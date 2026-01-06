# SS Worker & Queue — Index

## Worker 职责（硬约束）

- MUST 独立于 API 进程运行（例如 `python -m src.worker`）。
- MUST 通过 queue claim 确保同一 job 不会被两个 worker 同时执行。
- MUST 为每次 attempt 创建 `run_id` 与 `runs/<run_id>/` 目录，并写入 meta/artifacts。

## Queue（最小实现路径）

MVP 可以从 file-based queue 开始，但必须可替换：
- enqueue：记录 queued 意图
- claim：原子化（rename/lock）
- ack/release：成功确认/失败释放或延迟重试

## 重试（建议）

- `max_attempts` 与 backoff MUST 可配置（来自 `Config`）。
- 达到上限 MUST 置为 `failed`，并保留错误证据 artifacts。

