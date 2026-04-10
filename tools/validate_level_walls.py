#!/usr/bin/env python3
"""Проверка JSON уровней: в каждом ряду enemy-зоны не более (cols - 2) стен type=wall."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    levels_dir = root / "levels"
    sys.path.insert(0, str(root / "tools"))
    from generate_campaign_levels import assert_wall_row_gaps

    errors = 0
    for path in sorted(levels_dir.glob("level_*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        try:
            assert_wall_row_gaps(data, path.name)
        except AssertionError as e:
            print(e, file=sys.stderr)
            errors += 1
    if errors:
        print(f"validate_level_walls: {errors} файл(ов) с нарушением", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
