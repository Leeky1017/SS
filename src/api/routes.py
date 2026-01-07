from __future__ import annotations

from fastapi import APIRouter

from src.api import draft, health, jobs

api_router = APIRouter()
api_router.include_router(jobs.router)
api_router.include_router(draft.router)
api_router.include_router(health.router)

api_v1_router = APIRouter(prefix="/v1")
api_v1_router.include_router(jobs.router)
api_v1_router.include_router(draft.router)
