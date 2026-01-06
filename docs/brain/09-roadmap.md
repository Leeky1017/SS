# 09 — 路线图（Epics & Sub-Issues）

这份路线图的目的：把“主脑形态”拆成可交付的纵切任务，每个任务都能独立验收并保持仓库可维护性。

## 0) Roadmap 总览

- 主 Issue（Master Brain doc）：#9
- Epics：
  - #10：Job 模型 + job.json v1 + 状态机
  - #11：API 扩展（status/artifacts/run trigger）
  - #12：LLM Brain（PlanService + artifacts）
  - #13：Worker/Queue（claim + retry + run attempts）
  - #14：Stata Runner（do-file + 执行 + 产物）
  - #15：Observability & Security 基线

## 1) Epic #10：Job 模型 + job.json v1 + 状态机

- #16：定义 job.json v1 schema + Pydantic models
- #17：状态机 guard + 幂等键（revision/fingerprint）

依赖建议：
- #16 应优先于 #18/#19/#20（API/Plan 都需要稳定 schema）

## 2) Epic #11：API 扩展

- #18：新增 GET /jobs/{job_id}
- #19：Artifacts API（index+download）+ Run trigger

依赖建议：
- #18/#19 依赖 #16（job/artifact 模型）
- artifacts 下载依赖 #27（安全红线）中的路径约束落地

## 3) Epic #12：LLM Brain

- #20：PlanService + LLMPlan schema（确定性 stub）
- #21：LLM 调用 artifacts（prompt/response/元数据/脱敏）

依赖建议：
- #20 依赖 #16（plan 写入 job.json）
- #21 依赖 #26/#27（日志规范与脱敏策略）

## 4) Epic #13：Worker/Queue

- #22：Queue 抽象 + file-based 实现（claim）
- #23：Worker loop + run attempt 目录 + retry/backoff

依赖建议：
- #23 依赖 #22（claim 机制）与 #17（状态机推进）

## 5) Epic #14：Stata Runner

- #24：StataRunner port + LocalStataRunner subprocess
- #25：DoFileGenerator（从 plan 生成 do-file）

依赖建议：
- #25 依赖 #20（plan schema）
- #24/#25 的产物归档依赖 #16（artifacts 模型）

## 6) Epic #15：Observability & Security

- #26：结构化日志规范 + 配置化 log_level
- #27：安全红线落地（路径/注入/敏感信息）

建议策略：
- #26/#27 尽量前置，避免“先堆功能后补安全/可观测”导致返工

## 7) 交付纪律（每个 Issue 的 Definition of Done）

- 有对应的 OpenSpec spec（delta requirements + verifiable scenarios）
- 有 Rulebook task（proposal + tasks）
- 有 tests（只测业务逻辑与边界，不测第三方框架内部）
- `ruff check .` + `pytest -q` 全绿
- `openspec/_ops/task_runs/ISSUE-N.md` 记录关键命令与输出

