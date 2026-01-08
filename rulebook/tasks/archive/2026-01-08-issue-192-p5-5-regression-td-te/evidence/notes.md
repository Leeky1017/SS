# Notes: issue-192-p5-5-regression-td-te

## Findings
- TD01 can avoid `reghdfe` by using `xtreg, fe` with time fixed effects (`i.__TIME_VAR__`) and clustered SEs.
- TD02 depends on both `reghdfe` and `estout/esttab` (SSC); table export should be replaced with a built-in path.
- TE05 depends on `twopm` (SSC) but can be implemented as an explicit two-part model using base Stata (`logit` + `glm` on positive subsample).
- TE08 depends on `mixlogit` (SSC) and has no base-Stata equivalent; keep SSC dep but improve missing-dep handling and documentation.

## Decisions
- For SSC model commands without base alternatives (e.g., `mixlogit`), keep hard dependency but ensure missing dep fails fast with `SS_RC|code=199|...`.

