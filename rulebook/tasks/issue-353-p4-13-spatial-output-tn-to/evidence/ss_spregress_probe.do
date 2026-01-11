clear all
set more off
version 18
capture log close _all
log using "ss_spregress_probe.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear

gen long sid = _n
capture spset sid
capture spset, modify coord(x cluster)

capture spmatrix create idistance W
display "create_idistance_rc=" _rc

capture spregress y x treat post, ml dvarlag(W)
display "spregress_rc=" _rc

log close
exit 0
