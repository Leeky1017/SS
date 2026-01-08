* ==============================================================================
* SS_TEMPLATE: id=TC08  level=L0  module=C  title="Trend Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TC08_trend.csv type=table desc="Trend test results"
*   - data_TC08_trend.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="nptrend command"
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.4) ============
* - [x] Validate vars and types (校验变量存在与类型)
* - [x] Missingness summary (缺失值摘要)
* - [x] No SSC dependencies (无需 SSC)
* - [x] Bilingual notes for key steps (关键步骤中英文注释)

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

display "SS_TASK_BEGIN|id=TC08|level=L0|title=Trend_Test"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local var = "__VAR__"
local group_var = "__GROUP_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC08|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TC08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Validate variables / 校验变量
capture confirm variable `var'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `var'|msg=var_not_found:var|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `group_var'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `group_var'|msg=var_not_found:group_var|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `var'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `var'|msg=not_numeric:var|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly count if missing(`var') | missing(`group_var')
local n_missing_total = r(N)
display "SS_METRIC|name=n_missing|value=`n_missing_total'"

capture noisily nptrend `var', by(`group_var')
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=nptrend|msg=test_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local z = r(z)
local p = r(p)

display "SS_METRIC|name=z_stat|value=`z'"
display "SS_METRIC|name=p_value|value=`p'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str30 test = "Trend Test"
gen double z = `z'
gen double p = `p'
export delimited using "table_TC08_trend.csv", replace
display "SS_OUTPUT_FILE|file=table_TC08_trend.csv|type=table|desc=trend_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TC08_trend.dta", replace
display "SS_OUTPUT_FILE|file=data_TC08_trend.dta|type=data|desc=trend_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=z_stat|value=`z'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TC08|status=ok|elapsed_sec=`elapsed'"
log close
