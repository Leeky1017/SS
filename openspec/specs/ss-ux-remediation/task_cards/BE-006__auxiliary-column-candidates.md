# Task Card: BE-006 Auxiliary column candidates

- Priority: P1-HIGH
- Area: Backend / Draft
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

当前变量候选列表只包含主文件的列，不包含辅助文件的列。用户无法选择辅助文件中的变量（例如“政府干预程度”），导致面板回归/合并分析等场景无法完成。

## 技术分析

- 现状：
  - Draft 预览 API 返回 `DraftPreviewResponse.column_candidates: list[str]`（`src/api/draft.py` / `src/api/schemas.py`）。
  - 多文件上传已存在（`POST /v1/jobs/{job_id}/inputs/upload` 支持多个 role），但候选列集合是否合并取决于 `DraftService` 的实现策略。
- 缺口：候选列缺少“来源信息”，即使后端合并列名，前端也无法分组展示或避免同名冲突（主/辅文件同列名）。

## 解决方案

1. 在 domain 层生成候选列时合并所有已上传数据集（主 + 辅），并携带来源（推荐使用 `dataset_key` + `role`）。
2. API 契约改造（尽量非 breaking）：
   - 保留现有 `column_candidates: list[str]`（保持兼容）。
   - 新增 `column_candidates_v2: list[{dataset_key: str, role: str, name: str}]`（或等价命名），用于前端分组展示与消歧。
3. 前端在变量选择下拉框中按数据集分组显示（例如“主文件 / 辅助文件 1 / 辅助文件 2”），并在提交时携带来源信息或做稳定映射（避免同名冲突）。

## 验收标准

- [ ] 变量选择下拉框显示所有文件的列，并按来源分组
- [ ] 选择辅助文件列时后端能稳定识别来源与列名（同名列不会混淆）
- [ ] 契约变更遵循“后端先改 → 生成前端 types → 再改前端”流程（避免漂移）

## Dependencies

- 无
