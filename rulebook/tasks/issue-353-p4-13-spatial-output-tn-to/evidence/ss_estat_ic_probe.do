clear all
set more off
version 18
capture log close _all
log using "ss_estat_ic_probe.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear

gen long sid = _n
spset sid
spset, modify coord(x cluster)
spmatrix create idistance W, normalize(row)
spregress y x treat post, ml dvarlag(W)
estat ic
matrix list r(S)
log close
exit 0
