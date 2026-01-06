# 08 — API 契约与演进（保持薄层）

API 的职责：校验输入、调用 domain service、组装响应。**不做 IO、状态机细节与执行**。

## 1) 现有端点（骨架已具备）

- `POST /jobs`
  - 输入：requirement（可选）
  - 输出：job_id、status
- `GET /jobs/{job_id}/draft/preview`
  - 行为：读取 job → 调用 LLM preview → 写回 draft → 返回 draft_text
- `POST /jobs/{job_id}/confirm`
  - 行为：推进为 queued（并记录 scheduled_at）

## 2) 下一步最小扩展（Roadmap）

建议优先级：

1) `GET /jobs/{job_id}`（#18）
  - 返回权威状态、时间戳、draft 摘要、最近一次 run attempt 摘要、artifacts 索引摘要
2) Artifacts API（#19）
  - `GET /jobs/{job_id}/artifacts`（index）
  - `GET /jobs/{job_id}/artifacts/{artifact_id}`（download）
3) Run trigger（#19）
  - `POST /jobs/{job_id}/run`：推进 queued/记录 intent，不在 API 内跑 runner

## 3) 错误返回规范

统一结构：

```json
{"error_code":"JOB_NOT_FOUND","message":"job not found: job_xxx"}
```

原则：
- domain/infra 抛出 `SSError` 子类
- FastAPI 统一 handler 映射为 JSON（见 `src/main.py`）

## 4) 安全与路径

- 所有 path 只能是 job 目录内相对路径
- artifacts 下载必须做白名单/目录约束（拒绝 `..`、拒绝符号链接逃逸）

