from __future__ import annotations

import logging
import secrets
from collections.abc import Mapping, MutableMapping

from opentelemetry import propagate, trace
from opentelemetry.context import Context
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter
from opentelemetry.sdk.trace.sampling import TraceIdRatioBased
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

from src.config import Config

logger = logging.getLogger(__name__)

_configured = False
_propagator = TraceContextTextMapPropagator()


def new_trace_id_hex() -> str:
    return secrets.token_hex(16)


def new_span_id_hex() -> str:
    return secrets.token_hex(8)


def build_traceparent(*, trace_id: str, span_id: str, sampled: bool) -> str:
    flags = "01" if sampled else "00"
    return f"00-{trace_id}-{span_id}-{flags}"


def carrier_from_traceparent(traceparent: str) -> dict[str, str]:
    return {"traceparent": traceparent}


def context_from_traceparent(traceparent: str) -> Context:
    return extract_context(carrier=carrier_from_traceparent(traceparent))


def synthetic_parent_context_for_trace_id(*, trace_id: str, sampled: bool) -> Context:
    traceparent = build_traceparent(trace_id=trace_id, span_id=new_span_id_hex(), sampled=sampled)
    return context_from_traceparent(traceparent)


def extract_context(*, carrier: Mapping[str, str]) -> Context:
    return _propagator.extract(carrier=carrier)


def inject_current_context(*, carrier: MutableMapping[str, str]) -> None:
    propagate.inject(carrier)

def current_trace_ids() -> tuple[str | None, str | None]:
    span = trace.get_current_span()
    span_context = span.get_span_context()
    if not span_context.is_valid:
        return None, None
    return f"{span_context.trace_id:032x}", f"{span_context.span_id:016x}"


def configure_tracing(*, config: Config, component: str) -> None:
    global _configured
    if _configured or not config.tracing_enabled:
        return
    _configured = True

    resource = Resource.create({"service.name": f"{config.tracing_service_name}-{component}"})
    provider = TracerProvider(
        resource=resource,
        sampler=TraceIdRatioBased(float(config.tracing_sample_ratio)),
    )
    if config.tracing_exporter == "console":
        processor = BatchSpanProcessor(ConsoleSpanExporter())
    else:
        processor = BatchSpanProcessor(OTLPSpanExporter(endpoint=config.tracing_otlp_endpoint))
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)
    logger.info(
        "SS_TRACING_CONFIGURED",
        extra={
            "tracing_exporter": config.tracing_exporter,
            "otlp_endpoint": config.tracing_otlp_endpoint,
            "sample_ratio": config.tracing_sample_ratio,
            "service_name": f"{config.tracing_service_name}-{component}",
        },
    )
