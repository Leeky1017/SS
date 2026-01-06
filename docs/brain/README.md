# SS 主脑总纲（Master Brain）

SS 的目标：构建一个以 **LLM 为“大脑”** 的 Stata 实证分析自动化系统，并以 **可维护性优先** 的方式持续演进。

这份文档集是 SS 的“主脑形态”规划：它不追求一次写完所有细节，而是把后续所有模块的口径、边界、数据契约、验收方式先统一，避免“边写边长出全局耦合”。

## 你应该先记住的硬约束（不可破）

- 分层边界：`src/api/` 只做 HTTP 薄层；业务在 `src/domain/`；外部系统在 `src/infra/`；通用工具在 `src/utils/`。
- 依赖必须显式注入：FastAPI `Depends` / 构造函数参数；禁止隐式全局单例与动态代理。
- 异常必须可观测：只捕获具体异常；返回结构化错误码；日志必须包含事件码 + 关键上下文。
- 尺寸上限：每个函数 `< 50` 行；每个文件 `< 300` 行（超过必须拆分）。

## 主脑是什么（在 SS 里的定义）

“主脑”不是把一切都交给 LLM 随机生成，而是把 LLM 的作用 **收敛为可审计、可回放、可替换** 的能力模块：

- LLM 输出必须是结构化的 `LLMPlan`（或明确的业务产物），而不是不可控的自由文本脚本。
- 每次 LLM 调用都必须落盘为 artifacts（prompt/response/settings/timing/redaction），并可在 job 目录内复现。
- 任何 “LLM 说了算” 的地方，都必须有显式的安全边界（脱敏、拒绝策略、执行隔离）。

## 最小闭环（从今天到可跑的端到端）

当前骨架（已具备）：`POST /jobs` → `GET /jobs/{job_id}/draft/preview` → `POST /jobs/{job_id}/confirm`（见 `docs/architecture.md`）。

后续闭环演进（目标形态）：

1) Create：创建 job，写入 `jobs/<job_id>/job.json`
2) Draft：收集输入摘要 + requirement → LLM 草案 → 写回 job.json + artifacts
3) Confirm：冻结 `LLMPlan`（确定性 + 可验证）→ job 进入 `queued`
4) Run（worker）：claim queued job → 生成 do-file → 跑 Stata → 归档 log/表/图 → job 进入 `succeeded/failed`
5) Inspect：API 提供 job 状态与 artifacts 下载，支撑调试与 UI

## 核心对象（贯穿全系统）

- **Job（job.json）**：权威状态 + 索引（状态机字段、inputs manifest、plan、runs、artifacts）
- **Artifacts**：所有关键输入/输出/trace 的可追溯文件集合（LLM/runner/logs/results）
- **LLMPlan**：结构化的执行计划（step 列表 + 参数 + 依赖 + 预期产物）
- **RunAttempt**：一次实际执行尝试（run_id、开始/结束、状态、退出码、log/artifacts）

## 文档导航（从“主脑”拆分出去的子文档）

- `docs/brain/01-principles.md`：原则、边界、依赖注入与交付准则
- `docs/brain/02-job-and-artifacts.md`：job.json v1 与 artifacts 目录/索引规范
- `docs/brain/03-state-machine-and-idempotency.md`：状态机、幂等键、并发与重试
- `docs/brain/04-ports-and-services.md`：domain ports 与 services 的拆分（可测试的业务骨架）
- `docs/brain/05-llm-brain.md`：LLMPlan、prompt/response artifacts、脱敏与安全边界
- `docs/brain/06-worker-queue.md`：worker/queue/claim/run attempt 的执行框架
- `docs/brain/07-stata-runner.md`：StataRunner、do-file 生成、执行隔离与产物归档
- `docs/brain/08-api-contract.md`：API 契约与演进路线（保持薄层）
- `docs/brain/09-roadmap.md`：Issue 路线图（Epic + 子 Issue）

## 路线图（GitHub Issues）

- Roadmap 主 Issue：#9
- Epics：
  - #10（Job 模型 + job.json v1 + 状态机）
  - #11（API 扩展）
  - #12（LLM Brain：Plan + artifacts）
  - #13（Worker/Queue）
  - #14（Stata Runner）
  - #15（Observability & Security）

## 本地验证（每次 PR 必跑）

```bash
ruff check .
pytest -q
```

