# [ROUND-02-FE-A] FE-B002: 变量纠偏（Variable Corrections）映射 UI

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Related specs:
  - `openspec/specs/backend-stata-proxy-extension/spec.md`
- Legacy reference:
  - `legacy/stata_service/frontend/src/components/DraftPreview.tsx`

## Goal

在 Step 3 提供“修正变量映射”可展开区域，允许用户把系统识别的变量名纠偏到真实列名，并保持可撤销/可清空。

## In scope

- 引入 `variableCorrections: Record<string, string>` 的前端状态
- 显示并可编辑：
  - 因变量（outcome_var）下拉纠偏
  - 自变量（treatment_var）下拉纠偏
  - 控制变量（controls）逐项下拉纠偏
- 候选项来源规则（按 spec）：`column_candidates` → `variable_types[].name` → 当前变量集合兜底
- “清除修正”按钮：仅在存在纠偏时显示，点击后清空纠偏

## Out of scope

- 纠偏写入后端（在 confirm 时提交；见 FE-B004）
- 自动修复变量名合法性（由后端冻结校验负责；见 backend spec）

## Dependencies & parallelism

- Depends on: FE-B001（Step 3 已获取 draft preview 数据）
- Can run in parallel with: FE-B005（warnings UI）

## Acceptance checklist

- [ ] 用户可在 Step 3 展开“修正变量映射”并看到 outcome/treatment/controls 对应的下拉框
- [ ] 下拉候选项来自 `column_candidates`（优先）或 fallback 规则
- [ ] 选择纠偏后，Step 3 蓝图表格展示纠偏后的变量名（不直接改写原始 draft 字段）
- [ ] 点击“清除修正”可恢复到原始变量展示
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md` 记录关键命令与输出

