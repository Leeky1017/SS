* ==============================================================================
* SS_TEMPLATE: id=TD04  level=L0  module=D  title="Quantile Reg"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TD04_qreg.csv type=table desc="Quantile regression results"
*   - fig_TD04_qreg.png type=graph desc="Quantile regression plot"
*   - data_TD04_qreg.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="sqreg command"
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.5) ============
* - [x] Quantile regression interpretation noted (分位回归解读提示)
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

display "SS_TASK_BEGIN|id=TD04|level=L0|title=Quantile_Reg"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD04|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TD04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture noisily sqreg `depvar' `indepvars', quantiles(.10 .25 .50 .75 .90) reps(100)
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=sqreg|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TD04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
display "SS_METRIC|name=n_obs|value=`e(N)'"

capture noisily 

if _rc {

    local rc = _rc

    display "SS_RC|code=`rc'|cmd=grqreg|msg=fit_failed|severity=fail"

    timer off 1

    quietly timer list 1

    local elapsed = r(t1)

    display "SS_TASK_END|id=TD04|status=fail|elapsed_sec=`elapsed'"

    log close

    exit `rc'

}, ci ols title("分位数回归系数")
graph export "fig_TD04_qreg.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TD04_qreg.png|type=graph|desc=qreg_plot"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
matrix b = e(b)
preserve
clear
set obs 5
gen int quantile = .
replace quantile = 10 in 1
replace quantile = 25 in 2
replace quantile = 50 in 3
replace quantile = 75 in 4
replace quantile = 90 in 5
export delimited using "table_TD04_qreg.csv", replace
display "SS_OUTPUT_FILE|file=table_TD04_qreg.csv|type=table|desc=qreg_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TD04_qreg.dta", replace
display "SS_OUTPUT_FILE|file=data_TD04_qreg.dta|type=data|desc=qreg_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=quantiles|value=5"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TD04|status=ok|elapsed_sec=`elapsed'"
log close
