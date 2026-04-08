#!/usr/bin/env python3
"""Генерация 50 JSON-уровней: порталы = scheduled_spawns на y=0, дорожки = стены."""

from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path


def wall_road_vertical(cols: int, enemy_rows: int, cx: int) -> list[dict]:
    """Коридор по столбцу cx: стены по бокам, если есть место."""
    obs: list[dict] = []
    for y in range(enemy_rows):
        if cx - 1 >= 0:
            obs.append({"x": cx - 1, "y": y, "type": "wall"})
        if cx + 1 < cols:
            obs.append({"x": cx + 1, "y": y, "type": "wall"})
    return obs


def wall_road_horizontal(cols: int, enemy_rows: int, ry: int) -> list[dict]:
    """Горизонтальная «дорожка»: стены сверху и снизу от ряда ry."""
    obs: list[dict] = []
    for x in range(cols):
        if ry - 1 >= 0:
            obs.append({"x": x, "y": ry - 1, "type": "wall"})
        if ry + 1 < enemy_rows:
            obs.append({"x": x, "y": ry + 1, "type": "wall"})
    return obs


def merge_obstacles(*groups: list[dict]) -> list[dict]:
    seen: set[tuple[int, int]] = set()
    out: list[dict] = []
    for g in groups:
        for o in g:
            key = (int(o["x"]), int(o["y"]))
            if key in seen:
                continue
            seen.add(key)
            out.append(o)
    return out


def chess_monsters(cols: int, y0: int, y1: int, hp_even: int, hp_odd: int) -> list[dict]:
    sm: list[dict] = []
    for y in range(y0, y1 + 1):
        for x in range(cols):
            hp = hp_even if (x + y) % 2 == 0 else hp_odd
            hp = min(6, max(1, hp))
            sm.append({"x": x, "y": y, "hp": hp})
    return sm


def obstacle_blocked_cells(obstacles: list[dict], enemy_rows: int, cols: int) -> set[tuple[int, int]]:
    blocked: set[tuple[int, int]] = set()
    for o in obstacles:
        ox = int(o.get("x", -1))
        oy = int(o.get("y", -1))
        if 0 <= ox < cols and 0 <= oy < enemy_rows:
            blocked.add((ox, oy))
    return blocked


def expand_scheduled(raw: list[dict]) -> list[dict]:
    out: list[dict] = []
    for item in raw:
        hp = min(6, max(1, int(item.get("hp", 1))))
        x = int(item.get("x", 0))
        y = int(item.get("y", 0))
        count = max(1, int(item.get("count", 1)))
        turn = max(0, int(item.get("spawn_after_player_turns", 0)))
        for _ in range(count):
            out.append({"x": x, "y": y, "hp": hp, "spawn_after_player_turns": turn})
    return out


def sequential_portal_spawns(portal_xs: list[int], spawn_list: list[tuple[int, int]]) -> list[dict]:
    """
    spawn_list: (hp, count) — волны подряд; каждый монстр со своим ходом 1,2,3,…
    чтобы не было «пустого поля», пока не наступит большой spawn_after_player_turns.
    """
    sp: list[dict] = []
    if not portal_xs:
        return sp
    turn = 1
    wi = 0
    for hp, count in spawn_list:
        hp = min(6, max(1, hp))
        for _ in range(count):
            px = portal_xs[wi % len(portal_xs)]
            sp.append(
                {
                    "x": px,
                    "y": 0,
                    "hp": hp,
                    "count": 1,
                    "spawn_after_player_turns": turn,
                }
            )
            turn += 1
            wi += 1
    return sp


