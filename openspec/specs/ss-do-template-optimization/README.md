# SS Do Template Optimization — Strategy

This spec covers the optimization strategy for the vendored do-template library at `assets/stata_do_library/` (319 templates), with the explicit goal of making the library **LLM-selectable, auditable, and maintainable** in SS.

## Executive Answers (核心问题结论)

1. **319 个模板是否都需要保留？哪些应该删除？**  
   不需要以“319 个独立可选模板”的形态全部保留。库本身可作为起点保留，但应当 **合并重复能力、删除冗余实现**，以“一个能力只保留一个主模板”为原则。首批可直接进入“合并/删除队列”的重复项见「Duplicate / Merge Plan」。

2. **分类体系是否需要重新设计？新的分类应该是什么？**  
   需要：当前 `module(A-U)` + `family(32)` 对维护者友好，但对 LLM 检索存在重复与歧义。建议引入 **canonical taxonomy**：  
   - `capability_group`（面向检索的一级能力域，少而稳）  
   - `family`（canonical id + aliases）  
   - `tags/keywords/use_when`（LLM 召回与排序）  
   `module` 可保留为维护分组，但不作为检索主轴。

3. **meta.json 格式是否统一？是否需要标准化？**  
   现状：`do/meta/*.meta.json` 在字段层面较统一，但与 `assets/*` 内 legacy contract/docs、以及 `DO_LIBRARY_INDEX.json` 的部分字段存在漂移。需要 **标准化为“meta 为单一真相”**，并用 JSON Schema + CI 校验保障不再漂移（含 header/meta/anchors 的一致性验证）。

4. **如何设计索引让 LLM 快速锁定模板？**  
   建议采用 **两阶段检索**（family → template）+ token 预算裁剪：  
   - Stage 1：只给 LLM `FamilySummary`（~2K tokens）产出候选 family（含 fallback）  
   - Stage 2：动态加载候选 templates 的 `TemplateSummary`，排序 + topK 裁剪（~3K tokens）后让 LLM 选 `template_id`  
   同时要求：`template_id` 必须属于候选集合，否则结构化失败。

5. **是否需要“模板组合”机制？**  
   需要，但必须做成 **最小、显式、可审计** 的 pipeline：顺序执行、显式输入/输出 wiring、逐步归档 artifacts；不引入隐式状态转移或通用工作流引擎。

## Current State Snapshot (as-is)

Evidence sources:
- `assets/stata_do_library/DO_AUDIT_REPORT.md`
- `assets/stata_do_library/DO_LIBRARY_INDEX.json`
- `assets/stata_do_library/CAPABILITY_MANIFEST.json`
- `openspec/specs/ss-do-template-library/spec.md`

Library inventory:
- Templates: 319 `do/*.do` + 319 `do/meta/*.meta.json`
- Modules: 21 (`A`–`U`)
- Families: 32 in `DO_LIBRARY_INDEX.json` (存在重复/同义，如 `panel` vs `panel_data`)

### Prefix / ID System (T、TA、TB… 的含义)

- `T01`–`T50`：早期“基础集”，ID 本身不编码 module；module 由范围隐式决定（A–J 分段）。
- `TAxx`–`TUxx`：扩展模块集，ID 编码 module（A–U）。
- `module` 的语义来自扩展规划与审计报告（例如：G=因果推断，K=金融专题，L=会计审计等）。

结论：当前“数字段隐式 module + 字母段显式 module”的混合模式不利于人类/LLM 一致理解，需要以 meta/index 的 canonical taxonomy 提供稳定、统一的检索视图。

## Problems & Risks

### 1) Index / Contract Drift（索引与契约漂移）

- `assets/stata_do_library/DO_LIBRARY_INDEX.json` 内部自洽性不足：`tasks.*.audit.verdict` 显示 319 全部 `PROD_READY`，但 `compliance_summary.prod_ready` 仍为 `50`。
- `assets/stata_do_library/README.md` 与 `assets/stata_do_library/SS_DO_CONTRACT.md` 仍使用 legacy `tasks/` 路径叙述，与 SS 中的实际落盘（`assets/stata_do_library/`）不一致。
- `assets/stata_do_library/CAPABILITY_MANIFEST.json` 含硬编码 Windows `ado_path`（需改为可配置/移除）。

### 2) Lint Gate Coverage（门禁覆盖不足）

现有 linter 能做基础安全检查与锚点计数，但对以下问题缺少硬门禁：
- header `OUTPUTS` 的 `type` 枚举漂移（如 `figure` vs `graph`）
- header `DEPENDENCIES: none` 与 meta `dependencies` 不一致
- 锚点格式“存在但不规范”（例如少量模板混入 `SS_METRIC:<...>` 旧格式）

