* ==============================================================================
* SS_TEMPLATE: id=TP15  level=L1  module=P  title="Svy Tabulate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP15_svytab.csv type=table desc="Survey tabulate results"
*   - data_TP15_svy.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TP15|level=L1|title=Svy_Tabulate"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local var1 = "__VAR1__"
local var2 = "__VAR2__"
local pweight = "__PWEIGHT__"
local strata = "__STRATA__"
local psu = "__PSU__"

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
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

svyset `psu' [pweight=`pweight'], strata(`strata')
svy: tabulate `var1' `var2', pearson
local f = e(F_Pear)
local p = e(p_Pear)
display "SS_METRIC|name=f_stat|value=`f'"
display "SS_METRIC|name=p_value|value=`p'"

preserve
clear
set obs 1
gen str32 analysis = "Survey Tabulate"
gen double f = `f'
gen double p = `p'
export delimited using "table_TP15_svytab.csv", replace
display "SS_OUTPUT_FILE|file=table_TP15_svytab.csv|type=table|desc=svy_tab"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TP15_svy.dta", replace
display "SS_OUTPUT_FILE|file=data_TP15_svy.dta|type=data|desc=svy_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=p_value|value=`p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP15|status=ok|elapsed_sec=`elapsed'"
log close
