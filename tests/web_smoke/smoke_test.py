#!/usr/bin/env python3
"""Smoke-тест Web-сборки Godot: загрузка, автозапуск уровня, проверка логов."""

from __future__ import annotations

import argparse
import http.server
import socketserver
import sys
import threading
import time
from pathlib import Path
from typing import Callable
from urllib.parse import urljoin

from playwright.sync_api import Error as PlaywrightError
from playwright.sync_api import Page, sync_playwright

TARGET_PHASE = "game_board_ready"
DEFAULT_TIMEOUT_MS = 120_000
PAGES_RETRY_INTERVAL_SEC = 20
PAGES_MAX_ATTEMPTS = 9
IGNORED_CONSOLE_PATTERNS = (
    "Failed to load resource",
    "favicon",
)


class WasmHttpHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
    }

    def __init__(self, *args, directory: str | None = None, **kwargs):
        super().__init__(*args, directory=directory, **kwargs)

    def log_message(self, format: str, *args) -> None:
        return


def _start_static_server(serve_dir: Path, port: int) -> socketserver.TCPServer:
    handler = lambda *args, **kwargs: WasmHttpHandler(  # noqa: E731
        *args,
        directory=str(serve_dir),
        **kwargs,
    )
    server = socketserver.TCPServer(("127.0.0.1", port), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


def _should_ignore_console_line(text: str) -> bool:
    lowered = text.lower()
    return any(pattern.lower() in lowered for pattern in IGNORED_CONSOLE_PATTERNS)


def _attach_log_collectors(page: Page, console_errors: list[str], page_errors: list[str]) -> None:
    def on_console(msg) -> None:
        if msg.type not in ("error", "warning"):
            return
        line = f"[{msg.type}] {msg.text}"
        if _should_ignore_console_line(line):
            return
        console_errors.append(line)
        page.evaluate(
            "(line) => {"
            "window.__EB_SMOKE__ = window.__EB_SMOKE__ || {errors: []};"
            "window.__EB_SMOKE__.consoleErrors.push(line);"
            "}",
            line,
        )

    def on_page_error(exc: Exception) -> None:
        line = f"[pageerror] {exc}"
        page_errors.append(line)

    page.on("console", on_console)
    page.on("pageerror", on_page_error)


def _run_single_attempt(base_url: str, timeout_ms: int) -> dict:
    console_errors: list[str] = []
    page_errors: list[str] = []
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 648, "height": 1200})
        _attach_log_collectors(page, console_errors, page_errors)
        target_url = urljoin(base_url.rstrip("/") + "/", "?smoke_test=1")
        page.goto(target_url, wait_until="domcontentloaded", timeout=timeout_ms)
        page.wait_for_selector("#canvas", state="visible", timeout=timeout_ms)
        page.wait_for_function(
            f"() => window.__EB_SMOKE__ && window.__EB_SMOKE__.phase === '{TARGET_PHASE}'",
            timeout=timeout_ms,
        )
        smoke_state = page.evaluate(
            "() => ({"
            "phase: window.__EB_SMOKE__?.phase || '',"
            "detail: window.__EB_SMOKE__?.detail || '',"
            "errors: window.__EB_SMOKE__?.errors || [],"
            "consoleErrors: window.__EB_SMOKE__?.consoleErrors || []"
            "})"
        )
        browser.close()
    return {
        "smoke_state": smoke_state,
        "console_errors": console_errors,
        "page_errors": page_errors,
    }


def _format_failure(result: dict) -> str:
    lines = ["Smoke-тест не пройден."]
    smoke_state = result.get("smoke_state", {})
    lines.append(f"Фаза: {smoke_state.get('phase', '?')} ({smoke_state.get('detail', '')})")
    for label, key in (
        ("Ошибки игры", "errors"),
        ("Ошибки консоли (игра)", "consoleErrors"),
        ("Ошибки консоли (браузер)", "console_errors"),
        ("Page errors", "page_errors"),
    ):
        values = smoke_state.get(key) if key in smoke_state else result.get(key, [])
        if values:
            lines.append(f"{label}:")
            for item in values:
                lines.append(f"  - {item}")
    return "\n".join(lines)


def _run_with_retries(
    base_url: str,
    timeout_ms: int,
    attempts: int,
    retry_interval_sec: int,
    label: str,
) -> dict:
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        print(f"[{label}] Попытка {attempt}/{attempts}: {base_url}")
        try:
            result = _run_single_attempt(base_url, timeout_ms)
            smoke_errors = result["smoke_state"].get("errors", [])
            if smoke_errors or result["console_errors"] or result["page_errors"]:
                raise AssertionError(_format_failure(result))
            print(f"[{label}] OK — уровень загружен без ошибок.")
            return result
        except (AssertionError, PlaywrightError, TimeoutError) as exc:
            last_error = exc
            print(f"[{label}] Неудача: {exc}")
            if attempt < attempts:
                time.sleep(retry_interval_sec)
    raise SystemExit(f"[{label}] Все попытки исчерпаны: {last_error}")


def _verify_build_files(serve_dir: Path) -> None:
    required = ["index.html"]
    wasm_files = list(serve_dir.glob("*.wasm"))
    js_files = list(serve_dir.glob("*.js"))
    pck_files = list(serve_dir.glob("*.pck"))
    missing = [name for name in required if not (serve_dir / name).exists()]
    if missing:
        raise SystemExit(f"В билде нет файлов: {', '.join(missing)}")
    if not wasm_files or not js_files or not pck_files:
        raise SystemExit("В билде отсутствуют .js / .wasm / .pck артефакты Godot.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Smoke-тест Web-сборки Elemental Blast")
    parser.add_argument("--base-url", help="URL уже развёрнутой сборки (GitHub Pages)")
    parser.add_argument("--serve-dir", type=Path, help="Локальная папка build/web для проверки артефакта")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--timeout-ms", type=int, default=DEFAULT_TIMEOUT_MS)
    parser.add_argument(
        "--pages-wait-seconds",
        type=int,
        default=PAGES_RETRY_INTERVAL_SEC,
        help="Пауза между повторами для GitHub Pages",
    )
    parser.add_argument(
        "--pages-max-attempts",
        type=int,
        default=PAGES_MAX_ATTEMPTS,
        help="Число попыток для GitHub Pages (деплой может идти с задержкой)",
    )
    args = parser.parse_args()
    if not args.base_url and not args.serve_dir:
        parser.error("Укажите --base-url и/или --serve-dir")

    runners: list[Callable[[], None]] = []

    if args.serve_dir:
        serve_dir = args.serve_dir.resolve()
        if not serve_dir.is_dir():
            raise SystemExit(f"Папка не найдена: {serve_dir}")
        _verify_build_files(serve_dir)

        def run_local() -> None:
            server = _start_static_server(serve_dir, args.port)
            try:
                _run_with_retries(
                    f"http://127.0.0.1:{args.port}",
                    args.timeout_ms,
                    attempts=1,
                    retry_interval_sec=0,
                    label="artifact",
                )
            finally:
                server.shutdown()

        runners.append(run_local)

    if args.base_url:
        def run_pages() -> None:
            _run_with_retries(
                args.base_url,
                args.timeout_ms,
                attempts=args.pages_max_attempts,
                retry_interval_sec=args.pages_wait_seconds,
                label="github-pages",
            )

        runners.append(run_pages)

    for runner in runners:
        runner()


if __name__ == "__main__":
    main()
