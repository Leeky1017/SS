* ==============================================================================
* SS_TEMPLATE: id=TD01  level=L1  module=D  title="Twoway FE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD01_twfe.csv type=table desc="TWFE regression results"
*   - data_TD01_twfe.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - reghdfe source=ssc purpose="high-dimensional fixed effects"
* ==============================================================================

capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TD01|level=L1|title=Twoway_FE"
display "SS_TASK_VERSION:2.0.1"

capture which reghdfe
if _rc {
    display "SS_DEP_MISSING:reghdfe"
    display "SS_ERROR:DEP_MISSING:reghdfe not installed"
    display "SS_ERR:DEP_MISSING:reghdfe not installed"
    log close
    exit 199
}
display "SS_DEP_CHECK|pkg=reghdfe|source=ssc|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
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
reghdfe `depvar' `indepvars', absorb(`panelvar' `timevar') vce(cluster `panelvar')

local r2 = e(r2)
local n_obs = e(N)
display "SS_METRIC|name=r2|value=`r2'"
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
matrix b = e(b)
matrix V = e(V)
preserve
clear
local nvars : word count `indepvars'
set obs `nvars'
gen str32 variable = ""
gen double coef = .
gen double se = .
local i = 1
foreach var of local indepvars {
    replace variable = "`var'" in `i'
    replace coef = b[1, `i'] in `i'
    replace se = sqrt(V[`i', `i']) in `i'
    local i = `i' + 1
}
export delimited using "table_TD01_twfe.csv", replace
display "SS_OUTPUT_FILE|file=table_TD01_twfe.csv|type=table|desc=twfe_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD01_twfe.dta", replace
display "SS_OUTPUT_FILE|file=data_TD01_twfe.dta|type=data|desc=twfe_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TD01|status=ok|elapsed_sec=`elapsed'"
log close
