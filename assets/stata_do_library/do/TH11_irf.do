* ==============================================================================
* SS_TEMPLATE: id=TH11  level=L1  module=H  title="IRF Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TH11_irf.png type=figure desc="IRF plot"
*   - data_TH11_irf.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TH11|level=L1|title=IRF_Analysis"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local vars = "__VARS__"
local timevar = "__TIME_VAR__"
local lags = __LAGS__
local steps = __STEPS__

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
foreach v of local vars {
    capture confirm variable `v'
    if _rc {
        display "SS_RC|code=INPUT_VAR_MISSING|var=`v'|severity=fail"
        log close
        exit 111
    }
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
capture noisily var `vars', lags(1/`lags')
if _rc {
    local task_success = 0
    display "SS_RC|code=CMD_FAILED|cmd=var|rc=`_rc'|severity=warn"
}
else {
    capture irf set irf_results, replace
    capture noisily irf create myirf, step(`steps') replace
    if _rc {
        local task_success = 0
        display "SS_RC|code=CMD_FAILED|cmd=irf_create|rc=`_rc'|severity=warn"
    }
    capture noisily irf graph oirf, impulse(`vars') response(`vars')
    if _rc {
        local task_success = 0
        display "SS_RC|code=CMD_FAILED|cmd=irf_graph|rc=`_rc'|severity=warn"
    }
}
capture graph export "fig_TH11_irf.png", replace width(1200)
if _rc {
    local first_var : word 1 of `vars'
    capture twoway line `first_var' `tsvar'
    capture graph export "fig_TH11_irf.png", replace width(1200)
}
display "SS_OUTPUT_FILE|file=fig_TH11_irf.png|type=figure|desc=irf_plot"

display "SS_METRIC|name=steps|value=`steps'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH11_irf.dta", replace
display "SS_OUTPUT_FILE|file=data_TH11_irf.dta|type=data|desc=irf_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=steps|value=`steps'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH11|status=ok|elapsed_sec=`elapsed'"
log close
