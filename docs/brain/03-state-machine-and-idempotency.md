# 03 — 状态机、幂等与并发（State / Idempotency / Concurrency）

SS 的可维护性关键在于：状态机与幂等策略必须是 **domain 逻辑**，而不是散落在 API/worker 的 if/else。

## 1) 状态枚举（建议）

- `created`：job 已创建，但还没有可用草案
- `draft_ready`：已有草案（或至少草案 artifacts 已落盘）
- `confirmed`：用户确认完成，计划已冻结（可进入队列）
- `queued`：等待 worker claim
- `running`：正在执行（必须有当前 run attempt）
- `succeeded`：执行完成且产物齐备
- `failed`：执行失败（必须有失败证据 artifacts + error_code）

## 2) 允许的迁移（建议）

```text
created -> draft_ready
draft_ready -> confirmed
confirmed -> queued
queued -> running
running -> succeeded
running -> failed
failed -> queued        # 可选：允许人工/系统重试
```

禁止：
- 直接 `created -> queued`（除非明确跳过 draft/confirm 的产品需求）
- `succeeded -> running`（除非开启“重新执行”的显式版本化语义）

## 3) 每个状态的最小不变量

- `draft_ready`：`draft` 存在 或 有 `llm.*` artifacts 指向可用草案
- `confirmed`：`llm_plan` 已冻结（plan 不允许在 worker 中隐式重新生成）
- `running`：存在当前 `runs[-1]` 且 `runs[-1].status == running`
- `failed`：存在当前 run 的 `error_code` 或 `stata.log`/`run.stderr` 等证据
- `succeeded`：至少有 `stata.log` + 1 个结果产物（表或图）进入 artifacts_index

## 4) 幂等键（建议口径）

目的：重复请求不应产生语义冲突的 artifacts 或错误状态推进。

建议把幂等键定义为：

```text
idempotency_key = sha256(
  schema_version +
  job_id +
  inputs.fingerprint +
  requirement_normalized +
  llm_plan.plan_version +
  llm_plan.steps_normalized
)
```

使用方式：
- 如果新的运行请求的 `idempotency_key` 与上一次成功 run 一致，可直接复用结果（或返回 “already_succeeded”）。
- 如果不一致，则必须生成新的 run_id，并将旧结果作为历史 runs 保留。

## 5) 并发模型（最小可行策略）

目标：同一 job 同一时间只有一个执行者。

建议组合：
- **claim lock（队列层）**：worker claim queued job 时用原子操作保证唯一
- **job.json lock（存储层）**：对 job.json 更新加文件锁，防止并发写
- **revision check（逻辑层）**：写回时携带 revision，避免“最后写赢”覆盖

最低实现路径：
1) worker 发现 queued job
2) 尝试 claim（成功则继续，失败则跳过）
3) load job.json，确认状态仍是 queued
4) 写入 run attempt + 状态 running（原子写 + 锁）

## 6) 重试策略（建议）

分类：
- 可重试：临时 IO、LLM provider 临时失败、worker 崩溃导致中断
- 不可重试：job 数据损坏、非法状态迁移、输入缺失且不可恢复

重试建议：
- `max_attempts` 与 `backoff` 来自 `Config`
- 每次 attempt 产生新的 run_id（可追溯）
- 达到上限：置为 failed，保留失败 artifacts，并返回明确 error_code

