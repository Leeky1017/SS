* ==============================================================================
* SS_TEMPLATE: id=TC09  level=L0  module=C  title="Normality Comprehensive"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TC09_norm.csv type=table desc="Normality test results"
*   - data_TC09_norm.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="swilk sfrancia"
* ==============================================================================

* ============ BEST_PRACTICE_REVIEW (Phase 5.4) ============
* - [x] Validate numeric vars (校验数值变量；非数值/缺失变量给出 warn 并跳过)
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

display "SS_TASK_BEGIN|id=TC09|level=L0|title=Normality_Comprehensive"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local vars = "__VARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC09|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TC09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Validate input variables / 校验输入变量
local numeric_vars ""
local n_missing_total = 0
foreach var of local vars {
    capture confirm variable `var'
    if _rc {
        display "SS_RC|code=0|cmd=confirm variable `var'|msg=var_not_found_skipped|severity=warn"
        continue
    }
    capture confirm numeric variable `var'
    if _rc {
        display "SS_RC|code=0|cmd=confirm numeric variable `var'|msg=not_numeric_skipped|severity=warn"
        continue
    }
    local numeric_vars "`numeric_vars' `var'"
    quietly count if missing(`var')
    local n_missing_total = `n_missing_total' + r(N)
}
local n_vars_used : word count `numeric_vars'
if `n_vars_used' <= 0 {
    display "SS_RC|code=198|cmd=confirm numeric variable <vars>|msg=no_valid_numeric_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 198
}
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=n_vars_valid|value=`n_vars_used'"

display ">>> Shapiro-Wilk检验:"
capture noisily swilk `numeric_vars'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=swilk|msg=normality_test_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

display ">>> Shapiro-Francia检验:"
capture noisily sfrancia `numeric_vars'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=sfrancia|msg=normality_test_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
tempname results
postfile `results' str32 variable double sw_w double sw_p double sf_w double sf_p ///
    using "temp_norm.dta", replace

foreach var of local numeric_vars {
    quietly swilk `var'
    local sw_w = r(W)
    local sw_p = r(p)
    quietly sfrancia `var'
    local sf_w = r(W)
    local sf_p = r(p)
    post `results' ("`var'") (`sw_w') (`sw_p') (`sf_w') (`sf_p')
}
postclose `results'

preserve
use "temp_norm.dta", clear
export delimited using "table_TC09_norm.csv", replace
display "SS_OUTPUT_FILE|file=table_TC09_norm.csv|type=table|desc=norm_results"
restore
capture erase "temp_norm.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=erase temp_norm.dta|msg=cleanup_failed|severity=warn"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TC09_norm.dta", replace
display "SS_OUTPUT_FILE|file=data_TC09_norm.dta|type=data|desc=norm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_vars|value=`n_vars_used'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TC09|status=ok|elapsed_sec=`elapsed'"
log close
