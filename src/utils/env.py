from __future__ import annotations

import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)


def load_dotenv(*, path: Path | None = None, override: bool = False) -> int:
    dotenv_path = Path(".env") if path is None else path
    try:
        lines = dotenv_path.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError:
        return 0
    except OSError as exc:
        logger.warning(
            "SS_DOTENV_READ_FAILED",
            extra={"path": str(dotenv_path), "error": str(exc)},
        )
        return 0

    loaded = 0
    for idx, raw in enumerate(lines, start=1):
        key, value = _parse_dotenv_line(raw=raw, path=dotenv_path, line_number=idx)
        if key is None:
            continue
        if not override and key in os.environ:
            continue
        os.environ[key] = value
        loaded += 1
    return loaded


def _parse_dotenv_line(*, raw: str, path: Path, line_number: int) -> tuple[str | None, str]:
    line = raw.strip()
    if line == "" or line.startswith("#"):
        return None, ""
    if line.startswith("export "):
        line = line.removeprefix("export ").lstrip()
    if "=" not in line:
        logger.warning(
            "SS_DOTENV_LINE_INVALID",
            extra={"path": str(path), "line_number": line_number, "reason": "missing_equals"},
        )
        return None, ""
    key, value = line.split("=", 1)
    key = key.strip()
    if key == "":
        logger.warning(
            "SS_DOTENV_LINE_INVALID",
            extra={"path": str(path), "line_number": line_number, "reason": "empty_key"},
        )
        return None, ""
    return key, _strip_optional_quotes(value.strip())


def _strip_optional_quotes(value: str) -> str:
    if len(value) < 2:
        return value
    if value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def int_value(raw: str, *, default: int) -> int:
    try:
        return int(raw)
    except (TypeError, ValueError):
        return default


def float_value(raw: str, *, default: float) -> float:
    try:
        return float(raw)
    except (TypeError, ValueError):
        return default


def bool_value(raw: str, *, default: bool) -> bool:
    value = str(raw).strip().lower()
    if value in {"1", "true", "yes", "y", "on"}:
        return True
    if value in {"0", "false", "no", "n", "off"}:
        return False
    return default


def clamped_ratio(raw: str, *, default: float) -> float:
    ratio = float_value(raw, default=default)
    if ratio < 0.0:
        return 0.0
    if ratio > 1.0:
        return 1.0
    return ratio


def clamped_int(
    raw: str,
    *,
    default: int,
    min_value: int | None = None,
    max_value: int | None = None,
) -> int:
    value = int_value(raw, default=default)
    if min_value is not None and value < min_value:
        return min_value
    if max_value is not None and value > max_value:
        return max_value
    return value
