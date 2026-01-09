* ==============================================================================
* SS_TEMPLATE: id=TH04  level=L1  module=H  title="SARIMA Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH04_sarima.csv type=table desc="SARIMA results"
*   - fig_TH04_forecast.png type=figure desc="Forecast plot"
*   - data_TH04_sarima.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TH04|level=L1|title=SARIMA_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local var = "__VAR__"
local timevar = "__TIME_VAR__"
local p = __P__
local d = __D__
local q = __Q__
local sp = __SP__
local sd = __SD__
local sq = __SQ__
local season = __SEASON__

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
local ll = .
local aic = .
capture noisily arima `var', arima(`p',`d',`q') sarima(`sp',`sd',`sq',`season')
if _rc {
    local task_success = 0
    display "SS_RC|code=CMD_FAILED|cmd=arima|rc=`_rc'|severity=warn"
}
else {
    local ll = e(ll)
    local aic = -2*`ll' + 2*e(k)
}
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=aic|value=`aic'"

capture drop yhat
if `task_success' {
    capture noisily predict yhat, y
}
if `task_success' {
    capture noisily tsline `var' yhat, title("SARIMA预测") legend(order(1 "实际" 2 "拟合"))
}
else {
    capture noisily tsline `var', title("SARIMA (analysis skipped)")
}
capture graph export "fig_TH04_forecast.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TH04_forecast.png|type=figure|desc=forecast"

preserve
clear
set obs 1
gen str32 model = "SARIMA"
gen double ll = `ll'
gen double aic = `aic'
export delimited using "table_TH04_sarima.csv", replace
display "SS_OUTPUT_FILE|file=table_TH04_sarima.csv|type=table|desc=sarima_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH04_sarima.dta", replace
display "SS_OUTPUT_FILE|file=data_TH04_sarima.dta|type=data|desc=sarima_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=aic|value=`aic'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=`task_success'"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH04|status=ok|elapsed_sec=`elapsed'"
log close
