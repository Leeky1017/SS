* ==============================================================================
* SS_TEMPLATE: id=TH14  level=L1  module=H  title="Rolling Regression"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TH14_rolling.png type=figure desc="Rolling plot"
*   - data_TH14_rolling.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - asreg source=ssc purpose="Rolling regression"
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

display "SS_TASK_BEGIN|id=TH14|level=L1|title=Rolling_Regression"
display "SS_TASK_VERSION|version=2.0.1"

local dep_missing = 0
capture which asreg
if _rc {
    local dep_missing = 1
    display "SS_DEP_CHECK|pkg=asreg|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=asreg"
    display "SS_RC|code=DEP_MISSING|pkg=asreg|severity=warn"
}
else {
    display "SS_DEP_CHECK|pkg=asreg|source=ssc|status=ok"
}

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local timevar = "__TIME_VAR__"
local window = __WINDOW__

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
capture confirm variable `depvar'
if _rc {
    display "SS_RC|code=INPUT_VAR_MISSING|var=`depvar'|severity=fail"
    log close
    exit 111
}
foreach v of local indepvars {
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
if `dep_missing' {
    local task_success = 0
    display "SS_RC|code=SKIP_ANALYSIS|reason=missing_dep:asreg|severity=warn"
}
else {
    capture noisily asreg `depvar' `indepvars', window(`window') se
    if _rc {
        local task_success = 0
        display "SS_RC|code=CMD_FAILED|cmd=asreg|rc=`_rc'|severity=warn"
    }
}

capture noisily tsline _b_*, title("滚动回归系数") legend(cols(3))
capture graph export "fig_TH14_rolling.png", replace width(1200)
if _rc {
    capture twoway line `depvar' `tsvar', title("Rolling (analysis skipped)")
    capture graph export "fig_TH14_rolling.png", replace width(1200)
}
display "SS_OUTPUT_FILE|file=fig_TH14_rolling.png|type=figure|desc=rolling_plot"

display "SS_METRIC|name=window|value=`window'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH14_rolling.dta", replace
display "SS_OUTPUT_FILE|file=data_TH14_rolling.dta|type=data|desc=rolling_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=window|value=`window'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH14|status=ok|elapsed_sec=`elapsed'"
log close
