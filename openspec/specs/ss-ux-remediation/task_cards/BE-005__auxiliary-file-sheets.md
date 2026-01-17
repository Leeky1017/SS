# Task Card: BE-005 Auxiliary file sheet selection

- Priority: P1-HIGH
- Area: Backend / Inputs
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

当前系统只允许对主文件选择 Excel sheet，辅助文件无法选择 sheet。用户上传多 sheet 的 Excel 辅助文件时，系统无法正确识别数据或无法按用户期望使用正确的数据表。

## 技术分析

- 现状：
  - 主文件 sheet 选择端点已存在：`POST /v1/jobs/{job_id}/inputs/primary/sheet`（`src/api/inputs_primary_sheet.py`）。
  - 输入预览端点目前只预览主文件：`GET /v1/jobs/{job_id}/inputs/preview`（`src/api/jobs.py` → `JobInputsService.preview_primary_dataset(...)`）。
  - manifest 目前仅支持主文件 sheet options：`src/domain/inputs_manifest.py` 只有 `primary_dataset_excel_options(...)` / `set_primary_dataset_excel_options(...)`。
- 缺口：
  - 无法针对辅助数据集（非 primary dataset）保存 sheet_name/header_row 选项。
  - UI 无法获取每个文件的 sheet_names/selected_sheet，从而无法呈现“辅助文件 sheet 选择”。

## 解决方案

1. 端点设计（二选一，优先方案 A）：
   - A（推荐，稳定标识）：新增 `POST /v1/jobs/{job_id}/inputs/datasets/{dataset_key}/sheet`，参数 `sheet_name`，并返回该 dataset 的 `sheet_names`/`selected_sheet`/`header_row`。
   - B（按指令草案，兼容 UI “第 N 个辅助文件”）：新增 `POST /v1/jobs/{job_id}/inputs/auxiliary/{index}/sheet`。
2. 扩展 manifest 支持“任意 dataset”的 Excel options（sheet_name/header_row），并由 `InputsSheetSelectionService` 提供相应选择方法（对齐 primary 的校验/写入/日志）。
3. 扩展 inputs preview 响应（非 breaking）：
   - 保留现有字段（主文件预览）。
   - 新增可选字段（例如 `datasets[]`）包含每个文件的 `dataset_key/role/original_name/sheet_names/selected_sheet`，供前端渲染辅助文件 sheet 选择 UI。

## 验收标准

- [ ] 辅助文件可选择指定 sheet
- [ ] 选择结果持久化到 manifest，并在后续（预览/变量候选/计划生成）中生效
- [ ] 错误场景（sheet 不存在/非 Excel）返回结构化错误（`error_code` + `message`），不暴露内部异常

## Dependencies

- 无
