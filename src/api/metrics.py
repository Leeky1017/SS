from __future__ import annotations

from fastapi import APIRouter, Depends, Response

from src.api.deps import get_metrics
from src.infra.prometheus_metrics import PrometheusMetrics

router = APIRouter(tags=["metrics"])


@router.get("/metrics", include_in_schema=False)
async def get_metrics_export(metrics: PrometheusMetrics = Depends(get_metrics)) -> Response:
    return Response(
        content=metrics.render_latest(),
        media_type=metrics.content_type_latest,
    )
