clear all
set more off
version 18
capture log close _all
log using "ss_spset_syntax_probe.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear

gen long sid = _n

capture spset sid

display "spset_plain_rc=" _rc

capture spset sid, coord(x cluster)
display "spset_coord_rc=" _rc

capture spset sid, coords(x cluster)
display "spset_coords_space_rc=" _rc

capture spset sid, coords(x, cluster)
display "spset_coords_comma_rc=" _rc

capture spset sid, coordinates(x cluster)
display "spset_coordinates_rc=" _rc

capture spset sid, coords(x cluster) replace
display "spset_coords_replace_rc=" _rc

capture spset sid, coord(x cluster) replace
display "spset_coord_replace_rc=" _rc

log close
exit 0
