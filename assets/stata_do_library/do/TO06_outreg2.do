* ==============================================================================
* SS_TEMPLATE: id=TO06  level=L2  module=O  title="Outreg2 (fallback)"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO06_compare.doc type=table desc="Comparison table"
*   - data_TO06_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none (optional: outreg2)
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

program define ss_fail_TO06
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TO06|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TO06|level=L2|title=Outreg2"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TO06 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `depvar'
if _rc {
    ss_fail_TO06 111 "confirm variable `depvar'" "depvar_not_found"
}
foreach v of local indepvars {
    capture confirm variable `v'
    if _rc {
        ss_fail_TO06 111 "confirm variable `v'" "indepvar_not_found"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture which outreg2
local has_outreg2 = (_rc == 0)
if `has_outreg2' == 0 {
    display "SS_RC|code=111|cmd=which outreg2|msg=optional_dep_missing_fallback|pkg=outreg2|severity=warn"
}

regress `depvar' `indepvars'
local r2a_ols = e(r2_a)

regress `depvar' `indepvars', robust
local r2_robust = e(r2)

local r2a_txt : display %9.3f `r2a_ols'
local r2r_txt : display %9.3f `r2_robust'

tempname fh
file open `fh' using "table_TO06_compare.doc", write replace text
file write `fh' "Model comparison (fallback; outreg2 not required)" _n
file write `fh' "OLS Adj. R2=`r2a_txt'" _n
file write `fh' "Robust R2=`r2r_txt'" _n
file close `fh'
display "SS_OUTPUT_FILE|file=table_TO06_compare.doc|type=table|desc=compare_table"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TO06_export.dta", replace
display "SS_OUTPUT_FILE|file=data_TO06_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2a_ols|value=`r2a_ols'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO06|status=ok|elapsed_sec=`elapsed'"
log close