def count_level_targets(data: dict) -> dict[int, int]:
    """Те же правила, что LevelManager._normalize + game_board _init_enemies_from_config."""
    targets: dict[int, int] = defaultdict(int)
    er = int(data.get("enemy_rows", 10))
    cols = int(data.get("cols", 7))
    blocked = obstacle_blocked_cells(list(data.get("obstacles", [])), er, cols)

    if data.get("start_monsters"):
        for item in data["start_monsters"]:
            hp = min(6, max(1, int(item.get("hp", 1))))
            x, y = int(item.get("x", 0)), int(item.get("y", 0))
            if (x, y) in blocked:
                continue
            targets[hp] += 1

    if data.get("scheduled_spawns"):
        for e in expand_scheduled(list(data["scheduled_spawns"])):
            targets[int(e["hp"])] += 1

    if data.get("monster_tiers"):
        for tier in data["monster_tiers"]:
            if isinstance(tier, dict) and "hp" in tier and "count" in tier:
                hp = min(6, max(1, int(tier["hp"])))
                cnt = max(0, int(tier["count"]))
                targets[hp] += cnt

    if not data.get("start_monsters") and not data.get("scheduled_spawns"):
        if not data.get("monster_tiers"):
            total = er * cols
            strong = int(data.get("strong_monsters", 0))
            strong_hp = min(6, max(1, int(data.get("strong_hp", 3))))
            for _ in range(min(strong, total)):
                targets[strong_hp] += 1
            for _ in range(max(0, total - strong)):
                targets[1] += 1

    return dict(targets)


def total_positive_targets(targets: dict[int, int]) -> int:
    return sum(c for c in targets.values() if c > 0)


def tier_level(
    n: int,
    cols: int,
    rows: int,
    moves: int,
    tiers: list[dict],
    obstacles: list[dict],
    seed: int,
) -> dict:
    tiers = [t for t in tiers if int(t.get("count", 0)) > 0]
    return {
        "cols": cols,
        "rows": rows,
        "enemy_rows": 10,
        "moves": moves,
        "monster_tiers": tiers,
        "obstacles": obstacles,
        "seed": seed,
    }


def portal_level(
    n: int,
    cols: int,
    rows: int,
    moves: int,
    start_monsters: list[dict],
    scheduled: list[dict],
    obstacles: list[dict],
    seed: int,
) -> dict:
    return {
        "cols": cols,
        "rows": rows,
        "enemy_rows": 10,
        "moves": moves,
        "start_monsters": start_monsters,
        "scheduled_spawns": scheduled,
        "obstacles": obstacles,
        "seed": seed,
    }