### 3) Retrieval Taxonomy Ambiguity（检索分类歧义）

- family 存在重复/同义（`panel`/`panel_data`, `survival`/`survival_analysis`, `descriptive`/`descriptive_statistics`）
- 占位符命名存在历史变体：`__DEPVAR__` vs `__DEP_VAR__`, `__INDEPVARS__` vs `__INDEP_VARS__`, `__TIME_VAR__` vs `__TIMEVAR__`
- 存在重复能力实现（同一方法在不同 module/family 下重复）

## Optimization Strategy

### A) Make “meta is canonical” the single source of truth

Principle:
- **Do not maintain duplicated truth** across do header, meta, and index by manual edits.
- Treat `do/meta/*.meta.json` as canonical.
- Generate: runtime index + LLM retrieval views from meta (deterministic).

Actions:
- Define `meta` JSON Schema (versioned) and validate in CI.
- Regenerate `DO_LIBRARY_INDEX.json` from meta and make summaries derived (no stale counters).
- Strengthen linter: header/meta/anchors consistency checks become hard gates.

### B) Canonical taxonomy for LLM retrieval

Introduce a stable, SS-owned taxonomy:
- `capability_group`: small set of top-level groups (e.g., data_prep / exploratory / regression / panel / causal / time_series / survival / spatial / domain_finance / domain_accounting / domain_medical / reporting / ml / text / bayesian)
- `family`: canonical id + aliases (no duplicates as canonical)
- `tags`: method + domain + data-shape tags
- `keywords` + `use_when`: maintained text for retrieval and ranking

Implementation note:
- Keep `module` as maintainer grouping; do not force LLM to reason about letters.

### C) LLM index & selection protocol (two-stage)

Outputs (generated):
- `FamilySummary[]` (short, stable; for Stage 1)
- `TemplateSummary[]` (trimmed per candidate set; for Stage 2)

Protocol:
1) Stage 1 picks canonical families (plus fallback families if confidence low).
2) Stage 2 loads candidate templates, ranks, trims to topK within a token budget, and forces the LLM to pick a `template_id` from that set.

Hard rule:
- If LLM outputs a template outside the set → structured error + retry with expanded fallback (bounded).

### D) Duplicate / Merge Plan (first wave)

Policy: “one capability → one canonical template”; duplicates are merged and the redundant ones are deleted from the selectable set.

Known exact-duplicate signals from current meta (by `title_zh`/`slug`):
- LASSO: keep `TS01`, delete `TD07`
- Ridge: keep `TS02`, delete `TD08`
- Elastic Net: keep `TS03`, delete `TD09`
- Spline regression: keep `TU12`, delete `TD11`
- MI Impute: keep `TA03`, delete `TU15`
- VECM: keep `TQ03`, delete `TH10`
- GARCH: keep `TK04`, delete `TH05`
- Fama–MacBeth: keep `TK20`, delete `TF13`
- Group descriptive stats: keep `T02`, delete `TB01`

Rationale (directional):
- Prefer the template that is (a) more complete/diagnostic, (b) has fewer external dependencies, (c) aligns with the future canonical placeholder + output conventions.

### E) Placeholder standardization

Goal: library-wide canonical placeholders (with either strict enforcement or deterministic normalization).

First targets (high frequency variants):
- `__DEPVAR__` (deprecate `__DEP_VAR__`)
- `__INDEPVARS__` (deprecate `__INDEP_VARS__`)
- `__TIME_VAR__` (deprecate `__TIMEVAR__`)

### F) Composition mechanism (minimal pipeline)

Define a pipeline contract:
- A pipeline is an ordered list of template steps.
- Each step declares:
  - `template_id`
  - `params` (resolved deterministically)
  - `input_bindings` (which file feeds which required input role)
  - `output_bindings` (which produced dataset becomes the next step’s primary dataset)

Start small:
- Support only “dataset chaining” first (one primary dataset output per step).
- Defer general DAG/workflow features until proven necessary.

## Rollout Phases

See `openspec/specs/ss-do-template-optimization/task_cards/` for the execution breakdown:
- Phase 0: meta/index/contract alignment + stronger gates
- Phase 1: taxonomy canonicalization + retrieval index
- Phase 2: duplicate merges + placeholder normalization
- Phase 3: composition MVP + evidence harness
- Phase 4: full-library Stata 18 code-quality audit (batch run + fix runtime errors + normalize anchors/style)
- Phase 5: content enhancement (best practices + diagnostics + output polish + capability gap analysis)
