# Task Card: BE-007 Column name normalization

- Priority: P1-HIGH
- Area: Backend / Plan
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

中文列名（如“经济发展水平”）无法直接用于 Stata 脚本（变量名限制/编码约束），需要建立稳定的 `original → normalized` 映射，并且映射关系必须可追溯、可展示给用户确认。

## 技术分析

- 现状：
  - 计划冻结与 do-file 生成需要使用“可被 Stata 接受”的变量名（`src/domain/do_file_generator.py`）。
  - 当前 API/前端允许用户在 Step3 中提交 `variable_corrections`（`ConfirmJobRequest.variable_corrections`），但缺少系统级的“自动生成 + 用户确认”映射机制。
- 风险：
  - 自动生成但不可追溯会导致用户不信任（看不懂变量替换）。
  - 非稳定算法会导致同一列名在不同 run 中映射不同，难以复现。

## 解决方案

1. 在 domain 层新增标准化组件（建议新文件 `src/domain/column_normalizer.py`，保持纯函数/可测试）：
   - 输入：`[{dataset_key, original_name}]`（必要时含 role/来源）
   - 输出：`[{dataset_key, original, normalized}]`（确保 normalized 唯一）
2. 算法要求：
   - 稳定：同样的输入顺序/集合产生同样输出（排序 + 去重 + 冲突后缀）。
   - 可读：尽量保留可读前缀（例如拼音首字母/英文单词），并限制长度。
   - 合法：满足 Stata 变量名规则（字母开头、仅字母数字下划线、长度限制等）。
3. API 契约：
   - Draft 预览（或 Plan 预览）返回映射表供前端展示与确认。
   - 前端确认/修正后的映射通过 `ConfirmJobRequest.variable_corrections`（或新增专用字段）提交。
4. Do-file 生成时使用“确认后的映射”填充模板参数，并将映射写入 artifacts（便于复现/审计）。

## 验收标准

- [ ] 中文列名自动生成 Stata 可用代号（合法且唯一）
- [ ] 用户可以查看并修正映射（UI 展示来源 + original + normalized）
- [ ] 最终脚本使用确认后的变量名（可在 do-file/plan.json 或专用 artifact 中追溯）

## Dependencies

- 无
