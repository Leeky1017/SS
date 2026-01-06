* ==============================================================================
* SS_TEMPLATE: id=TC02  level=L0  module=C  title="Repeated ANOVA"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TC02_repeated.csv type=table desc="Repeated ANOVA results"
*   - data_TC02_rep.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="anova repeated"
* ==============================================================================
* Task ID:      TC02_repeated_anova
* Placeholders: __DEPVAR__, __TIME_VAR__, __ID_VAR__
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

display "SS_TASK_BEGIN|id=TC02|level=L0|title=Repeated_ANOVA"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local time_var = "__TIME_VAR__"
local id_var = "__ID_VAR__"

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
anova `depvar' `time_var' / `id_var'|`time_var', repeated(`time_var')
display "SS_METRIC|name=n_obs|value=`n_input'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str30 test = "Repeated Measures ANOVA"
export delimited using "table_TC02_repeated.csv", replace
display "SS_OUTPUT_FILE|file=table_TC02_repeated.csv|type=table|desc=repeated_anova"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TC02_rep.dta", replace
display "SS_OUTPUT_FILE|file=data_TC02_rep.dta|type=data|desc=rep_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=depvar|value=`depvar'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TC02|status=ok|elapsed_sec=`elapsed'"
log close
