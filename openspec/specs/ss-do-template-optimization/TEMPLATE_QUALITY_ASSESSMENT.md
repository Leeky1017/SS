# Template Quality Assessment (Phase 4/5 Planning + Static Pre-scan)

This report answers “what we know now” from static inspection, and defines how Phase 4/5 will produce Stata 18 runtime evidence and best-practice upgrades.

## Current inventory (repo truth)

- Templates (`assets/stata_do_library/do/*.do`): **319**
- Meta (`assets/stata_do_library/do/meta/*.meta.json`): **319**
- Fixtures (`assets/stata_do_library/fixtures/<template_id>/`): **319**

Static gate (do-file lint, contract v1.1):
- Result: **319/319 passed**
- Command:
  - `python3 assets/stata_do_library/DO_LINT_RULES.py --path assets/stata_do_library/do --output /tmp/do_lint_report_current.json`

## Q1) How many templates run on Stata 18 without errors?

Not measured in this environment (no Stata binary available). Phase 4 defines a **full-library batch runner** on Stata 18 that will produce the authoritative number.

What we can already state:
- With static gates, all 319 templates satisfy the current do-file contract checks.
- **58/319** templates declare at least one **SSC** dependency in meta; a “clean” Stata install without those packages will fail those templates unless Phase 4 pre-installs deps.

## Q2) Most common code problems (Top 10, actionable)

Top issues observed via static scans (counts are template counts unless noted):

1. Legacy anchor format still emitted:
   - `SS_TASK_VERSION:<ver>`: **319/319** (colon format; not pipe-delimited)
   - `SS_ERROR:<code>:...` / `SS_ERR:<code>:...`: **306/319**
   - `SS_DEP_MISSING:<pkg>`: **48/319**
   - `SS_WARNING:<code>:...`: **31/319**
2. Mixed `SS_METRIC` formats:
   - legacy `SS_METRIC:<...>` appears in **70/319** (in addition to required `SS_METRIC|name=...`)
3. Dependency surface that can break runtime reproducibility:
   - templates with SSC deps: **58/319**
   - top SSC packages (by template count): `ivreg2`(4), `estout`(4), `psmatch2`(4), `reghdfe`(3), `rdrobust`(3)
4. Meta output-type drift (impacts index/gates downstream):
   - `outputs[].type = "figure"` appears in **35** meta entries (canonical type should be unified, e.g. `graph`)
   - a non-canonical type `manifest` appears in **1** meta entry
5. Meta dependency source drift:
   - `dependencies[].source = "stata"` appears **11** times (should normalize to the canonical enum)

## Q3) Which templates use outdated methods or have better alternatives?

Phase 5 will do a template-by-template best-practice review. High-probability upgrade targets (based on dependency signals + common empirical practice):

- **PSM**: templates relying on `psmatch2` → prefer Stata’s `teffects psmatch` where possible; require overlap diagnostics + balance evidence.
- **IV**: templates using `ivreg2`/`ranktest` → either standardize around built-in `ivregress` + required weak-IV diagnostics, or keep `ivreg2` but enforce consistent first-stage + weak-ID reporting.
- **DID / event study**: de-emphasize TWFE-only defaults; prefer heterogeneity-robust implementations (e.g. `csdid`/`drdid` where available) and require parallel-trend evidence outputs.
- **Output tooling**: templates relying on `estout/esttab` for tables → consider migrating to Stata 18 `collect`/`etable`/`putexcel` for fewer external deps and more consistent formatting.
- **Stepwise selection**: keep only as an explicitly “legacy/teaching” option with warnings; prefer regularization or pre-registered model specs.

## Q4) What important capabilities are missing (new templates needed)?

The library is broad, but Phase 5 should validate gaps against the canonical taxonomy and real-world SS usage. Likely missing/high-value additions:

- **PPML with high-dimensional FE** (gravity/trade/flows): `ppmlhdfe`-style workflow + diagnostics.
- **Modern causal ML / DML** (cross-fitting, nuisance estimation): e.g. `ddml`-style template with strict reproducibility + reporting.
- **Small-cluster inference** (wild bootstrap, randomization inference hooks) for DID/FE settings.
- **Multiple-testing adjustments** (FDR/q-values) for “many outcomes / many treatments” workflows.
- **Robust sensitivity playbooks** packaged as templates (beyond single-method add-ons): parameterized robustness bundles with standardized outputs.

## Q5) Effort estimate (fix + enhance)

Phase 4 (full-library Stata 18 audit):
- Harness + reporting + deterministic fixture wiring: **2–4 days**
- First full run + triage taxonomy: **1–2 days**
- Fixes to reach “0 fail” baseline: **1–3 weeks** (depends on SSC install policy + true runtime error rate)

Phase 5 (content enhancement):
- Best-practice checklist per family + upgrade plan: **3–5 days**
- Upgrade high-impact subset (~top 50 templates): **2–4 weeks**
- Full-library upgrades + new templates: incremental, best handled as a rolling backlog (priority by usage × risk)

## Recommended priorities (Phase 4/5)

- P0: Phase 4 batch runner + “0 fail” baseline on Stata 18 (unblocks everything else).
- P1: Phase 5 upgrades for the highest-usage families (data prep, regression, panel, causal) + migrate common outputs to Stata 18-native tooling where feasible.
- P2: Fill true capability gaps only after the taxonomy is canonical and runtime evidence is stable (avoid adding new surface area before the base is solid).

## Phase 4: Required evidence outputs (definition)

Batch runner MUST produce:
- `template_runs.json` (per-template status, error code/taxonomy, deps, elapsed, outputs)
- `summary.csv` (one row per template, suitable for quick diff/CI artifacts)
- per-template artifacts: rendered do-file, parameter map, Stata log(s), declared outputs

All evidence MUST be linked from `openspec/_ops/task_runs/ISSUE-<N>.md` for the Phase 4 implementation issue.
