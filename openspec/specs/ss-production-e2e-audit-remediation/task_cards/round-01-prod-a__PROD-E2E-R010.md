# [ROUND-01-PROD-A] PROD-E2E-R010: 将 do-template library 作为唯一权威执行资产接入（DI 方式）

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F001)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-production-e2e-audit/spec.md`

## Goal

把 `assets/stata_do_library/**` 接入为生产链路的唯一模板来源，并通过显式依赖注入（API/worker 依赖组装层）提供：

- `DoTemplateCatalog`（list families/templates）
- `DoTemplateRepository`（get template + meta）

## In scope

- 使用 `SS_DO_TEMPLATE_LIBRARY_DIR`（来自 `src/config.py`）作为唯一库路径来源。
- 在依赖注入层（例如 `src/api/deps.py` 与 worker 组装处）构建 `FileSystemDoTemplateCatalog` / `FileSystemDoTemplateRepository`，并注入到 domain services。

## Out of scope

- 改写模板库格式（library 是 data asset，格式固定）。

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: `PROD-E2E-R001` / `PROD-E2E-R040`

## Acceptance checklist

- [ ] `/v1` 链路中存在被注入并实际使用的 `DoTemplateCatalog` 与 `DoTemplateRepository`
- [ ] 配置路径仅来自 `src/config.py`（无散落 env 读取）
- [ ] 增加单元测试：给定一个 library_dir，可列出 templates 且可读取 template+meta（不依赖网络）

