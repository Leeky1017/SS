# 06 — Worker 与 Queue（后台执行框架）

SS 的执行必须脱离 API 进程：API 只负责创建/确认/查询；worker 负责执行 queued job。

## 1) Worker 的职责

- 从 queue claim job（同一 job 只能被一个 worker 执行）
- 创建 run attempt（run_id + runs/<run_id>/）
- 调用 domain `RunService` 完成一次 run
- 归档 artifacts，并更新 job.json 状态

## 2) Queue（最小实现路径）

MVP 可从 file-based queue 开始（目标是可替换）：

- 入队：把 job 状态推进到 `queued`（或写入一个 queue index 文件）
- claim：用原子操作（rename/lock）把 job 标记为 claimed
- release：失败时释放或延迟重试

核心目标：即使 worker 崩溃，也不会导致 job 永久卡死或被多 worker 同时跑。

## 3) Run attempt 目录（可复现隔离）

每次 attempt 必须产生独立目录：

```text
jobs/<job_id>/runs/<run_id>/
  work/         # runner 工作目录（只在这里读写）
  artifacts/    # 本 attempt 的产物（之后可汇总）
  meta.json     # attempt 元信息（开始/结束/错误码/版本）
```

建议 worker 在开始时把：
- `plan.json`（冻结计划）
- `inputs/manifest.json`（输入清单）
复制或引用到 attempt 目录，以确保回放不依赖外部状态。

## 4) Worker loop（伪代码）

```text
while True:
  claimed = queue.claim_next()
  if not claimed:
    sleep(poll_interval)
    continue

  try:
    run_service.run_once(job_id=claimed.job_id)
    queue.ack(claimed.job_id)
  except RetryableError:
    queue.release(claimed.job_id, reason="retryable")
  except SSError:
    queue.ack(claimed.job_id)  # 不再重试
```

## 5) 重试与 backoff（建议）

- `max_attempts`、`backoff_sec`、`poll_interval_sec` 来自 `Config`
- 重试次数写入 job.json（或 attempt meta），避免无限循环
- 达到上限后置为 failed，并保留错误 artifacts

## 6) 可观测性（worker 事件码建议）

最低事件码：
- `SS_WORKER_CLAIMED`
- `SS_RUN_STARTED`
- `SS_RUN_SUCCEEDED`
- `SS_RUN_FAILED`
- `SS_RUN_RETRY_SCHEDULED`

日志必须带 `job_id` 与 `run_id`。

