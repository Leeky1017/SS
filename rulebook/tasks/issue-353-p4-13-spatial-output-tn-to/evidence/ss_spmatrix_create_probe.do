clear all
set more off
version 18
capture log close _all
log using "ss_spmatrix_create_probe.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear

gen long sid = _n
capture spset sid
display "spset_plain_rc=" _rc
capture spset, modify coord(x cluster)
display "spset_modify_coord_rc=" _rc

capture spmatrix create contiguity Wc, normalize(row)
display "contiguity_rc=" _rc

capture spmatrix create idistance Wi
display "idistance_rc=" _rc

capture spmatrix create idistance Wi, normalize(row)
display "idistance_norm_rc=" _rc

capture spmatrix create knn Wk
display "knn_rc=" _rc

capture spmatrix create knn Wk, k(2)
display "knn_k2_rc=" _rc

capture spmatrix create nearest Wn
display "nearest_rc=" _rc

capture spmatrix create nearest Wn, k(2)
display "nearest_k2_rc=" _rc

log close
exit 0
