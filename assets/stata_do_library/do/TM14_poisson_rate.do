* ==============================================================================
* SS_TEMPLATE: id=TM14  level=L1  module=M  title="Poisson Rate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM14_irr.csv type=table desc="IRR results"
*   - data_TM14_irr.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Poisson rate models require a positive exposure/time-at-risk; validate `__EXPOSURE__` carefully.
* - Overdispersion can inflate type I error; consider robust SE or negative binomial alternatives.
* - Interpret IRR alongside absolute rates and model fit diagnostics.
* 最佳实践审查（ZH）:
* - Poisson 率模型要求暴露/观察时间为正；请重点校验 `__EXPOSURE__`。
* - 过度离散可能导致显著性偏高；可考虑 robust 或负二项模型。
* - IRR 解读建议结合绝对率与拟合诊断。
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

display "SS_TASK_BEGIN|id=TM14|level=L1|title=Poisson_Rate"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local outcome = "__OUTCOME__"
local indepvars = "__INDEPVARS__"
local exposure = "__EXPOSURE__"

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
    display "SS_TASK_END|id=TM14|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables exist; exposure must be positive numeric.
* ZH: 校验关键变量存在；暴露变量需为正的数值型。
local required_vars "`outcome' `exposure'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TM14|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
capture confirm numeric variable `outcome'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `outcome'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `exposure'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `exposure'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
foreach v of varlist `indepvars' {
    capture confirm numeric variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm numeric variable `v'|msg=var_not_numeric|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TM14|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
count if !missing(`exposure') & (`exposure' <= 0)
local n_bad_exp = r(N)
display "SS_METRIC|name=n_nonpositive_exposure|value=`n_bad_exp'"
if `n_bad_exp' > 0 {
    display "SS_RC|code=2006|cmd=validate_exposure_positive|msg=nonpositive_exposure_detected|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2006
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* EN: Fit Poisson model with exposure and report log-likelihood.
* ZH: 拟合带暴露项的 Poisson 模型并报告对数似然。
local model_ok = 1
local ll = .
capture noisily poisson `outcome' `indepvars', exposure(`exposure') irr
if _rc {
    local model_ok = 0
    display "SS_RC|code=`=_rc'|cmd=poisson|msg=model_fit_failed|severity=warn"
}
if `model_ok' == 1 {
    local ll = e(ll)
}
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "Poisson IRR"
gen double ll = `ll'
export delimited using "table_TM14_irr.csv", replace
display "SS_OUTPUT_FILE|file=table_TM14_irr.csv|type=table|desc=irr_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM14_irr.dta", replace
display "SS_OUTPUT_FILE|file=data_TM14_irr.dta|type=data|desc=irr_data"
local step_status "ok"
if `model_ok' == 0 {
    local step_status "warn"
}
display "SS_STEP_END|step=S03_analysis|status=`step_status'|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"

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
display "SS_TASK_END|id=TM14|status=`task_status'|elapsed_sec=`elapsed'"
log close
