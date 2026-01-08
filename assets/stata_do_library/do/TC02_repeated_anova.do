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

* ============ BEST_PRACTICE_REVIEW (Phase 5.4) ============
* - [x] Validate vars and types (校验变量存在与类型)
* - [x] Missingness summary (缺失值摘要)
* - [x] No SSC dependencies (无需 SSC)
* - [x] Bilingual notes for key steps (关键步骤中英文注释)
* - 2026-01-08: Export a minimal, machine-readable summary table (导出最小可解析汇总表)

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

display "SS_TASK_BEGIN|id=TC02|level=L0|title=Repeated_ANOVA"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local depvar = "__DEPVAR__"
local time_var = "__TIME_VAR__"
local id_var = "__ID_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC02|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TC02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Validate variables / 校验变量
capture confirm variable `depvar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `depvar'|msg=var_not_found:depvar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `depvar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `depvar'|msg=not_numeric:depvar|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `time_var'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `time_var'|msg=var_not_found:time_var|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `id_var'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `id_var'|msg=var_not_found:id_var|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly count if missing(`depvar') | missing(`time_var') | missing(`id_var')
local n_missing_total = r(N)
display "SS_METRIC|name=n_missing|value=`n_missing_total'"

capture noisily anova `depvar' `time_var' / `id_var'|`time_var', repeated(`time_var')
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=anova repeated|msg=fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TC02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

local f_stat = .
local df_m = .
local df_r = .
local p_value = .
capture local f_stat = e(F)
capture local df_m = e(df_m)
capture local df_r = e(df_r)
if ("`f_stat'" != ".") & ("`df_m'" != ".") & ("`df_r'" != ".") {
    local p_value = Ftail(`df_m', `df_r', `f_stat')
}
display "SS_METRIC|name=n_obs|value=`n_input'"
display "SS_METRIC|name=f_stat|value=`f_stat'"
display "SS_METRIC|name=p_value|value=`p_value'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str30 test = "Repeated Measures ANOVA"
gen double f_stat = `f_stat'
gen double p_value = `p_value'
gen double df_m = `df_m'
gen double df_r = `df_r'
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
display "SS_METRIC|name=n_missing|value=`n_missing_total'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TC02|status=ok|elapsed_sec=`elapsed'"
log close
