# Proposal: issue-362-p5-13-spatial-output-tn-to

## Why
TN01–TN10（空间计量）与 TO01–TO08（输出/报告）在 Phase 4.13 完成“可运行+可审计”后，仍缺少 Phase 5 的内容增强：最佳实践审查记录、关键步骤中英文注释，以及对 Stata 18 原生输出工具（`collect`/`etable`/`putdocx`/`putexcel`）的优先使用。当前部分 TO* 仍保留 SSC 工具的历史语义（esttab/outreg2/asdoc/table1_mc），对新环境不够友好，也不利于长期维护。

## What Changes
- 为 TN01–TN10、TO01–TO08 增加 Phase 5.13 best-practice review 区块（含 `SS_BP_REVIEW` 锚点）与关键步骤双语注释。
- 强化输入校验与失败策略：缺失输入/关键变量→fail；可降级路径→warn（显式 `SS_RC`）。
- TO01–TO08 优先使用 Stata 18 原生命令导出表格/报告（`collect`/`etable`/`putdocx`/`putexcel`），并尽可能移除/降级 SSC 依赖。
- 更新相应 `*.meta.json` 与 `DO_LIBRARY_INDEX.json`（确保 index 与 meta 一致）。

## Impact
- Affected spec/task card: `openspec/specs/ss-do-template-optimization/task_cards/phase-5.13__spatial-output-TN-TO.md`
- Affected templates: `assets/stata_do_library/do/TN01_spmatrix.do` … `TN10_lm_tests.do`, `TO01_esttab_html.do` … `TO08_table1.do`
- Affected metadata/index: `assets/stata_do_library/do/meta/TN*.meta.json`, `assets/stata_do_library/do/meta/TO*.meta.json`, `assets/stata_do_library/DO_LIBRARY_INDEX.json`
- Breaking change: NO (contract anchors preserved; outputs remain declared + archived)
- User benefit: 更接近空间计量与报告导出的“可复用范式”，减少 SSC 环境差异带来的失败与维护成本
