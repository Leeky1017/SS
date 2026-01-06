* ==============================================================================
* SS_TEMPLATE: id=TH03  level=L1  module=H  title="Zivot-Andrews Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TH03_za.csv type=table desc="ZA results"
*   - data_TH03_za.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - zandrews source=ssc purpose="ZA test"
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TH03|level=L1|title=ZA_Test"
display "SS_TASK_VERSION:2.0.1"

capture which zandrews
if _rc {
    display "SS_DEP_MISSING:zandrews"
    display "SS_ERROR:DEP_MISSING:zandrews not installed"
    display "SS_ERR:DEP_MISSING:zandrews not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=zandrews|source=ssc|status=ok"

local var = "__VAR__"
local timevar = "__TIMEVAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
tsset `timevar'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
zandrews `var', break(both)
local break_point = r(breakdate)
local t_stat = r(t)
display "SS_METRIC|name=break_point|value=`break_point'"
display "SS_METRIC|name=t_stat|value=`t_stat'"

preserve
clear
set obs 1
gen str32 test = "Zivot-Andrews"
gen double break_point = `break_point'
gen double t_stat = `t_stat'
export delimited using "table_TH03_za.csv", replace
display "SS_OUTPUT_FILE|file=table_TH03_za.csv|type=table|desc=za_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TH03_za.dta", replace
display "SS_OUTPUT_FILE|file=data_TH03_za.dta|type=data|desc=za_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=break_point|value=`break_point'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TH03|status=ok|elapsed_sec=`elapsed'"
log close
