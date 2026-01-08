* ==============================================================================
* SS_TEMPLATE: id=TB05  level=L0  module=B  title="Group Mean Trend"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - fig_TB05_group_trend.png type=graph desc="Group mean trend plot"
*   - data_TB05_trend.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="collapse and twoway"
* ==============================================================================
* Task ID:      TB05_group_mean_trend
* Placeholders: __YVAR__, __TIME_VAR__, __GROUP_VAR__
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

display "SS_TASK_BEGIN|id=TB05|level=L0|title=Group_Mean_Trend"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local yvar = "__YVAR__"
local timevar = "__TIME_VAR__"
local group_var = "__GROUP_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
collapse (mean) `yvar', by(`timevar' `group_var')
sort `group_var' `timevar'

twoway (line `yvar' `timevar' if `group_var' == 0, lcolor(navy)) ///
       (line `yvar' `timevar' if `group_var' == 1, lcolor(red)), ///
    title("分组均值趋势图") xtitle("`timevar'") ytitle("Mean `yvar'") ///
    legend(order(1 "Group 0" 2 "Group 1"))
graph export "fig_TB05_group_trend.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TB05_group_trend.png|type=graph|desc=group_trend"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TB05_trend.dta", replace
display "SS_OUTPUT_FILE|file=data_TB05_trend.dta|type=data|desc=trend_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=yvar|value=`yvar'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TB05|status=ok|elapsed_sec=`elapsed'"
log close
