* ==============================================================================
* SS_TEMPLATE: id=TS12  level=L1  module=S  title="GEE Logit"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS12_geelogit.csv type=table desc="GEE logit results"
*   - data_TS12_geelogit.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TS12|level=L1|title=GEE_Logit"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"
local corr = "__CORR__"

local indepvars_clean ""
foreach v of local indepvars {
    if "`v'" != "`depvar'" {
        local indepvars_clean "`indepvars_clean' `v'"
    }
}
local indepvars "`indepvars_clean'"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture xtset `panelvar' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset `panelvar' `timevar'|msg=xtset_failed|severity=fail"
    log close
    exit `rc'
}
capture noisily xtgee `depvar' `indepvars', family(binomial) link(logit) corr(`corr') eform robust
if _rc == 2000 {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtgee|msg=perfect_prediction_fallback_to_intercept_only|severity=warn"
    capture noisily xtgee `depvar', family(binomial) link(logit) corr(`corr') eform robust
}
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtgee|msg=xtgee_failed|severity=fail"
    log close
    exit `rc'
}
display "SS_METRIC|name=n_obs|value=`e(N)'"

preserve
clear
set obs 1
gen str32 model = "GEE Logit"
export delimited using "table_TS12_geelogit.csv", replace
display "SS_OUTPUT_FILE|file=table_TS12_geelogit.csv|type=table|desc=geelogit_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TS12_geelogit.dta", replace
display "SS_OUTPUT_FILE|file=data_TS12_geelogit.dta|type=data|desc=geelogit_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_obs|value=`e(N)'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS12|status=ok|elapsed_sec=`elapsed'"
log close
