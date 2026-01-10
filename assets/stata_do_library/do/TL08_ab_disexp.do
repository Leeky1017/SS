* ==============================================================================
* SS_TEMPLATE: id=TL08  level=L1  module=L  title="Ab Disexp"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL08_abdis.csv type=table desc="Abnormal DISEXP results"
*   - data_TL08_abdis.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Abnormal discretionary expense model is usually estimated by industry-year; pooled estimates may reduce comparability.
* - Uses lagged revenue as a scale/driver; confirm revenue definition and timing.
* - Consider winsorizing scaled variables and reporting estimation sample size.
* 最佳实践审查（ZH）:
* - 异常费用模型通常按行业-年份估计；pooled 估计可能降低可比性。
* - 使用滞后收入作为解释变量；请确认收入定义与时期匹配。
* - 建议对缩放后的变量截尾，并报告回归有效样本量。
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

display "SS_TASK_BEGIN|id=TL08|level=L1|title=Ab_Disexp"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local disexp = "__DISEXP__"
local rev = "__REV__"
local assets = "__ASSETS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"

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
    display "SS_TASK_END|id=TL08|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and numeric types.
* ZH: 校验关键变量存在且为数值型。
local required_vars "`disexp' `rev' `assets' `panelvar' `timevar'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL08|status=fail|elapsed_sec=`elapsed'"
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
        display "SS_TASK_END|id=TL08|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Estimate normal discretionary expense model and take residual as abnormal DISEXP.
* ZH: 估计“正常费用”模型并取残差作为异常 DISEXP。

capture xtset `panelvar' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset `panelvar' `timevar'|msg=xtset_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
generate disexp_scaled = `disexp' / L.`assets'
generate inv_assets = 1 / L.`assets'
generate lag_rev = L.`rev' / L.`assets'

count if !missing(disexp_scaled, inv_assets, lag_rev)
local n_reg = r(N)
display "SS_METRIC|name=n_reg|value=`n_reg'"
if `n_reg' < 30 {
    display "SS_RC|code=2001|cmd=count_complete_cases|msg=small_sample_for_regression|severity=warn"
}

capture noisily regress disexp_scaled inv_assets lag_rev
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress|msg=model_fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture noisily predict ab_disexp, residuals
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=predict|msg=predict_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL08|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

summarize ab_disexp
local mean_ab_disexp = r(mean)
display "SS_METRIC|name=mean_ab_disexp|value=`mean_ab_disexp'"

preserve
clear
set obs 1
gen str32 model = "Abnormal DISEXP"
gen double mean = `mean_ab_disexp'
export delimited using "table_TL08_abdis.csv", replace
display "SS_OUTPUT_FILE|file=table_TL08_abdis.csv|type=table|desc=abdis_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL08_abdis.dta", replace
display "SS_OUTPUT_FILE|file=data_TL08_abdis.dta|type=data|desc=abdis_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_ab_disexp|value=`mean_ab_disexp'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL08|status=ok|elapsed_sec=`elapsed'"
log close
