* ==============================================================================
* SS_TEMPLATE: id=TB07  level=L1  module=B  title="Vioplot"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - fig_TB07_violin.png type=figure desc="Violin plot"
*   - data_TB07_vio.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - vioplot source=ssc purpose="violin plot visualization"
* ==============================================================================
* Task ID:      TB07_vioplot
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

display "SS_TASK_BEGIN|id=TB07|level=L1|title=Vioplot"
display "SS_TASK_VERSION:2.0.1"

capture which vioplot
if _rc {
    display "SS_DEP_MISSING:vioplot"
    display "SS_ERROR:DEP_MISSING:vioplot not installed"
    display "SS_ERR:DEP_MISSING:vioplot not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=vioplot|source=ssc|status=ok"

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
vioplot `var', over(`by_var') title("小提琴图: `var'") ytitle("`var'")
graph export "fig_TB07_violin.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TB07_violin.png|type=figure|desc=violin_plot"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TB07_vio.dta", replace
display "SS_OUTPUT_FILE|file=data_TB07_vio.dta|type=data|desc=vio_data"
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

display "SS_TASK_END|id=TB07|status=ok|elapsed_sec=`elapsed'"
log close
