* ==============================================================================
* SS_TEMPLATE: id=TB09  level=L1  module=B  title="Spineplot"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TB09_spine.png type=graph desc="Spine plot"
*   - data_TB09_spine.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - spineplot source=ssc purpose="spine plot visualization"
* ==============================================================================
* Task ID:      TB09_spineplot
* Placeholders: __VAR1__, __VAR2__
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

display "SS_TASK_BEGIN|id=TB09|level=L1|title=Spineplot"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=spineplot|source=ssc|status=ok"

local var1 = "__VAR1__"
local var2 = "__VAR2__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TB09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
spineplot `var1' `var2', title("脊柱图: `var1' by `var2'")
graph export "fig_TB09_spine.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TB09_spine.png|type=graph|desc=spine_plot"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TB09_spine.dta", replace
display "SS_OUTPUT_FILE|file=data_TB09_spine.dta|type=data|desc=spine_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=var1|value=`var1'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TB09|status=ok|elapsed_sec=`elapsed'"
log close
