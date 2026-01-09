# [ROUND-02-FE-A] FE-B005: 数据质量预警（Data Quality Warnings）展示

## Metadata

- Priority: P1
- Issue: TBD
- Spec: `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Legacy reference:
  - `legacy/stata_service/frontend/src/components/DraftPreview.tsx`

## Goal

让用户在确认前看到结构化的数据质量预警，并获得可操作的建议，以减少“执行后才发现数据不适配”的返工。

## In scope

- 在 Step 3 展示 `data_quality_warnings` 面板：
  - severity（info/warning/error）可区分
  - message 必显示
  - suggestion 若存在则展示
- 保持视觉一致：复用现有 `panel`/`section-label` 体系

## Out of scope

- 对 warning 的自动修复（仅展示 + 建议）

## Dependencies & parallelism

- Depends on: FE-B001（能拿到 draft preview 响应）
- Can run in parallel with: FE-B002 / FE-B003

## Acceptance checklist

- [ ] 存在 `data_quality_warnings` 时，Step 3 必显示预警面板
- [ ] 每条预警至少包含 severity + message；suggestion（如有）可见
- [ ] UI 视觉与现有 Desktop Pro 风格一致
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md` 记录关键命令与输出

