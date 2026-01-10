* ==============================================================================
* SS_TEMPLATE: id=TL11  level=L1  module=L  title="Altman ZScore"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL11_zscore.csv type=table desc="Z-Score results"
*   - data_TL11_zscore.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TL11|level=L1|title=Altman_ZScore"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local wc = "__WC__"
local re = "__RE__"
local ebit = "__EBIT__"
local mve = "__MVE__"
local tl = "__TL__"
local sales = "__SALES__"
local ta = "__TA__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
local required_vars "`wc' `re' `ebit' `mve' `tl' `sales' `ta'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL11|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
    capture confirm numeric variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm numeric variable `v'|msg=var_not_numeric|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL11|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

generate x1 = `wc' / `ta'
generate x2 = `re' / `ta'
generate x3 = `ebit' / `ta'
generate x4 = `mve' / `tl'
generate x5 = `sales' / `ta'

generate zscore = 1.2*x1 + 1.4*x2 + 3.3*x3 + 0.6*x4 + 1.0*x5
generate zone = cond(zscore > 2.99, 1, cond(zscore < 1.81, 3, 2))
label define zone_lbl 1 "Safe" 2 "Grey" 3 "Distress"
label values zone zone_lbl

summarize zscore
local mean_zscore = r(mean)
count if zone == 3
local n_distress = r(N)
display "SS_METRIC|name=mean_zscore|value=`mean_zscore'"
display "SS_METRIC|name=n_distress|value=`n_distress'"

preserve
clear
set obs 1
gen str32 model = "Altman Z-Score"
gen double mean_zscore = `mean_zscore'
gen int n_distress = `n_distress'
export delimited using "table_TL11_zscore.csv", replace
display "SS_OUTPUT_FILE|file=table_TL11_zscore.csv|type=table|desc=zscore_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL11_zscore.dta", replace
display "SS_OUTPUT_FILE|file=data_TL11_zscore.dta|type=data|desc=zscore_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_zscore|value=`mean_zscore'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL11|status=ok|elapsed_sec=`elapsed'"
log close
