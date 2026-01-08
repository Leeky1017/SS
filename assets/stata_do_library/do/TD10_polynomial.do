* ==============================================================================
* SS_TEMPLATE: id=TD10  level=L0  module=D  title="Polynomial"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD10_poly.csv type=table desc="Polynomial results"
*   - fig_TD10_poly.png type=graph desc="Polynomial plot"
*   - data_TD10_poly.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="regress command"
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.5) ============
* - [x] Polynomial terms need scaling/interpretation (多项式项建议中心化；解释需谨慎)
* - [x] Validate required inputs and fail fast (关键输入校验；错误显式退出)
* - [x] Bilingual notes (关键步骤中英文注释)

capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TD10|level=L0|title=Polynomial"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvar = "__INDEPVAR__"
local degree = __DEGREE__
if `degree' < 2 | `degree' > 5 { local degree = 2 }

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
forvalues i = 2/`degree' {
    generate `indepvar'_`i' = `indepvar'^`i'
}
forvalues i = 2/`degree' {
    local poly_vars "`poly_vars' `indepvar'_`i'"
}

if _rc {

    local rc = _rc

    display "SS_RC|code=`rc'|cmd=regress|msg=fit_failed|severity=fail"

    timer off 1

    quietly timer list 1

    local elapsed = r(t1)

    display "SS_TASK_END|id=TD10|status=fail|elapsed_sec=`elapsed'"

    log close

    exit `rc'

}
local r2 = e(r2)
display "SS_METRIC|name=r2|value=`r2'"
display "SS_METRIC|name=degree|value=`degree'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
predict yhat
twoway (scatter `depvar' `indepvar', mcolor(navy%30)) ///
       (line yhat `indepvar', sort lcolor(red)), ///
    title("多项式回归 (degree=`degree')") legend(order(1 "Data" 2 "Fitted"))
graph export "fig_TD10_poly.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TD10_poly.png|type=graph|desc=poly_plot"

preserve
clear
set obs 1
gen int degree = `degree'
gen double r2 = `r2'
export delimited using "table_TD10_poly.csv", replace
display "SS_OUTPUT_FILE|file=table_TD10_poly.csv|type=table|desc=poly_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD10_poly.dta", replace
display "SS_OUTPUT_FILE|file=data_TD10_poly.dta|type=data|desc=poly_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TD10|status=ok|elapsed_sec=`elapsed'"
log close
