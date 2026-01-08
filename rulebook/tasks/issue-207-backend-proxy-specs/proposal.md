# Proposal: issue-207-backend-proxy-specs

## Why
当前 backend proxy extension 的 OpenSpec 内容存在，但没有放在 `openspec/specs/` 的 canonical 位置，且对应 task card 被放进了不相关的 spec 目录（`ss-job-contract`）。这会造成权威文档分散、引用路径不稳定，并违背 SS 的 OpenSpec 结构约束。

## What Changes
- Move backend proxy extension spec into canonical layout: `openspec/specs/backend-stata-proxy-extension/spec.md`。
- Move the task card into the same spec scope: `openspec/specs/backend-stata-proxy-extension/task_cards/...`。
- Update run log / rulebook references that point to the moved paths.
- This Issue is spec-only: no `src/**/*.py` changes, and do not touch `index.html`.

## Impact
- Affected specs:
  - `openspec/specs/backend-stata-proxy-extension/spec.md` (new canonical location)
  - `openspec/specs/backend-stata-proxy-extension/task_cards/backend__stata-proxy-extension.md`
- Affected code: None
- Breaking change: NO (documentation/layout only)
- User benefit: OpenSpec 与 task card 归位到 canonical 结构，后续实现与审计引用路径稳定、不会出现“spec 在 specs 外/任务卡挂错 spec”的歧义。
