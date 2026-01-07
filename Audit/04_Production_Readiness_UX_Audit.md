# SS 生产就绪审计（用户体验闭环）

- Date: 2026-01-07
- Scope: “真实用户能否通过 SS 完成一次完整的实证分析，并拿到可用的结果文件？”
- Verdict: **Not Ready**

## 结论（面向用户价值）

当前 SS **无法跑通最小用户闭环**：用户仅通过现有 HTTP API 无法完成“上传数据 → 生成可执行计划（plan）→ worker 执行 → 产出结果文件下载”。

阻塞点主要集中在：**输入数据链路缺失**、**plan 冻结/执行链路未接入用户路径**、**worker 默认不执行真实 Stata 且产物不足以形成“结果文件”**。

## 审计方法与证据

### 代码走查范围

- API：`src/api/jobs.py`、`src/api/draft.py`、`src/api/schemas.py`
- Domain：`src/domain/draft_service.py`、`src/domain/plan_service.py`、`src/domain/worker_plan_executor.py`
- Worker：`src/worker.py`

### 可运行验证

- `.venv/bin/ruff check .`（PASS）
- `.venv/bin/pytest -q`（PASS：95 passed, 5 skipped）
- 证据记录：`openspec/_ops/task_runs/ISSUE-124.md`

### 对齐的权威规格

- `openspec/specs/ss-api-surface/spec.md`
- `openspec/specs/ss-llm-brain/spec.md`
- `openspec/specs/ss-stata-runner/spec.md`
- `openspec/specs/ss-state-machine/spec.md`
- `openspec/specs/ss-testing-strategy/README.md`

## 用户体验闭环检查结果（6 阶段）

说明：每条结论都以“仅通过当前 API + worker 默认实现”作为判定基准；测试中直接注入 service（如 `PlanService.freeze_plan()`）的路径，不视为真实用户能力。

### 1) 输入阶段

- [ ] 用户能否上传数据文件（CSV、Excel、DTA）？
  - 结论：FAIL（当前 API 未提供上传入口；`src/api/` 未包含相关路由）
- [x] 用户能否输入自然语言分析需求？
  - 结论：PASS（`POST /v1/jobs`，见 `src/api/jobs.py` + `src/api/schemas.py`）
- [ ] 上传的文件是否被正确解析（列识别、数据预览）？
  - 结论：FAIL（无上传/解析/预览端点）
- [ ] 错误输入（空文件、格式错误）是否有清晰提示？
  - 结论：FAIL（该能力缺失，无法验证）

### 2) 理解阶段

- [ ] SS 是否能理解用户的分析需求？
  - 结论：PARTIAL（`draft/preview` 返回的是 stub 文本；不构成“理解”，见 `src/domain/llm_client.py`）
- [ ] LLM 是否正确生成分析计划（plan）？
  - 结论：FAIL（`PlanService` 存在但未接入用户链路；见 `src/domain/plan_service.py`，且 API 不调用）
- [ ] 变量映射是否正确？
  - 结论：FAIL（缺少输入数据预览与映射机制）
- [ ] 用户能否查看和理解 SS 的分析方案？
  - 结论：FAIL（缺少 plan 生成/预览的用户入口；plan 只在测试里通过直接调用生成）

### 3) 确认阶段

- [x] 用户能否查看契约草案（Draft）？
  - 结论：PASS（`GET /v1/jobs/{job_id}/draft/preview`，见 `src/api/draft.py`）
- [x] Draft 内容是否清晰可读？
  - 结论：PASS（文本可读，但为 stub；适合开发期，不足以代表生产质量）
- [x] 用户能否确认/拒绝 Draft？
  - 结论：PARTIAL（`POST /v1/jobs/{job_id}/confirm` 支持 confirmed=false，但当前实现为 noop，不引入“rejected”状态；见 `src/domain/job_service.py`）
- [x] 确认后 Job 状态是否正确转移？
  - 结论：PASS（`draft_ready -> confirmed -> queued`；非法转移会 409，见 `src/domain/state_machine.py`）

