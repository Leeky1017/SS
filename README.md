# SS（新架构骨架）

## 运行

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -e ".[dev]"
python -m src.main
```

### Windows（PowerShell）

- 一键启动（加载 `.env` + 启动 API + 后台启动 Worker）：`powershell -ExecutionPolicy Bypass -File start.ps1`
- 若需要 UI：先构建前端生成 `frontend/dist`（存在时 API 会在 `/` 托管静态页面）

## 开发（本地检查）

```bash
. .venv/bin/activate
ruff check .
mypy
pytest -q
```

## 最小链路

- `POST /jobs`：创建 job（写入 `jobs/<job_id>/job.json`）
- `GET /jobs/{job_id}/draft/preview`：读取 job → 调用 LLM client（stub）→ 写回草案 → 返回草案
- `POST /jobs/{job_id}/confirm`：更新状态为 queued（并记录 scheduled_at）
