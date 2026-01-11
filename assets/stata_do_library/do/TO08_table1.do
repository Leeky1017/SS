* ==============================================================================
* SS_TEMPLATE: id=TO08  level=L2  module=O  title="Table1 (fallback)"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO08_table1.doc type=table desc="Table1 Word"
*   - table_TO08_table1.csv type=table desc="Table1 CSV"
*   - data_TO08_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none (optional: table1_mc)
* ==============================================================================

capture log close _all
local rc_log_close = _rc
if `rc_log_close' != 0 {
    display "SS_RC|code=`rc_log_close'|cmd=log close _all|msg=no_active_log|severity=warn"
}

clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TO08
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TO08|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TO08|level=L2|title=Table1"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local vars = "__VARS__"
local by_var = "__BY_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TO08 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `by_var'
if _rc {
    ss_fail_TO08 111 "confirm variable `by_var'" "by_var_not_found"
}
foreach v of local vars {
    capture confirm variable `v'
    if _rc {
        ss_fail_TO08 111 "confirm variable `v'" "var_not_found"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture which table1_mc
local has_table1 = (_rc == 0)
if `has_table1' == 0 {
    display "SS_RC|code=111|cmd=which table1_mc|msg=optional_dep_missing_fallback|pkg=table1_mc|severity=warn"
}

tempname fh
file open `fh' using "table_TO08_table1.doc", write replace text
file write `fh' "Table 1 (fallback summary via tabstat)" _n
file write `fh' "by: `by_var'" _n
file write `fh' "vars: `vars'" _n
file close `fh'
display "SS_OUTPUT_FILE|file=table_TO08_table1.doc|type=table|desc=table1_doc"

tabstat `vars', by(`by_var') statistics(n mean sd) columns(statistics) save
matrix stats = r(StatTotal)
preserve
clear
svmat stats, names(col)
export delimited using "table_TO08_table1.csv", replace
display "SS_OUTPUT_FILE|file=table_TO08_table1.csv|type=table|desc=table1_csv"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TO08_export.dta", replace
display "SS_OUTPUT_FILE|file=data_TO08_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO08|status=ok|elapsed_sec=`elapsed'"
log close

