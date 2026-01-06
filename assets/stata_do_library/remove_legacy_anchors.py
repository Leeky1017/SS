#!/usr/bin/env python3
"""
Remove v1.0 legacy anchors from Stata templates, keeping only v1.1 anchors.

v1.0 anchors (to remove):
  - display "SS_TASK_START:Txxx"
  - display "SS_TASK_END:SUCCESS"
  - display "SS_TASK_END:FAILED"

v1.1 anchors (to keep):
  - display "SS_TASK_BEGIN|id=Txxx|level=L0|title=..."
  - display "SS_TASK_END|id=Txxx|status=ok|elapsed_sec=..."

Usage:
    python tasks/remove_legacy_anchors.py --dry-run
    python tasks/remove_legacy_anchors.py
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path


DO_DIR = Path(__file__).parent / "do"

# Match entire lines containing v1.0 anchors (keep v1.1 lines intact).
LEGACY_LINE_PATTERNS = [
    r'^\s*display\s+"SS_TASK_START:\w+".*(?:\r?\n)?',
    r'^\s*display\s+"SS_TASK_END:(SUCCESS|FAILED)".*(?:\r?\n)?',
]


def remove_legacy_anchors(do_file: Path, dry_run: bool = False) -> bool:
    content = do_file.read_text(encoding="utf-8")
    original = content

    for pattern in LEGACY_LINE_PATTERNS:
        content = re.sub(pattern, "", content, flags=re.MULTILINE)

    if content != original:
        if not dry_run:
            do_file.write_text(content, encoding="utf-8")
        return True
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Remove v1.0 legacy anchors from Stata templates")
    parser.add_argument("--dry-run", action="store_true", help="Preview changes without modifying files")
    args = parser.parse_args()

    if not DO_DIR.exists():
        raise FileNotFoundError(f"DO directory not found: {DO_DIR}")

    count = 0
    for do_file in sorted(DO_DIR.glob("*.do")):
        if remove_legacy_anchors(do_file, dry_run=args.dry_run):
            count += 1
            prefix = "[DRY-RUN] " if args.dry_run else ""
            print(f"{prefix}Updated: {do_file.name}")

    summary = "Would update" if args.dry_run else "Updated"
    print(f"\n{summary}: {count} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

