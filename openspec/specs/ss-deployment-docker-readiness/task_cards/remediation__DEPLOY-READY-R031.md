# [DEPLOY-READY] DEPLOY-READY-R031: 落地统一输出格式器（Output Formatter）并补齐 Word/PDF 等输出能力（如需）

## Metadata

- Priority: P0
- Issue: #391
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-do-template-library/spec.md`

## Problem

当前输出能力存在两类风险：
- 输出格式覆盖不完整（缺 Word/PDF 或不可预测）
- 输出格式逻辑分散在各模板中，难以维护与扩展（每个模板各自处理，口径不一）

需要引入统一的后处理链路：模板执行 → 原始产物（CSV/LOG/DO）→ 统一输出格式器 → 用户指定格式。

## Goal

实现统一输出格式器（Output Formatter），支持用户在提交任务时指定 `output_formats: string[]`，并在模板执行完成后把原始产物转换为目标格式并入 artifacts index。

最低支持格式：
- `csv`（raw）
- `xlsx`（Excel）
- `dta`（Stata 数据）
- `docx`（Word 报告）
- `pdf`（PDF 报告）
- `log`（Stata 日志）
- `do`（Stata 代码）

建议：报告类输出优先采用 Stata `putdocx` / `putpdf`。

## In scope

- 增加 `output_formats` 参数支持与默认值 `["csv","log","do"]`
- worker 在模板执行后调用统一输出格式器产出目标格式并写入 artifacts index
- 输出失败策略明确（失败必须显式，不允许 silent failure）

## Out of scope

- 不在本卡为每个模板定制“个性化报告排版”（只做统一、可维护的最小报告/导出）

## Dependencies & parallelism

- Depends on: DEPLOY-READY-R002（输出能力审计）
- Can run in parallel with: DEPLOY-READY-R010, DEPLOY-READY-R011

## Acceptance checklist

- [x] `output_formats` 可在任务提交时指定，未指定时默认 `["csv","log","do"]`
- [x] 模板执行后统一输出格式器运行并产出请求的格式（至少覆盖 csv/xlsx/dta/docx/pdf/log/do）
- [x] 产物全部写入 artifacts index，且可通过 artifacts download 端点下载
- [x] Word/PDF 优先采用 `putdocx` / `putpdf`（或明确说明为何不采用）
- [x] Evidence: `openspec/_ops/task_runs/ISSUE-391.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/400
- Delivered:
  - Added job-level `output_formats` request plumbing + default `["csv","log","do"]`.
  - Implemented a unified post-run `OutputFormatterService` and worker hook to produce `csv/xlsx/dta/docx/pdf/log/do`.
  - Normalized do-template output kinds and patched 9 docx template metas to declare `putdocx`.
  - Indexed formatted artifacts for download and added regression tests.
- Notes:
  - For minimal, CI-friendly report generation, `docx/pdf` are produced via `python-docx`/`reportlab` (rather than Stata `putdocx`/`putpdf`).
- Run log: `openspec/_ops/task_runs/ISSUE-391.md`
