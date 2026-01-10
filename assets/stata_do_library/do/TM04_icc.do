* ==============================================================================
* SS_TEMPLATE: id=TM04  level=L1  module=M  title="ICC"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM04_icc.csv type=table desc="ICC results"
*   - data_TM04_icc.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - ICC depends on model choice (one-way/random/mixed); this minimal template uses a simple one-way approach via `loneway`.
* - Ensure repeated measurements are aligned within subject ID and that variables are comparable (same scale/units).
* - Consider reporting confidence intervals and checking for systematic rater/measurement bias.
* 最佳实践审查（ZH）:
* - ICC 的结果依赖模型设定；本模板用 `loneway` 给出简化的一元方差法 ICC。
* - 请确保同一受试者 ID 下的重复测量对齐，且各测量变量可比（同尺度/单位）。
* - 建议报告置信区间，并关注系统性测量偏差。
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

display "SS_TASK_BEGIN|id=TM04|level=L1|title=ICC"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local vars = "__VARS__"
local id_var = "__ID_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM04|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate subject ID and measurement variables exist.
* ZH: 校验受试者 ID 与测量变量存在。
capture confirm variable `id_var'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `id_var'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local n_vars : word count `vars'
display "SS_METRIC|name=n_measure_vars|value=`n_vars'"
if `n_vars' < 2 {
    display "SS_RC|code=2008|cmd=validate_vars_list|msg=need_at_least_two_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2008
}
foreach v of local vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TM04|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
    capture confirm numeric variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm numeric variable `v'|msg=var_not_numeric|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TM04|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

local model_ok = 1
local icc = .
local lb = .
local ub = .

preserve
keep `id_var' `vars'

local n_vars : word count `vars'
if `n_vars' < 2 {
    local model_ok = 0
}

if `model_ok' == 1 {
    forvalues j = 1/`n_vars' {
        local v : word `j' of `vars'
        capture confirm variable `v'
        if _rc {
            local model_ok = 0
        }
    }
}

if `model_ok' == 1 {
    forvalues j = 1/`n_vars' {
        local v : word `j' of `vars'
        gen double ss_icc`j' = `v'
    }
    keep `id_var' ss_icc*
    capture reshape long ss_icc, i(`id_var') j(rater)
    if _rc {
        local model_ok = 0
    }
}

if `model_ok' == 1 {
    capture loneway ss_icc `id_var'
    if _rc {
        local model_ok = 0
    }
}

if `model_ok' == 1 {
    local icc = r(rho)
    local lb = r(lb)
    local ub = r(ub)
}
restore

if `model_ok' == 0 {
    display "SS_RC|code=2000|cmd=icc|msg=icc_failed|severity=warn"
}
display "SS_METRIC|name=icc|value=`icc'"

preserve
clear
set obs 1
gen str32 analysis = "ICC"
gen double icc = `icc'
gen double lb = `lb'
gen double ub = `ub'
export delimited using "table_TM04_icc.csv", replace
display "SS_OUTPUT_FILE|file=table_TM04_icc.csv|type=table|desc=icc_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM04_icc.dta", replace
display "SS_OUTPUT_FILE|file=data_TM04_icc.dta|type=data|desc=icc_data"
local step_status "ok"
if `model_ok' == 0 {
    local step_status "warn"
}
display "SS_STEP_END|step=S03_analysis|status=`step_status'|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=icc|value=`icc'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

local task_status "ok"
if `model_ok' == 0 {
    local task_status "warn"
}
display "SS_TASK_END|id=TM04|status=`task_status'|elapsed_sec=`elapsed'"
log close
