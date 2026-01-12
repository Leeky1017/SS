# Proposal: issue-391-deploy-ready-r031

## Why
SS 的输出格式逻辑目前分散在模板中，覆盖不完整且口径不一致（尤其 Word/PDF、`outputs[].type`→artifact kind 映射），导致产物不可预测、难以维护与扩展。需要落地统一的 post-run Output Formatter，并把用户请求的输出格式稳定写入 artifacts index，形成可下载的交付闭环。

## What Changes
- 增加 job-level `output_formats: string[]`（默认 `["csv","log","do"]`）并在任务提交/触发运行时写入 job.json。
- 新增 `OutputFormatterService`（domain）在模板执行后统一产出请求格式（csv/xlsx/dta/docx/pdf/log/do）并写入 artifacts index。
- 修复 artifact kind 归一化：补齐 meta `outputs[].type` (`data`/`report` 等) → artifact kind 的映射，避免错误归类为 log。
- 修复审计发现：补齐 9 个 docx 模板的 `putdocx` 依赖声明；补齐报告型 PDF 输出能力。

## Impact
- Affected specs:
  - `openspec/specs/ss-deployment-docker-readiness/spec.md`
  - `openspec/specs/ss-job-contract/spec.md` (artifacts index usage; job.json optional fields)
- Affected code:
  - Worker post-run formatting hook
  - Artifacts indexing / kind mapping
  - Do-template meta dependency declarations
- Breaking change: NO (additive fields + additive artifacts)
- User benefit: 用户可声明输出格式，模板执行后稳定产出并可下载（覆盖 csv/xlsx/dta/docx/pdf/log/do）。
