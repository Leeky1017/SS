clear all
set more off
version 18
capture log close _all
log using "ss_file_write_format_probe.result.log", text replace
import delimited "/home/leeky/work/SS/.worktrees/issue-353-p4-13-spatial-output-tn-to/assets/stata_do_library/fixtures/TN03/sample_data.csv", clear
regress y x treat post, robust
local indepvars "x treat post"
tempname fh
file open `fh' using "ss_file_write_format_probe.out.txt", write replace text
foreach v of local indepvars {
    file write `fh' "`v' & " %9.3f _b[`v'] " & " %9.3f _se[`v'] " \\ " _n
}
file close `fh'
log close
exit 0
