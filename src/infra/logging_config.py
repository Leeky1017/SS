from __future__ import annotations

import json
import logging
import logging.config
import traceback
from datetime import datetime, timezone
from typing import Any

from src.infra.tracing import current_trace_ids

_STANDARD_LOG_RECORD_ATTRS = frozenset(
    {
        "name",
        "msg",
        "args",
        "levelname",
        "levelno",
        "pathname",
        "filename",
        "module",
        "exc_info",
        "exc_text",
        "stack_info",
        "lineno",
        "funcName",
        "created",
        "msecs",
        "relativeCreated",
        "thread",
        "threadName",
        "processName",
        "process",
        "taskName",
    }
)


def _iso_utc(ts: float) -> str:
    return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()


def _normalize_log_level(value: str) -> str:
    candidate = str(value).strip().upper()
    if candidate == "":
        return "INFO"
    resolved = logging.getLevelName(candidate)
    if isinstance(resolved, int):
        return candidate
    return "INFO"


def _extract_extras(record: logging.LogRecord) -> dict[str, object]:
    extras: dict[str, object] = {}
    for key, value in record.__dict__.items():
        if key in _STANDARD_LOG_RECORD_ATTRS:
            continue
        if key in {"job_id", "run_id", "step", "trace_id", "span_id"}:
            continue
        extras[key] = value
    return extras


class SSJsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        trace_id, span_id = current_trace_ids()
        payload: dict[str, Any] = {
            "ts": _iso_utc(float(record.created)),
            "level": record.levelname,
            "logger": record.name,
            "event": record.getMessage(),
            "job_id": getattr(record, "job_id", None),
            "run_id": getattr(record, "run_id", None),
            "step": getattr(record, "step", None),
            "trace_id": trace_id,
            "span_id": span_id,
        }
        payload.update(_extract_extras(record))
        if record.exc_info:
            exc_type = record.exc_info[0].__name__ if record.exc_info[0] is not None else None
            payload["exc_type"] = exc_type
            payload["exc"] = "".join(traceback.format_exception(*record.exc_info)).rstrip()
        return json.dumps(payload, ensure_ascii=False, separators=(",", ":"), default=str)


def build_logging_config(*, log_level: str) -> dict[str, Any]:
    level = _normalize_log_level(log_level)
    return {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {"ss_json": {"()": "src.infra.logging_config.SSJsonFormatter"}},
        "handlers": {
            "stdout": {
                "class": "logging.StreamHandler",
                "level": level,
                "formatter": "ss_json",
                "stream": "ext://sys.stdout",
            }
        },
        "root": {"level": level, "handlers": ["stdout"]},
        "loggers": {
            "uvicorn": {"level": level, "handlers": ["stdout"], "propagate": False},
            "uvicorn.error": {"level": level, "handlers": ["stdout"], "propagate": False},
            "uvicorn.access": {"level": level, "handlers": ["stdout"], "propagate": False},
        },
    }


def configure_logging(*, log_level: str) -> None:
    logging.config.dictConfig(build_logging_config(log_level=log_level))
