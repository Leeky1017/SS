from __future__ import annotations

import logging
import os
from collections.abc import Iterator
from contextlib import contextmanager
from typing import IO

logger = logging.getLogger(__name__)


@contextmanager
def exclusive_lock(file: IO[str]) -> Iterator[None]:
    _lock(file)
    try:
        yield
    finally:
        try:
            _unlock(file)
        except OSError as exc:
            logger.warning(
                "SS_FILE_LOCK_RELEASE_FAILED",
                extra={"fd": file.fileno(), "error": str(exc)},
            )


def _lock(file: IO[str]) -> None:
    if os.name == "nt":
        import msvcrt

        file.seek(0)
        msvcrt.locking(file.fileno(), msvcrt.LK_LOCK, 1)
        return

    import fcntl

    fcntl.flock(file.fileno(), fcntl.LOCK_EX)


def _unlock(file: IO[str]) -> None:
    if os.name == "nt":
        import msvcrt

        file.seek(0)
        msvcrt.locking(file.fileno(), msvcrt.LK_UNLCK, 1)
        return

    import fcntl

    fcntl.flock(file.fileno(), fcntl.LOCK_UN)
