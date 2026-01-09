# TG01–TG25 Audit (Issue #258)

## Scope

- Templates: `assets/stata_do_library/do/TG01_*.do` … `TG25_*.do`
- Goal: best practices + stronger diagnostics/error signaling + bilingual comments, while minimizing SSC dependencies (Stata 18-native first).

## SSC dependency decisions (replace where feasible)

| Template | Current SSC deps | Decision | Rationale |
|---|---|---|---|
| TG01–TG02, TG06–TG07 | `psmatch2` | Replace → Stata built-in `teffects`/`tebalance` | Prefer Stata 18-native PSM and built-in balance/overlap diagnostics (`tebalance`, `teoverlap`, `osample()`). |
| TG13–TG15, TG24 | `ivreg2` (+ TG14 `ranktest`) | Replace → Stata built-in `ivregress 2sls` | Keep weak-ID signals via excluded-instruments joint tests and postestimation (`estat overid/endogenous/firststage` when applicable). |
| TG16 | `xtivreg2` | Replace → Stata built-in `xtivreg` | Panel IV can be done with built-in FE/RE/FD IV estimators. |
| TG23 | `reghdfe`, `did_multiplegt` | Replace default → built-in `xtreg`/`regress` with FE dummies | Avoid requiring SSC for TWFE baseline; robust staggered DID is covered by TG20 (`csdid`/`drdid`). |
| TG05 | `cem` | Keep (explicitly) | No Stata-native CEM; keep with explicit install + limitations note. |
| TG08 | `rbounds` | Keep (explicitly) | Sensitivity analysis requires SSC; keep with explicit install + interpretation notes. |
| TG09–TG11 | `rdrobust` | Keep (explicitly) | RDD best-practice tooling is SSC; keep and strengthen bandwidth + robustness messaging. |
| TG12 | `rddensity` | Keep (explicitly) | Density test is SSC; keep with explicit install + interpretation notes. |
| TG17–TG18 | `synth` | Keep (explicitly) | SCM best-practice tooling is SSC; keep with explicit install + placebo guidance. |
| TG20 | `csdid`, `drdid` | Keep (explicitly) | Stata built-ins lack full heterogeneity-robust staggered DID; keep with explicit install + parallel-trends checks. |
| TG25 | `mtefe` | Keep (explicitly) | MTE requires SSC; keep with explicit install + interpretation notes. |

