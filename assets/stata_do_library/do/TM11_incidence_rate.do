* ==============================================================================
* SS_TEMPLATE: id=TM11  level=L1  module=M  title="Incidence Rate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM11_ir.csv type=table desc="IR results"
*   - data_TM11_ir.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Incidence rate ratios depend on correct person-time denominators; ensure `__PYEARS__` is positive and aligned to cases.
* - Consider overdispersion and alternative models (negative binomial) when counts are variable.
* - Report absolute rates alongside IRR for clinical interpretation.
* 最佳实践审查（ZH）:
* - 发病率比依赖正确的人时分母；请确认 `__PYEARS__` 为正且与病例计数对应。
* - 若过度离散明显，可考虑负二项等替代模型。
* - 建议同时报告绝对发病率以便临床解读。
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

display "SS_TASK_BEGIN|id=TM11|level=L1|title=Incidence_Rate"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local cases = "__CASES__"
local pyears = "__PYEARS__"
local group = "__GROUP__"

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
    display "SS_TASK_END|id=TM11|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables exist and basic constraints hold (pyears > 0).
* ZH: 校验关键变量存在且满足基本约束（人时 > 0）。
local required_vars "`cases' `pyears' `group'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TM11|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
capture confirm numeric variable `cases'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `cases'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `pyears'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `pyears'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
count if !missing(`pyears') & (`pyears' <= 0)
local n_bad_py = r(N)
display "SS_METRIC|name=n_nonpositive_pyears|value=`n_bad_py'"
if `n_bad_py' > 0 {
    display "SS_RC|code=2006|cmd=validate_pyears_positive|msg=nonpositive_pyears_detected|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2006
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* EN: Estimate incidence rate ratio via ir.
* ZH: 使用 ir 估计发病率比。
capture noisily ir `cases' `group' `pyears'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=ir|msg=ir_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local irr = r(irr)
local lb = r(lb_irr)
local ub = r(ub_irr)
display "SS_METRIC|name=incidence_rate_ratio|value=`irr'"

preserve
clear
set obs 1
gen double irr = `irr'
gen double lb = `lb'
gen double ub = `ub'
export delimited using "table_TM11_ir.csv", replace
display "SS_OUTPUT_FILE|file=table_TM11_ir.csv|type=table|desc=ir_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM11_ir.dta", replace
display "SS_OUTPUT_FILE|file=data_TM11_ir.dta|type=data|desc=ir_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=irr|value=`irr'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM11|status=ok|elapsed_sec=`elapsed'"
log close
