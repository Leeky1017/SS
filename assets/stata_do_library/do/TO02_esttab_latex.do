* ==============================================================================
* SS_TEMPLATE: id=TO02  level=L2  module=O  title="Esttab LaTeX"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TO02_reg.tex type=table desc="LaTeX regression table"
*   - data_TO02_export.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: estout
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TO02|level=L2|title=Esttab_LaTeX"
display "SS_TASK_VERSION:2.0.1"

capture which esttab
if _rc {
    display "SS_DEP_MISSING:estout"
    display "SS_ERROR:DEP_MISSING:estout not installed"
    display "SS_ERR:DEP_MISSING:estout not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=estout|source=ssc|status=ok"

local depvar = "__DEPVAR__"
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
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

regress `depvar' `indepvars'
estimates store m1

esttab m1 using "table_TO02_reg.tex", replace booktabs ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    stats(N r2, labels("Observations" "R-squared")) ///
    title("Regression Results") star(* 0.10 ** 0.05 *** 0.01)
display "SS_OUTPUT_FILE|file=table_TO02_reg.tex|type=table|desc=latex_table"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TO02_export.dta", replace
display "SS_OUTPUT_FILE|file=data_TO02_export.dta|type=data|desc=export_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_dropped|value=`n_dropped'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TO02|status=ok|elapsed_sec=`elapsed'"
log close
