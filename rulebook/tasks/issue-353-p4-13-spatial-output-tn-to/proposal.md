# Proposal: issue-353-p4-13-spatial-output-tn-to

## Why
TN*（空间计量）与 TO*（输出/报告）模板仍包含 legacy `SS_*:` anchors 与不一致的失败处理，导致 smoke-suite 解析、依赖缺失识别与运行证据不可审计。

## What Changes
- 为 TN01–TN10、TO01–TO08 建立专用 smoke-suite manifest（fixtures + params）。
- 将 legacy anchors（如 `SS_TASK_VERSION:<ver>`, `SS_ERROR:<code>:...`）统一为 `SS_EVENT|k=v`（含 `SS_TASK_VERSION|version=...` 与 `SS_RC|...`）。
- 修复 Stata 18 batch runs 的运行时错误（含依赖缺失/数据形状/输出路径防御）。

## Impact
- Affected spec/task card: `openspec/specs/ss-do-template-optimization/task_cards/phase-4.13__spatial-output-TN-TO.md`
- Affected templates: `assets/stata_do_library/do/TN01_spmatrix.do` … `TN10_lm_tests.do`, `TO01_esttab_html.do` … `TO08_table1.do`
- New artifacts: `assets/stata_do_library/smoke_suite/manifest.issue-353.tn01-tn10.to01-to08.1.0.json`
- Breaking change: NO (anchors normalized; behavior remains “run + auditable”)

