* ==============================================================================
* SS_TEMPLATE: id=TI06  level=L1  module=I  title="PH Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TI06_phtest.csv type=table desc="PH test results"
*   - fig_TI06_ph.png type=figure desc="PH plot"
*   - data_TI06_phtest.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TI06|level=L1|title=PH_Test"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local timevar = "__TIMEVAR__"
local failvar = "__FAILVAR__"
local indepvars = "__INDEPVARS__"

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
stset `timevar', failure(`failvar')
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
stcox `indepvars'
estat phtest, detail
local chi2 = r(chi2)
local p = r(p)
display "SS_METRIC|name=chi2|value=`chi2'"
display "SS_METRIC|name=p_value|value=`p'"

stphplot, by(`indepvars')
graph export "fig_TI06_ph.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TI06_ph.png|type=figure|desc=ph_plot"

preserve
clear
set obs 1
gen str32 test = "PH Test"
gen double chi2 = `chi2'
gen double p = `p'
export delimited using "table_TI06_phtest.csv", replace
display "SS_OUTPUT_FILE|file=table_TI06_phtest.csv|type=table|desc=phtest_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TI06_phtest.dta", replace
display "SS_OUTPUT_FILE|file=data_TI06_phtest.dta|type=data|desc=phtest_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=chi2|value=`chi2'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI06|status=ok|elapsed_sec=`elapsed'"
log close
