# SS State Machine — Index

状态机与幂等策略必须是 **domain 逻辑**。API/worker 不得各写一套 if/else。

## 状态枚举（建议）

- `created`
- `draft_ready`
- `confirmed`
- `queued`
- `running`
- `succeeded`
- `failed`

## 合法迁移（建议）

```text
created -> draft_ready -> confirmed -> queued -> running -> succeeded|failed
failed -> queued   (可选：允许显式重试)
```

## 幂等键（建议口径）

目的：重复请求不得产生语义冲突的产物。

建议幂等键至少包含：
- `inputs.fingerprint`
- `requirement`（规范化后）
- `llm_plan`（或其 revision）

## 并发与一致性（建议）

最低要求：同一 job 同一时间只允许一个执行者更新关键状态。

推荐组合：
- queue claim 原子化（防止双 worker）
- job.json 更新加锁 + 原子写（防止并发写覆盖）
- revision/compare-and-swap（防止“最后写赢”）

