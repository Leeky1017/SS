# [ROUND-02-FE-A] FE-B003: 待确认问题（Stage1 + OpenUnknowns）与澄清 Patch 流

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Related specs:
  - `openspec/specs/backend-stata-proxy-extension/spec.md`
- Legacy reference:
  - `legacy/stata_service/frontend/src/components/ConfirmationStep.tsx`
  - `legacy/stata_service/frontend/src/components/DraftPreview.tsx`

## Goal

在 Step 3 提供完整“阻断性确认 + 信息澄清”能力：必须回答 Stage1 选择题并补齐 blocking open_unknowns，才能进入确认执行。

## In scope

- 渲染 `stage1_questions`：
  - 支持 `single_choice` / `multi_choice`
  - 未回答时阻断确认
- 渲染 `open_unknowns`：
  - blocking 判定：`blocking == true` 或 `impact in (high, critical)`
  - 输入形态：文本输入；若 `candidates` 非空则优先提供候选下拉
- 提供“应用澄清并刷新预览”按钮：
  - 调用 `POST /v1/jobs/{job_id}/draft/patch` 提交 `field_updates`
  - 更新 remaining blockers 与预览字段展示（来自 patch 响应）

## Out of scope

- 默认值编辑（default_overrides）与 expert_suggestions 反馈（v1 不强制）

## Dependencies & parallelism

- Depends on: FE-B001（draft preview 数据可用）
- Can run in parallel with: FE-B002（变量纠偏 UI）

## Acceptance checklist

- [ ] Stage1 题目在 Step 3 明确呈现，且未回答时确认按钮不可用或触发明确校验提示
- [ ] blocking open_unknowns 必填，未填写时确认不可达
- [ ] “应用澄清并刷新预览”会调用 patch API，并用响应更新 UI（包括 remaining blockers）
- [ ] patch 后若仍有 blocking unknowns，确认仍被阻断
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md` 记录关键命令与输出

