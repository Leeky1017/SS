# Spec — Required check names alignment

## Goal

让 PR 上的 check runs 名称与工作流契约一致：
- `ci`
- `openspec-log-guard`
- `merge-serial`

## Requirements

1) Workflow job names
- `ci` workflow产出的 check run 名称为 `ci`
- `openspec-log-guard` workflow产出的 check run 名称为 `openspec-log-guard`
- `merge-serial` workflow产出的 check run 名称为 `merge-serial`

2) Documentation
- 文档说明：在 GitHub 分支保护中将上述三项设为 required checks，并启用 auto-merge。

