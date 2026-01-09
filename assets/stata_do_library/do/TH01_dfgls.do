* ==============================================================================
* SS_TEMPLATE: id=TH01  level=L1  module=H  title="DF-GLS Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH01_dfgls.csv type=table desc="DF-GLS results"
*   - data_TH01_dfgls.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
if _rc != 0 {
    * No log to close - this is expected
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TH01|level=L1|title=DFGLS_Test"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local var = "__VAR__"
local timevar = "__TIME_VAR__"
local maxlag = __MAXLAG__

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=FILE_NOT_FOUND|file=data.csv|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `timevar'
if _rc {
    display "SS_RC|code=INPUT_VAR_MISSING|var=`timevar'|severity=fail"
    log close
    exit 111
}
capture confirm variable `var'
if _rc {
    display "SS_RC|code=INPUT_VAR_MISSING|var=`var'|severity=fail"
    log close
    exit 111
}

local tsvar "`timevar'"
capture isid `timevar'
if _rc {
    sort `timevar'
    gen long ss_time_index = _n
    local tsvar "ss_time_index"
    display "SS_RC|code=TIMEVAR_NOT_UNIQUE|var=`timevar'|severity=warn"
    display "SS_METRIC|name=ts_timevar|value=ss_time_index"
}
capture tsset `tsvar'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local task_success = 1
capture noisily dfgls `var', maxlag(`maxlag')
local opt_lag = .
local t_stat = .
if _rc {
    local task_success = 0
    display "SS_RC|code=CMD_FAILED|cmd=dfgls|rc=`_rc'|severity=warn"
}
else {
    local opt_lag = r(optlag)
    local t_stat = r(t)
}
display "SS_METRIC|name=optimal_lag|value=`opt_lag'"
display "SS_METRIC|name=t_stat|value=`t_stat'"

preserve
clear
set obs 1
gen str32 test = "DF-GLS"
gen int opt_lag = `opt_lag'
gen double t_stat = `t_stat'
export delimited using "table_TH01_dfgls.csv", replace
display "SS_OUTPUT_FILE|file=table_TH01_dfgls.csv|type=table|desc=dfgls_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH01_dfgls.dta", replace
display "SS_OUTPUT_FILE|file=data_TH01_dfgls.dta|type=data|desc=dfgls_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=optimal_lag|value=`opt_lag'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH01|status=ok|elapsed_sec=`elapsed'"
log close
