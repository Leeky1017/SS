clear all
set more off
version 18
capture log close _all
log using "ss_spgenerate_probe.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear

gen long sid = _n
spset sid
spset, modify coord(x cluster)
spmatrix create idistance W

capture spgenerate Wy = W*y
display "spgenerate_rc=" _rc

capture corr y Wy
display "corr_rc=" _rc

log close
exit 0
