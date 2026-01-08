from __future__ import annotations

from collections.abc import Callable


def async_override(value: object) -> Callable[[], object]:
    async def _override() -> object:
        return value

    return _override

