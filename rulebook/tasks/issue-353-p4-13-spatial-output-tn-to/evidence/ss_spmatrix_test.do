clear all
set more off
version 18
capture log close _all
log using "ss_spmatrix_test.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear

gen long sid = _n
capture spset sid, coords(x cluster)
display "spset_rc=" _rc
capture spmatrix create contiguity W, normalize(row)
display "spmatrix_rc=" _rc
capture spmatrix summarize W
if _rc {
    display "spmatrix_summarize_rc=" _rc
}
log close
exit 0
