# 04 — Ports 与 Services（可测试的业务骨架）

domain 只写业务与接口（ports），infra 实现接口；API/worker 负责装配依赖。

## Ports（接口）建议清单

建议定义（domain）：
- `JobStore`
- `LLMClient`
- `Queue`
- `StataRunner`
- `Clock`（可选）

原则：
- ports 的签名要窄、稳定、可 mock（只 mock 边界）。
- ports 的返回值必须可序列化到 artifacts/job.json。

## Services（业务）建议拆分

每个 service 负责一个“状态机片段”：
- `JobService`：create/confirm/queue intent
- `DraftService`：draft preview + persist
- `PlanService`：freeze plan（结构化）
- `RunService`：run attempt + runner + archive + state update

