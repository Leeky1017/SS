# [ROUND-01-UX-A] UX-B003: Worker 执行闭环（DoFileGenerator + 可配置 StataRunner + 产物）

## Metadata

- Issue: #128 https://github.com/Leeky1017/SS/issues/128
- Audit: #124 https://github.com/Leeky1017/SS/issues/124
- Priority: P0 (Blocker)
- Related specs:
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Goal

让 worker 的执行链路真正跑通：`LLMPlan` + inputs manifest → `DoFileGenerator` → `StataRunner`（可配置 Local/Fake）→ 产物归档与可下载。

## In scope

- `PlanStepType.GENERATE_STATA_DO`：使用 `DoFileGenerator` 生成 do-file（取代 stub do-file）
- runner 选择可配置：
  - dev/test 默认可用 `FakeStataRunner`
  - 生产配置使用 `LocalStataRunner`（基于 `SS_STATA_CMD`）
- 成功产物最小集：
  - `stata.do`、`stata.log`、`run.meta.json`
  - 尽力产出一个表格 artifact（如 `summary_table.docx`）
- 失败路径必须产出：
  - stdout/stderr/log/meta + `run.error.json`（结构化）
- 调整/补齐 user journey tests：端到端验证（允许 fake runner 后端）

## Dependencies & parallelism

- Depends on: `DoFileGenerator`（ARCH-T052, #25 已完成）
- Depends on: `LocalStataRunner`（ARCH-T051, #24 已完成）
- Depends on: plan freeze（`UX-B002`）

## Acceptance checklist

- [ ] worker 不再生成 stub do-file；改由 DoFileGenerator 生成（确定性）
- [ ] runner 可配置，且生产配置能用 LocalStataRunner（SS_STATA_CMD）
- [ ] 成功/失败产物满足最小集（含结构化 run.error.json）
- [ ] user journey tests 覆盖执行与产物下载（可用 fake runner）