def build_level(n: int) -> dict:
    if n == 1:
        return {
            "cols": 8,
            "rows": 16,
            "enemy_rows": 10,
            "moves": 10,
            "start_monsters": [
                {"x": 2, "y": 1, "hp": 1},
                {"x": 4, "y": 1, "hp": 1},
                {"x": 3, "y": 2, "hp": 2},
            ],
            "scheduled_spawns": [
                {"x": 2, "y": 0, "hp": 1, "count": 1, "spawn_after_player_turns": 1},
                {"x": 2, "y": 0, "hp": 1, "count": 1, "spawn_after_player_turns": 2},
                {"x": 4, "y": 0, "hp": 2, "count": 1, "spawn_after_player_turns": 3},
            ],
            "seed": 1001,
        }

    boss = n % 5 == 0
    cols = 8 if n % 3 != 0 else 7
    rows = 16 if cols == 8 else 12
    er = 10
    seed = 9000 + n * 17

    if boss:
        hp_lo = 1 + n // 10
        hp_hi = 2 + n // 8
        hp_lo = min(6, max(1, hp_lo))
        hp_hi = min(6, max(1, hp_hi))
        moves = 20 + min(24, n // 2)

        portal_xs = [1, cols - 2]
        if cols >= 8:
            portal_xs = [1, cols // 2, cols - 2]

        spawn_list: list[tuple[int, int]] = [
            (hp_lo, 4),
            (min(6, hp_lo + 1), 3),
            (min(6, max(2, hp_hi)), 4),
            (min(6, hp_hi + 1), 3),
            (6, 2),
        ]
        if n >= 35:
            spawn_list.append((6, 2))
        sched = sequential_portal_spawns(portal_xs, spawn_list)

        y_fill0 = 2
        y_fill1 = min(4 + n // 12, er - 3)
        if y_fill1 < y_fill0:
            y_fill1 = y_fill0
        sm = chess_monsters(cols, y_fill0, y_fill1, hp_lo, hp_hi)

        cx = cols // 2
        obs = merge_obstacles(
            wall_road_vertical(cols, er, cx),
            [
                {"x": 0, "y": er - 1, "type": "wall"},
                {"x": cols - 1, "y": er - 1, "type": "wall"},
            ],
        )
        if 3 < er - 2:
            obs.append({"x": cx, "y": 3, "hp": min(4, 2 + n // 15)})

        return portal_level(n, cols, rows, moves, sm, sched, obs, seed)

    use_chess = (n % 2 == 0) or (n % 7 == 0)

    if use_chess:
        moves = 14 + min(22, (n * 4) // 5)
        hp_lo = 1 + (n // 12)
        hp_hi = 2 + (n // 10)
        hp_lo = min(6, max(1, hp_lo))
        hp_hi = min(6, max(1, hp_hi))
        y0, y1 = 1, min(5 + n // 8, er - 4)
        sm = chess_monsters(cols, y0, y1, hp_lo, hp_hi)

        portal_xs = [cols // 4, (3 * cols) // 4]
        if cols == 7:
            portal_xs = [1, 5]
        spawn_list = [
            (hp_lo, 3),
            (hp_hi, 2),
            (min(6, max(2, hp_hi)), 2),
        ]
        sched = sequential_portal_spawns(portal_xs, spawn_list)

        obs: list[dict] = []
        if n % 4 == 0:
            obs = merge_obstacles(
                wall_road_horizontal(cols, er, 4),
                [{"x": cols // 2, "y": 2, "hp": 2}],
            )
        elif n % 4 == 2:
            obs = merge_obstacles(
                wall_road_vertical(cols, er, cols // 2),
                [{"x": 1, "y": er - 2, "hp": 1}, {"x": cols - 2, "y": er - 2, "hp": 1}],
            )
        else:
            obs = [
                {"x": 0, "y": er - 2, "hp": 2},
                {"x": cols - 1, "y": er - 2, "hp": 2},
            ]

        return portal_level(n, cols, rows, moves, sm, sched, obs, seed)

    base = 8 + (n * 3) // 5
    t1 = max(6, base - 4)
    t2 = max(4, base // 2)
    t3 = max(2, base // 4)
    t4 = max(0, n // 8 - 1)
    t5 = max(0, n // 12 - 1)
    tiers = [
        {"hp": 1, "count": t1},
        {"hp": 2, "count": t2},
    ]
    if t3 > 0:
        tiers.append({"hp": 3, "count": t3})
    if t4 > 0:
        tiers.append({"hp": 4, "count": t4})
    if t5 > 0 and n >= 25:
        tiers.append({"hp": 5, "count": t5})
    if n >= 40:
        tiers.append({"hp": 6, "count": max(1, n // 20)})

    moves = 14 + min(24, n // 2)
    obs2: list[dict] = []
    if cols >= 8:
        obs2 = merge_obstacles(
            [{"x": 2, "y": 3, "hp": 2}, {"x": 5, "y": 3, "hp": 2}],
            [{"x": 3, "y": 5, "type": "wall"}, {"x": 4, "y": 5, "type": "wall"}],
        )
    else:
        obs2 = [
            {"x": 1, "y": 3, "hp": 2},
            {"x": 5, "y": 3, "hp": 2},
            {"x": 3, "y": 5, "type": "wall"},
        ]

    return tier_level(n, cols, rows, moves, tiers, obs2, seed)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    levels_dir = root / "levels"
    levels_dir.mkdir(parents=True, exist_ok=True)
    for n in range(1, 51):
        path = levels_dir / f"level_{n:03d}.json"
        data = build_level(n)
        tg = count_level_targets(data)
        assert total_positive_targets(tg) > 0, f"level {n}: нет целей"
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(path.name)


if __name__ == "__main__":
    main()
