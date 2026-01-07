from __future__ import annotations

import json
import logging

from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider

from src.infra.logging_config import SSJsonFormatter


def test_ssjsonformatter_when_span_active_includes_trace_fields() -> None:
    trace.set_tracer_provider(TracerProvider())
    tracer = trace.get_tracer(__name__)
    formatter = SSJsonFormatter()

    record = logging.LogRecord(
        name="test",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="SS_TEST_EVENT",
        args=(),
        exc_info=None,
    )
    setattr(record, "job_id", "job_test")

    with tracer.start_as_current_span("test-span"):
        payload = json.loads(formatter.format(record))

    assert isinstance(payload.get("trace_id"), str)
    assert len(payload["trace_id"]) == 32
    assert isinstance(payload.get("span_id"), str)
    assert len(payload["span_id"]) == 16

