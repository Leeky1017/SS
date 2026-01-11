clear all
set more off
version 18
capture log close _all
log using "ss_idistance_norm_probe.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear

gen long sid = _n
spset sid
spset, modify coord(x cluster)

capture spmatrix create idistance W1, normalize(row)
display "normalize_row_rc=" _rc

capture spmatrix create idistance W2, norm(row)
display "norm_row_rc=" _rc

capture spmatrix create idistance W3, normalization(row)
display "normalization_row_rc=" _rc

capture spmatrix create idistance W4, rowstandardize
display "rowstandardize_rc=" _rc

capture spmatrix create idistance W5, standardize(row)
display "standardize_row_rc=" _rc

log close
exit 0
