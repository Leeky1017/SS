clear all
set more off
version 18
capture log close _all
log using "ss_spset_modify_probe.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear

gen long sid = _n
capture spset sid
display "spset_plain_rc=" _rc

capture spset, modify coords(x cluster)
display "spset_modify_coords_rc=" _rc

capture spset, modify coordinates(x cluster)
display "spset_modify_coordinates_rc=" _rc

capture spset, modify coord(x cluster)
display "spset_modify_coord_rc=" _rc

capture spset, modify xcoord(x) ycoord(cluster)
display "spset_modify_xy_rc=" _rc

capture spset, describe
display "spset_describe_rc=" _rc

capture spmatrix create contiguity W, normalize(row)
display "spmatrix_contiguity_rc=" _rc

log close
exit 0
