#!/usr/bin/env python3
"""Генерация 50 JSON-уровней: порталы = scheduled_spawns на y=0, дорожки = стены."""

from __future__ import annotations

import json
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


def portal_spawns(
    cols: int,
    portal_xs: list[int],
    waves: list[tuple[int, int, int]],
) -> list[dict]:
    """
    waves: (hp, count, first_turn) — для каждого портала по кругу распределяем волны.
    """
    sp: list[dict] = []
    if not portal_xs:
        return sp
    wi = 0
    for hp, count, turn0 in waves:
        for _ in range(count):
            px = portal_xs[wi % len(portal_xs)]
            sp.append(
                {
                    "x": px,
                    "y": 0,
                    "hp": hp,
                    "count": 1,
                    "spawn_after_player_turns": turn0 + (wi // len(portal_xs)) * 2,
                }
            )
            wi += 1
    return sp


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
                {"x": 2, "y": 0, "hp": 1, "count": 2, "spawn_after_player_turns": 2},
                {"x": 4, "y": 0, "hp": 2, "count": 1, "spawn_after_player_turns": 4},
            ],
            "seed": 1001,
        }

    boss = n % 5 == 0
    cols = 8 if n % 3 != 0 else 7
    rows = 16 if cols == 8 else 12
    er = 10
    seed = 9000 + n * 17

    # Босс: больше HP, плотнее волны, меньше ходов относительно массы
    if boss:
        wave_step = 5 + n // 5
        hp_lo = 1 + n // 10
        hp_hi = 2 + n // 8
        moves = 18 + min(22, n // 2)

        portal_xs = [1, cols - 2]
        if cols >= 8:
            portal_xs = [1, cols // 2, cols - 2]
        waves = [
            (min(6, max(1, hp_lo)), 4, wave_step),
            (min(6, max(1, hp_lo + 1)), 3, wave_step + 3),
            (min(6, max(2, hp_hi)), 4, wave_step + 6),
            (min(6, max(2, hp_hi + 1)), 3, wave_step + 9),
            (6, 2, wave_step + 14),
        ]
        if n >= 35:
            waves.append((6, 2, wave_step + 18))

        y_fill0 = 2
        y_fill1 = min(4 + n // 12, er - 3)
        if y_fill1 < y_fill0:
            y_fill1 = y_fill0
        sm = chess_monsters(cols, y_fill0, y_fill1, hp_lo, hp_hi)
        sched = portal_spawns(cols, portal_xs, waves)

        cx = cols // 2
        obs = merge_obstacles(
            wall_road_vertical(cols, er, cx),
            [
                {"x": 0, "y": er - 1, "type": "wall"},
                {"x": cols - 1, "y": er - 1, "type": "wall"},
            ],
        )
        # Ломаемые блоки на «перекрёстке»
        if 3 < er - 2:
            obs.append({"x": cx, "y": 3, "hp": min(4, 2 + n // 15)})

        return portal_level(n, cols, rows, moves, sm, sched, obs, seed)

    # Не босс: чередуем tiers и шахматку + порталы
    use_chess = (n % 2 == 0) or (n % 7 == 0)

    if use_chess:
        moves = 12 + min(20, (n * 4) // 5)
        hp_lo = 1 + (n // 12)
        hp_hi = 2 + (n // 10)
        y0, y1 = 1, min(5 + n // 8, er - 4)
        sm = chess_monsters(cols, y0, y1, hp_lo, hp_hi)

        portal_xs = [cols // 4, (3 * cols) // 4]
        if cols == 7:
            portal_xs = [1, 5]
        waves = [
            (hp_lo, 3, 2 + n // 10),
            (hp_hi, 2, 4 + n // 8),
            (max(2, hp_hi), 2, 7 + n // 12),
        ]
        sched = portal_spawns(cols, portal_xs, waves)

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

    # monster_tiers: растущая лесенка по глубине кампании
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
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(path.name)


if __name__ == "__main__":
    main()
