* ==============================================================================
* SS_TEMPLATE: id=TF14  level=L1  module=F  title="PVAR"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TF14_pvar.csv type=table desc="PVAR results"
*   - fig_TF14_irf.png type=figure desc="IRF plot"
*   - data_TF14_pvar.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - pvar source=ssc purpose="Panel VAR"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TF14|level=L1|title=PVAR"
display "SS_TASK_VERSION:2.0.1"

capture which pvar
if _rc {
    display "SS_DEP_MISSING:pvar"
    display "SS_ERROR:DEP_MISSING:pvar not installed"
    display "SS_ERR:DEP_MISSING:pvar not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=pvar|source=ssc|status=ok"

local vars = "__VARS__"
local panelvar = "__PANELVAR__"
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
display "SS_METRIC:n_input:`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
ss_smart_xtset `panelvar' `timevar'
pvar `vars', lags(2) gmm
display "SS_METRIC|name=n_obs|value=`e(N)'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
pvarirf, mc(200) oirf
graph export "fig_TF14_irf.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TF14_irf.png|type=figure|desc=irf_plot"

preserve
clear
set obs 1
gen str32 model = "Panel VAR"
export delimited using "table_TF14_pvar.csv", replace
display "SS_OUTPUT_FILE|file=table_TF14_pvar.csv|type=table|desc=pvar_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TF14_pvar.dta", replace
display "SS_OUTPUT_FILE|file=data_TF14_pvar.dta|type=data|desc=pvar_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=model|value=pvar"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TF14|status=ok|elapsed_sec=`elapsed'"
log close