### 4) 执行阶段

- [x] Job 是否被正确入队？
  - 结论：PASS（confirm/run trigger 仅入队；`QueueJobScheduler.schedule()` 调用 `queue.enqueue()`，见 `src/infra/queue_job_scheduler.py`）
- [ ] Worker 是否正确领取并执行任务？
  - 结论：FAIL（worker 执行依赖 `job.llm_plan`；但 plan 未对用户生成，`execute_plan()` 会返回 `PLAN_MISSING`，见 `src/domain/worker_plan_executor.py`）
- [ ] Stata 是否被正确调用？
  - 结论：FAIL（`src/worker.py` 默认使用 `FakeStataRunner`，不会调用真实 Stata）
- [ ] 执行过程中的状态是否可查询（running/progress）？
  - 结论：PARTIAL（`GET /v1/jobs/{job_id}` 可查询 status/attempt；未提供细粒度 progress，见 `src/api/jobs.py`）
- [ ] 执行失败时是否有清晰的错误信息？
  - 结论：PARTIAL（runner 失败会生成 `run.error.json` artifact；但 plan 缺失类错误不会产生 artifacts，且 job status 响应不包含错误摘要）

### 5) 输出阶段

- [ ] 执行成功后是否生成预期的产物？
  - 结论：PARTIAL（fake runner 会产出 do/log/stdout/stderr/meta；但缺少“结果表格/图表”等用户可用结果文件）
- [ ] 产物是否包含：log 文件、结果表格、图表（如有）？
  - 结论：FAIL（当前默认链路缺少表格/图表产物；`LocalStataRunner` 支持采集导出表，但 worker 未接入且 do-file 生成未接入 `DoFileGenerator`）
- [ ] 用户能否下载 Word/PDF/dta 等格式的结果文件？
  - 结论：PARTIAL（download endpoint 存在：`GET /v1/jobs/{job_id}/artifacts/{rel_path}`；但默认链路不产生 Word/PDF/dta 结果）
- [x] 产物是否被正确归档到 artifacts？
  - 结论：PASS（artifacts index + path-safe download 已实现；见 `src/domain/artifacts_service.py`）

### 6) 可恢复性

- [x] 用户刷新页面后能否恢复到之前的状态？
  - 结论：PASS（状态持久化在 `job.json`，可通过 `GET /v1/jobs/{job_id}` 恢复）
- [x] 网络中断后重新连接，Job 状态是否正确？
  - 结论：PASS（同上；状态查询为幂等读取）
- [ ] 执行失败后用户能否重试？
  - 结论：PARTIAL（worker 内部有 retry；但 job 到 `failed/succeeded` 后 `POST /v1/jobs/{job_id}/run` 为幂等 noop，用户侧通常只能新建 job）

## Blockers（阻塞问题）

> Blocker 判定口径：若不解决，该阶段的核心功能无法完成，从而无法完成完整闭环。

1. **UX-B001：数据上传 + 数据预览缺失**
   - Issue: #126
   - Task card: `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B001.md`
2. **UX-B002：Plan 冻结与预览未接入用户链路**
   - Issue: #127
   - Task card: `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B002.md`
3. **UX-B003：Worker 执行闭环未接入 DoFileGenerator/真实 Runner，缺少可用结果产物**
   - Issue: #128
   - Task card: `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B003.md`

## Nice-to-have（非阻塞但高价值）

- Job status 增加更可解释的执行进度（例如 step-level 或阶段化 progress）
- Draft “拒绝/驳回”显式状态（而非 confirmed=false noop）
- 统一“失败摘要”呈现：在 `GET /v1/jobs/{job_id}` 里提供 latest_run 的 error 摘要（同时保留 artifacts 作为证据）
- 对齐 `ss-testing-strategy` 场景 A 描述与当前 user journey tests 覆盖范围（当前测试未覆盖 upload/preview/mapping）
