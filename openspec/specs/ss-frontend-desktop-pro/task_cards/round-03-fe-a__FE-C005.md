# [ROUND-03-FE-A] FE-C005: Step 3（Blueprint 预检）UI 与状态机（引用 frontend-stata-proxy-extension）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Related specs:
  - `openspec/specs/frontend-stata-proxy-extension/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-ux-loop-closure/spec.md`

## Problem

Step 3 是“专业确认”的关键路径：用户需要在确认前完成变量纠偏、查看 warnings、处理澄清门控，并在确认后锁定 contract。
当前后端与 UI 可能存在能力缺口，必须在不崩溃的前提下实现可用降级。

## Goal

实现 Step 3 “分析蓝图预检”完整 UI 与状态机，严格复刻 Desktop Pro primitives，并对齐 `frontend-stata-proxy-extension` 的专业确认交互；在后端能力缺失时提供清晰可用的降级策略。

## In scope

- Draft preview：
  - `GET /v1/jobs/{job_id}/draft/preview`
  - 渲染 outcome/treatment/controls（或其等价字段）与草案文本（`draft_text`）
- 专业确认 UX（对齐 `frontend-stata-proxy-extension`）：
  - 变量纠偏（dropdown candidates + clear）
  - warnings 面板（severity/message/suggestion）
  - 澄清门控（stage1 questions + open unknowns + patch flow）
  - 降级风险 modal（require_confirm_with_downgrade）
  - 确认锁定（confirm 后 Step 3 进入只读态 + locked banner）
- 确认：
  - `POST /v1/jobs/{job_id}/confirm`
  - v1 允许只发送 `variable_corrections/default_overrides`（当后端不支持 answers 时）
- 可用降级（必须显式实现）：
  - 缺少 `data_quality_warnings` → 隐藏 warnings 面板
  - 缺少 `stage1_questions/open_unknowns` → 隐藏澄清门控面板，不因缺失数据阻断确认
  - 缺少 candidates → 优先使用 inputs preview `columns[].name` 作为候选；仍为空则隐藏 dropdown 并只读展示
  - `POST /v1/jobs/{job_id}/draft/patch` 不可用（404/501）→ 隐藏/禁用“应用澄清并刷新预览”，并显示非阻断提示

## Out of scope

- 后端 `draft/patch` / answers contract 的实现与演进
- Expert suggestions feedback / default overrides 编辑器的高级形态

## Dependencies & parallelism

- Depends on: FE-C004（需要 inputs 已上传且可预览）、FE-C002、FE-C001
- Can run in parallel with: FE-C006（状态/产物页）

## Acceptance checklist

- [ ] Step 3 UI 复刻 Desktop Pro primitives（`panel/section-label/btn/data-table/mono` + CSS 变量语义一致）
- [ ] 能调用并渲染 `GET /v1/jobs/{job_id}/draft/preview` 的结果（含错误态可恢复）
- [ ] 实现 `frontend-stata-proxy-extension` 的交互要点，并且降级策略符合本卡 In scope 的明确规则
- [ ] confirm 成功后 Step 3 进入锁定只读态（banner 可见、输入禁用、避免重复编辑）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录关键命令与输出

