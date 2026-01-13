# src/utils/file_lock.py
"""Cross-platform file locking utilities for Windows and Unix."""
from __future__ import annotations

import sys
from typing import IO


def lock_file(f: IO[str]) -> None:
    """Acquire an exclusive lock on a file (cross-platform)."""
    if sys.platform == "win32":
        import msvcrt
        msvcrt.locking(f.fileno(), msvcrt.LK_LOCK, 1)
    else:
        import fcntl
        fcntl.flock(f.fileno(), fcntl.LOCK_EX)


def unlock_file(f: IO[str]) -> None:
    """Release a lock on a file (cross-platform)."""
    if sys.platform == "win32":
        import msvcrt
        msvcrt.locking(f.fileno(), msvcrt.LK_UNLCK, 1)
    else:
        import fcntl
        fcntl.flock(f.fileno(), fcntl.LOCK_UN)
