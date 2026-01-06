# 04 — Ports 与 Services（可测试的业务骨架）

SS 的实现方式：domain 只写业务与接口（ports），infra 实现接口；API/worker 负责装配依赖。

## 1) Ports（接口）清单（建议）

这些接口建议放在 `src/domain/`（或 `src/domain/ports/`），由 `src/infra/` 实现：

- `JobStore`
  - `create(job)`
  - `load(job_id) -> Job`
  - `save(job)`
  - `write_artifact(job_id, artifact) -> ArtifactRef`（可选：也可拆成 ArtifactStore）
- `LLMClient`
  - `draft_preview(job, prompt) -> Draft`
  - `plan(job, context) -> LLMPlan`（后续）
- `StataRunner`
  - `run(run_dir, do_file_path, timeout) -> RunResult`
- `Queue`
  - `enqueue(job_id)`
  - `claim_next() -> ClaimedJob | None`
  - `ack(job_id)` / `release(job_id, reason)`（按需要）
- `Clock`
  - `utc_now()`（可用现有 `src/utils/time.py`，但测试可注入 fake）

原则：
- ports 的方法签名要稳定、窄、可 mock（只 mock 边界）。
- ports 的返回值必须可序列化到 artifacts/job.json。

## 2) Services（业务）拆分（建议）

保持单一职责：每个 service 管一个“状态机片段”。

- `JobService`
  - create_job（写 job.json）
  - confirm_job（推进状态 + 记录 scheduled_at/confirmed_at）
- `DraftService`
  - preview（load job → LLM → write draft/artifacts → 状态推进）
- `PlanService`
  - freeze_plan（基于确认信息生成 LLMPlan，写回 job.json）
- `RunService`
  - run_once（创建 run attempt → 生成 do-file → runner 执行 → 归档 artifacts → 更新状态）

## 3) API 装配（现在的形态）

`src/api/deps.py` 是依赖装配中心：
- `get_job_store()`/`get_llm_client()` → 注入到 services
- `get_job_service()`/`get_draft_service()` → 注入到 routes

约束：
- 不要在 routes 里 new store/client（让依赖集中）。
- services 不依赖 FastAPI 类型。

## 4) Worker 装配（未来形态）

worker 启动时加载 Config，构造 infra 实现，然后注入 domain `RunService`：

```text
worker main
  -> load_config()
  -> store = JobStore(...)
  -> queue = Queue(...)
  -> llm = LLMClient(...)
  -> runner = StataRunner(...)
  -> run_service = RunService(store=store, llm=llm, runner=runner, ...)
  -> loop: claim -> run_service.run_once()
```

## 5) 设计检查清单（写代码前先对照）

- 这个模块属于 api/domain/infra 哪一层？
- 依赖是否显式注入？是否出现隐式全局？
- 失败路径是否有结构化错误码与事件码日志？
- 是否需要 artifacts？如果需要，产物的 kind/路径/索引是否明确？
- 文件是否逼近 300 行？函数是否逼近 50 行？（提前拆分）

