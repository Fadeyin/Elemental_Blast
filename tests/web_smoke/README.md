# Web smoke-тест

Проверяет, что Web-сборка Godot загружается, открывает уровень и не пишет ошибок в консоль.

## Как работает

1. Страница открывается с `?smoke_test=1`.
2. `WebSmokeTestBridge` автоматически проходит главное меню → диалог старта → игровое поле.
3. Playwright ждёт фазу `game_board_ready` и проверяет ошибки в `window.__EB_SMOKE__` и консоли браузера.

## Локальный запуск

```bash
pip install -r tests/web_smoke/requirements.txt
playwright install chromium

# Проверка локального артефакта build/web
python tests/web_smoke/smoke_test.py --serve-dir build/web

# Проверка GitHub Pages
python tests/web_smoke/smoke_test.py --base-url https://fadeyin.github.io/Elemental_Blast
```

## CI

Job `smoke-test` в `.github/workflows/godot-web-export.yml` запускается после `export-web`:

- проверяет скачанный артефакт билда;
- на `main` дополнительно проверяет https://fadeyin.github.io/Elemental_Blast/ с повторами (деплой Pages может идти с задержкой).
