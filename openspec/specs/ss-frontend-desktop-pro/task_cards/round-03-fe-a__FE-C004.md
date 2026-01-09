# [ROUND-03-FE-A] FE-C004: Step 2（Upload + Inputs Preview）完整可用（含错误态）

## Metadata

- Priority: P0
- Issue: #243
- Spec: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Related specs:
  - `openspec/specs/ss-ux-loop-closure/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Problem

没有真实可用的数据上传与预览，用户无法确认列名与样本行，后续 Draft/Plan 质量也无法保证；同时上传/解析失败的错误态如果不可恢复，会直接阻断闭环。

## Goal

实现 Step 2 “上传数据 + 预览”：支持 CSV/XLSX/DTA 上传，上传成功后能看到列与样本行预览；失败时提供明确错误与可重试体验。

## In scope

- Upload：
  - `POST /v1/jobs/{job_id}/inputs/upload`（`multipart/form-data`，至少支持单文件 primary dataset）
  - UI 复刻 `index.html` 的 drop-zone 交互（拖拽/点击选择）
  - 成功后显示 `manifest_rel_path` 与 `fingerprint`（mono）
- Preview：
  - `GET /v1/jobs/{job_id}/inputs/preview`（默认 rows/columns，UI 可提供“刷新预览”）
  - 以 `data-table` 渲染 `columns[]` 与 `sample_rows[]`（bounded）
- 错误态（可恢复）：
  - 上传失败/解析失败/预览失败：展示结构化错误 + request id + 重试按钮
- 状态持久化：
  - 上传结果与 preview 快照（best-effort），用于刷新恢复

## Out of scope

- 多数据源/多工作表的复杂选择 UX（可后续扩展）
- Blueprint 预检（见 FE-C005）

## Dependencies & parallelism

- Depends on: FE-C003（需要 `job_id`）、FE-C002、FE-C001
- Can run in parallel with: FE-C006（状态/产物页）

## Acceptance checklist

- [x] 上传成功后显示 `manifest_rel_path` 与 `fingerprint`
- [x] 预览页可渲染 columns + sample rows（`data-table`），并支持“刷新预览”
- [x] 错误态可恢复（清晰提示 + request id + 重试）
- [x] 刷新页面后不丢失 `job_id`，且能回到 Step 2 并继续预览/重试
- [x] Evidence: `openspec/_ops/task_runs/ISSUE-243.md` 记录关键命令与输出

## Completion

- PR: https://github.com/Leeky1017/SS/pull/245
- Step 2 drop-zone 上传（CSV/XLSX/DTA）+ 上传结果展示（manifest/fingerprint）
- Inputs preview 渲染 columns + sample_rows，并支持“刷新预览”
- 失败态统一展示结构化错误 + request id，并提供重试/重新兑换
- Run log: `openspec/_ops/task_runs/ISSUE-243.md`
