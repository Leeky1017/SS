from __future__ import annotations

from collections.abc import Sequence

from src.infra.exceptions import OutputFormatsInvalidError

SUPPORTED_OUTPUT_FORMATS: tuple[str, ...] = ("csv", "xlsx", "dta", "docx", "pdf", "log", "do")
DEFAULT_OUTPUT_FORMATS: tuple[str, ...] = ("csv", "log", "do")


def normalize_output_formats(value: Sequence[str] | None) -> tuple[str, ...]:
    if value is None:
        return DEFAULT_OUTPUT_FORMATS
    normalized: list[str] = []
    for raw in value:
        if not isinstance(raw, str):
            raise OutputFormatsInvalidError(
                reason="output_formats_contains_non_string",
                supported=SUPPORTED_OUTPUT_FORMATS,
            )
        fmt = raw.strip().lower()
        if fmt == "":
            raise OutputFormatsInvalidError(
                reason="output_formats_contains_empty_string",
                supported=SUPPORTED_OUTPUT_FORMATS,
            )
        if fmt not in SUPPORTED_OUTPUT_FORMATS:
            raise OutputFormatsInvalidError(
                reason=f"unsupported_output_format:{fmt}",
                supported=SUPPORTED_OUTPUT_FORMATS,
            )
        if fmt in normalized:
            continue
        normalized.append(fmt)
    if len(normalized) == 0:
        raise OutputFormatsInvalidError(
            reason="output_formats_empty",
            supported=SUPPORTED_OUTPUT_FORMATS,
        )
    return tuple(normalized)
