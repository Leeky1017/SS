# Proposal: issue-209-backend-proxy-taskcard

## Why
当前 `openspec/specs/backend-stata-proxy-extension/task_cards/backend__stata-proxy-extension.md` 的内容偏“spec/交付收口记录”，而不是 SS task card 约定的“具体实现任务 + 可验收 checklist”。这会导致后续实现阶段缺少可追踪的工作拆解与验收口径，也不利于并行协作与回归保护。

## What Changes
- Rewrite the task card to be implementation-focused (variable corrections, structured draft preview, contract freeze validation), aligned to `openspec/specs/backend-stata-proxy-extension/spec.md`.
- Keep changes doc-only (markdown); no runtime code changes and do not touch `index.html`.

## Impact
- Affected specs:
  - `openspec/specs/backend-stata-proxy-extension/task_cards/backend__stata-proxy-extension.md`
- Affected code: None
- Breaking change: NO
- User benefit: 把“后端代理层补齐”的实现任务拆解为可执行、可测试的 checklist，便于未来 Issue/PR 复用与审计。
