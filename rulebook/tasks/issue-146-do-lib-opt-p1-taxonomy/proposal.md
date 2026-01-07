# Proposal: issue-146-do-lib-opt-p1-taxonomy

## Why
SS 的 do-template library 目前 family 存在重复/歧义（如 `panel` vs `panel_data`），且缺少集中维护的 aliases/keywords/use_when/fallbacks，导致 LLM 检索与审计困难。

## What Changes
- 新增版本化 canonical family registry（含 aliases/keywords/use_when/fallbacks）与 JSON Schema。
- 提供确定性的 family alias 解析与模板→canonical family 映射工具函数。
- 生成并提交稳定的 `FamilySummary`（~2K tokens）供 Stage-1 使用，并用测试锁定再生稳定性。

## Impact
- Affected specs: `openspec/specs/ss-do-template-optimization/task_cards/phase-1__taxonomy-canonicalization.md`
- Affected code: `src/domain/do_template_taxonomy.py`
- Breaking change: NO
- User benefit: family 解析确定性 + 可审计，且 Stage-1 可在 token 预算内稳定选择候选 families。
