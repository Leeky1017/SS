# 08 — API 契约（保持薄层）

API 必须保持薄：参数校验、响应组装、调用 domain service。

## 现有端点（骨架）

- `POST /jobs`
- `GET /jobs/{job_id}/draft/preview`
- `POST /jobs/{job_id}/confirm`

## 建议扩展（Roadmap）

- `GET /jobs/{job_id}`：权威状态 + artifacts 索引摘要
- `GET /jobs/{job_id}/artifacts`：artifacts index
- `GET /jobs/{job_id}/artifacts/{artifact_id}`：安全下载（防 path traversal）
- `POST /jobs/{job_id}/run`：推进 queued（不执行）

