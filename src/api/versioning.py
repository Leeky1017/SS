from __future__ import annotations

from fastapi import Response

LEGACY_UNVERSIONED_PREFIXES: tuple[str, ...] = ("/jobs",)
LEGACY_UNVERSIONED_SUNSET_DATE = "2026-06-01"


def is_legacy_unversioned_path(path: str) -> bool:
    return any(path.startswith(prefix) for prefix in LEGACY_UNVERSIONED_PREFIXES)


def add_legacy_deprecation_headers(response: Response) -> None:
    response.headers["Deprecation"] = "true"
    response.headers["Sunset"] = LEGACY_UNVERSIONED_SUNSET_DATE

