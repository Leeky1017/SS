from __future__ import annotations

from pathlib import Path

import pytest

from src.main import create_app
from tests.asgi_client import asgi_client

pytestmark = pytest.mark.anyio


async def test_create_app_when_frontend_dist_present_serves_root_index_html() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    dist_dir = repo_root / "frontend" / "dist"
    dist_existed = dist_dir.exists()
    dist_dir.mkdir(parents=True, exist_ok=True)

    index_path = dist_dir / "index.html"
    index_existed = index_path.exists()
    if not index_existed:
        index_path.write_text("<html>ok</html>", encoding="utf-8")

    try:
        app = create_app()
        async with asgi_client(app=app) as client:
            response = await client.get("/")
        assert response.status_code == 200
        assert "text/html" in response.headers.get("content-type", "")
    finally:
        if not index_existed and index_path.exists():
            index_path.unlink()
        if not dist_existed:
            try:
                dist_dir.rmdir()
            except OSError:
                pass


async def test_create_app_when_frontend_dist_present_serves_admin_index_html() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    dist_dir = repo_root / "frontend" / "dist"
    dist_existed = dist_dir.exists()
    dist_dir.mkdir(parents=True, exist_ok=True)

    index_path = dist_dir / "index.html"
    index_existed = index_path.exists()
    if not index_existed:
        index_path.write_text("<html>ok</html>", encoding="utf-8")

    try:
        app = create_app()
        async with asgi_client(app=app) as client:
            response = await client.get("/admin/")
        assert response.status_code == 200
        assert "text/html" in response.headers.get("content-type", "")
    finally:
        if not index_existed and index_path.exists():
            index_path.unlink()
        if not dist_existed:
            try:
                dist_dir.rmdir()
            except OSError:
                pass
