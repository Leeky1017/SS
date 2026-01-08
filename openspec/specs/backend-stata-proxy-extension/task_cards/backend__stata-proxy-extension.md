# [BACKEND] Stata Proxy Extension: variable corrections + structured draft preview + contract freeze validation

## Metadata

- Issue: #203 https://github.com/Leeky1017/SS/issues/203
- Related specs:
  - `openspec/specs/backend-stata-proxy-extension/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-delivery-workflow/spec.md`

## Goal

把旧版 `stata_service` 的代理层遗珠（变量纠偏、结构化草案预览、冻结前列名交叉验证）以 **spec-first** 的方式固化为可验证契约，为后续实现提供唯一权威输入。

## In scope

- OpenSpec：`openspec/specs/backend-stata-proxy-extension/spec.md`
  - 功能目标、Schema 变更清单、Service 变更清单
  - API 端点 Request/Response JSON 契约
  - confirm→StataRunner 前的数据流图（Mermaid）
  - 验收测试用例（pytest 名称 + 行为断言）
- Rulebook task：`rulebook/tasks/issue-203-backend-stata-proxy-extension/`（proposal + tasks）
- Run log：`openspec/_ops/task_runs/ISSUE-203.md`（关键命令 + 关键输出 + 证据路径）

## Out of scope

- 修改任何 `src/**/*.py`（本 Issue 仅规格与交付链路）
- 为上述能力编写实现代码或测试代码
- 修改现有执行引擎（`src/domain/composition_exec/`）

## Dependencies & parallelism

- Hard dependencies: None (spec-only)
- Can run in parallel after this merges: the implementation Issue(s) that actually modify API/models/services/tests

## Acceptance checklist

- [x] `openspec/specs/backend-stata-proxy-extension/spec.md` 覆盖：变量纠偏、结构化草案预览、契约冻结校验三大目标，并包含 schema/service/endpoint/dataflow/acceptance
- [x] `rulebook/tasks/issue-203-backend-stata-proxy-extension/proposal.md` 与 `rulebook/tasks/issue-203-backend-stata-proxy-extension/tasks.md` 填写完整
- [x] `openspec/_ops/task_runs/ISSUE-203.md` 记录关键命令与输出（Issue/worktree/validate/preflight/PR）
- [x] 通过本地 gates 并在 run log 留证：`openspec validate --specs --strict --no-interactive`、`ruff check .`、`pytest -q`
- [x] PR 满足交付门禁：branch `task/203-backend-stata-proxy-extension`、commit message 包含 `(#203)`、PR body 包含 `Closes #203`、required checks 全绿并启用 auto-merge

## Evidence

- Run log: `openspec/_ops/task_runs/ISSUE-203.md`
- Local gates:
  - `openspec validate --specs --strict --no-interactive`
  - `ruff check .`
  - `pytest -q`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/204
- Run log: `openspec/_ops/task_runs/ISSUE-203.md`
- Summary:
  - Added OpenSpec for backend proxy extension (goals, schema/service deltas, endpoint contracts, dataflow, acceptance tests)
  - Added task card under `backend-stata-proxy-extension` spec for tracking and closeout
  - Added Issue run log with validation + preflight evidence and auto-merge metadata
