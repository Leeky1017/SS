# [DEPLOY-READY] DEPLOY-READY-R002: 审计 do-template 库的输出格式能力（csv/dta/docx/pdf）与输出产物口径

## Metadata

- Priority: P0
- Issue: #370
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`

## Problem

生产可用的交付物需要明确可预期的输出格式与下载产物，但当前存在不确定性：
- do-template 当前实际能产出哪些格式（CSV/DTA/DOCX/PDF/LOG/DO）
- 各模板输出命名与类型是否一致（artifact kind / file extension / meta）
- 是否需要/可行新增 Word/PDF 报告输出能力（以及推荐实现：Stata `putdocx` / `putpdf`）

此外，后续需要引入“统一输出格式器”（Output Formatter）后处理链路，本卡需要为整改任务提供事实依据。

## Goal

形成一份基于 `assets/stata_do_library/` 的输出能力审计结论，明确：
- 当前模板输出格式覆盖面（按模板/模块/家族统计）
- Word/PDF 输出是否已存在、采用何种实现（优先识别 `putdocx` / `putpdf`）
- 输出产物的命名/类型/索引是否满足“可下载、可解释、可验收”
- 为 DEPLOY-READY-R031 提供整改输入（缺什么、怎么补、优先级）

## In scope

- 审计 `assets/stata_do_library/do/meta/*.meta.json` 的 `outputs[]` 与依赖声明
- 抽样审计模板源码中对输出的实现方式（例如 `putdocx`, `putpdf`, `export excel`, `outsheet`, `save`)
- 输出格式覆盖面统计与差距分析（按 `csv/xlsx/dta/docx/pdf/log/do`）

## Out of scope

- 不在本卡直接实现输出格式器或新增输出（由 DEPLOY-READY-R031 承接）
- 不在本卡定义 Docker 镜像与 compose

## Dependencies & parallelism

- Depends on: none
- Can run in parallel with: DEPLOY-READY-R001, DEPLOY-READY-R003

## Acceptance checklist

- [x] 输出格式能力矩阵（至少覆盖 csv/dta/docx/pdf/log/do，若存在 xlsx 也需记录）
- [x] 明确 Word/PDF 的可行实现策略与现状差距（优先 `putdocx` / `putpdf`）
- [x] 明确 artifact kind/命名一致性问题，并给出整改建议
- [x] Evidence: `openspec/_ops/task_runs/ISSUE-370.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/385
- Added evidence-backed capability matrix from meta + sampled templates (csv/xlsx/dta/docx/pdf/log/do).
- Documented Word/PDF feasibility/gaps and artifact kind/naming inconsistencies to feed DEPLOY-READY-R031.
- Run log: `openspec/_ops/task_runs/ISSUE-370.md`
