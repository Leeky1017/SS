# Stata SSC dependencies (template library)

This is the canonical list of Stata SSC packages required by templates in `assets/stata_do_library/`.

## Install (remote/server)

Run in Stata (once per machine/user profile), then re-run smoke-suite:

```stata
ssc install <pkg>, replace
```

Notes:
- Templates MUST NOT auto-install SSC packages (no network side effects at runtime).
- When an SSC dependency is missing, templates should fail fast with `SS_DEP_MISSING|pkg=<pkg>` (and optionally an install hint).

## Package list

| SSC pkg | Templates | Purpose | Install |
| --- | --- | --- | --- |
| `asdoc` | `TO05` | Word export | `ssc install asdoc, replace` |
| `cem` | `TG05` | Coarsened exact matching | `ssc install cem, replace` |
| `csdid` | `TG20` | Staggered DID | `ssc install csdid, replace` |
| `drdid` | `TG20` | DR DID | `ssc install drdid, replace` |
| `estout` | `TO01`, `TO02`, `TO03` | Table export | `ssc install estout, replace` |
| `kpss` | `TH02` | KPSS test | `ssc install kpss, replace` |
| `mixlogit` | `TE08` | mixed logit model | `ssc install mixlogit, replace` |
| `mtefe` | `TG25` | MTE estimation | `ssc install mtefe, replace` |
| `outreg2` | `TO06` | Table export | `ssc install outreg2, replace` |
| `pvar` | `TF14` | Panel VAR | `ssc install pvar, replace` |
| `rbounds` | `TG08` | Rosenbaum bounds | `ssc install rbounds, replace` |
| `rddensity` | `TG12` | RDD density test | `ssc install rddensity, replace` |
| `rdrobust` | `TG09`, `TG10`, `TG11` | RDD bandwidth; RDD estimation | `ssc install rdrobust, replace` |
| `reghdfe` | `TD02` | high-dimensional fixed effects | `ssc install reghdfe, replace` |
| `spatdiag` | `TN10` | Spatial diagnostics | `ssc install spatdiag, replace` |
| `spatwmat` | `TN02` | Spatial tests | `ssc install spatwmat, replace` |
| `synth` | `TG17`, `TG18` | Synthetic control | `ssc install synth, replace` |
| `table1_mc` | `TO08` | Table 1 creation | `ssc install table1_mc, replace` |
| `xsmle` | `TN08` | Spatial panel | `ssc install xsmle, replace` |
| `xtabond2` | `TF05`, `TP03` | System GMM; System GMM estimation | `ssc install xtabond2, replace` |
| `xtcointtest` | `TP10` | Panel cointegration | `ssc install xtcointtest, replace` |
| `xthreg` | `TF07` | Panel threshold model | `ssc install xthreg, replace` |
| `xtserial` | `TF03`, `TP05` | Wooldridge test | `ssc install xtserial, replace` |
| `xttest3` | `TP06` | Modified Wald test | `ssc install xttest3, replace` |
| `zandrews` | `TH03` | ZA test | `ssc install zandrews, replace` |
