* ==============================================================================
* SS_TEMPLATE: id=TC10  level=L0  module=C  title="Variance Homogeneity"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TC10_var.csv type=table desc="Variance test results"
*   - data_TC10_var.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="robvar oneway"
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

display "SS_TASK_BEGIN|id=TC10|level=L0|title=Variance_Homogeneity"
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
    display "SS_TASK_END|id=TC10|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TC10|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TC10|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TC10|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TC10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly count if missing(`var') | missing(`group_var')
local n_missing_total = r(N)
display "SS_METRIC|name=n_missing|value=`n_missing_total'"

display ">>> Levene检验:"
capture noisily robvar `var', by(`group_var')
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=robvar|msg=test_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local levene_f = r(W0)
local levene_p = r(p_W0)

display ">>> Bartlett检验:"
capture noisily oneway `var' `group_var', tabulate
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=oneway|msg=test_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local bartlett_chi2 = r(chi2_b)
local bartlett_p = r(p_b)

display "SS_METRIC|name=levene_f|value=`levene_f'"
display "SS_METRIC|name=bartlett_chi2|value=`bartlett_chi2'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 2
gen str30 test = ""
gen double stat = .
gen double p = .
replace test = "Levene" in 1
replace stat = `levene_f' in 1
replace p = `levene_p' in 1
replace test = "Bartlett" in 2
replace stat = `bartlett_chi2' in 2
replace p = `bartlett_p' in 2
export delimited using "table_TC10_var.csv", replace
display "SS_OUTPUT_FILE|file=table_TC10_var.csv|type=table|desc=var_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TC10_var.dta", replace
display "SS_OUTPUT_FILE|file=data_TC10_var.dta|type=data|desc=var_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=levene_f|value=`levene_f'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TC10|status=ok|elapsed_sec=`elapsed'"
log close
