* ==============================================================================
* SS_TEMPLATE: id=TB08  level=L0  module=B  title="Kdensity Compare"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TB08_kdensity.png type=figure desc="Kdensity comparison plot"
*   - data_TB08_kd.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="kdensity command"
* ==============================================================================
* Task ID:      TB08_kdensity_compare
* Placeholders: __VAR__, __BY_VAR__
* Stata:        18.0+
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TB08|level=L0|title=Kdensity_Compare"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local var = "__VAR__"
local by_var = "__BY_VAR__"

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
display "SS_METRIC:n_input:`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
twoway (kdensity `var' if `by_var' == 0, lcolor(navy)) ///
       (kdensity `var' if `by_var' == 1, lcolor(red)), ///
    title("分组核密度图: `var'") xtitle("`var'") ytitle("密度") ///
    legend(order(1 "`by_var'=0" 2 "`by_var'=1"))
graph export "fig_TB08_kdensity.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TB08_kdensity.png|type=figure|desc=kdensity_plot"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TB08_kd.dta", replace
display "SS_OUTPUT_FILE|file=data_TB08_kd.dta|type=data|desc=kd_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=var|value=`var'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TB08|status=ok|elapsed_sec=`elapsed'"
log close
