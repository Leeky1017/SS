# Proposal: issue-211-frontend-stata-proxy-extension

## Why

当前 Premium “Desktop Pro” 的 `index.html` 已完成视觉基线，但 Step 3 “分析蓝图预检”缺少旧版 `stata_service` 前端中被验证过的专业交互逻辑（变量纠偏、阻断性确认、数据质量预警、确认后锁定）。

在进入代码实现前，需要先把“用户可感知的前端行为 + API 消费契约 + 可验收拆分”写成可执行的 OpenSpec 与 task cards，避免后续实现漂移与重复讨论。

## What Changes

- Add a new frontend OpenSpec: `openspec/specs/frontend-stata-proxy-extension/spec.md`.
- Split the full frontend work into task cards under `openspec/specs/frontend-stata-proxy-extension/task_cards/` (no scattering).
- Keep this Issue doc-only: no changes to `index.html` / `src/` runtime code.

## Impact

- Affected specs:
  - `openspec/specs/frontend-stata-proxy-extension/spec.md`
  - `openspec/specs/frontend-stata-proxy-extension/task_cards/round-02-fe-a__FE-B001.md`
  - `openspec/specs/frontend-stata-proxy-extension/task_cards/round-02-fe-a__FE-B002.md`
  - `openspec/specs/frontend-stata-proxy-extension/task_cards/round-02-fe-a__FE-B003.md`
  - `openspec/specs/frontend-stata-proxy-extension/task_cards/round-02-fe-a__FE-B004.md`
  - `openspec/specs/frontend-stata-proxy-extension/task_cards/round-02-fe-a__FE-B005.md`
- Affected code: None
- Breaking change: NO
- User benefit: Step 3 UX upgrade has a single authoritative spec + a complete, non-scattered task breakdown for implementation and review.

