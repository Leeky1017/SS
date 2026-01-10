* ==============================================================================
* SS_TEMPLATE: id=TL07  level=L1  module=L  title="Ab Prod"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL07_abprod.csv type=table desc="Abnormal PROD results"
*   - data_TL07_abprod.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Abnormal production cost model is usually estimated by industry-year; pooled estimates may mix heterogeneous cost structures.
* - Includes revenue change and lagged revenue change; ensure `__REV__` timing matches `__PROD__` definitions.
* - Consider winsorizing scaled variables and reporting estimation sample size.
* 最佳实践审查（ZH）:
* - 异常生产成本模型通常按行业-年份估计；pooled 估计可能混合异质成本结构。
* - 模型包含收入变动及其滞后；请确保 `__REV__` 与 `__PROD__` 的定义与时期匹配。
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

display "SS_TASK_BEGIN|id=TL07|level=L1|title=Ab_Prod"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local prod = "__PROD__"
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
    display "SS_TASK_END|id=TL07|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and numeric types.
* ZH: 校验关键变量存在且为数值型。
local required_vars "`prod' `rev' `assets' `panelvar' `timevar'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL07|status=fail|elapsed_sec=`elapsed'"
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
        display "SS_TASK_END|id=TL07|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Estimate normal production cost model and take residual as abnormal PROD.
* ZH: 估计“正常生产成本”模型并取残差作为异常 PROD。

capture xtset `panelvar' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset `panelvar' `timevar'|msg=xtset_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
generate prod_scaled = `prod' / L.`assets'
generate inv_assets = 1 / L.`assets'
generate rev_scaled = `rev' / L.`assets'
generate delta_rev = D.`rev' / L.`assets'
generate lag_delta_rev = L.delta_rev

count if !missing(prod_scaled, inv_assets, rev_scaled, delta_rev, lag_delta_rev)
local n_reg = r(N)
display "SS_METRIC|name=n_reg|value=`n_reg'"
if `n_reg' < 30 {
    display "SS_RC|code=2001|cmd=count_complete_cases|msg=small_sample_for_regression|severity=warn"
}

capture noisily regress prod_scaled inv_assets rev_scaled delta_rev lag_delta_rev
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress|msg=model_fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture noisily predict ab_prod, residuals
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=predict|msg=predict_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL07|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

summarize ab_prod
local mean_ab_prod = r(mean)
display "SS_METRIC|name=mean_ab_prod|value=`mean_ab_prod'"

preserve
clear
set obs 1
gen str32 model = "Abnormal PROD"
gen double mean = `mean_ab_prod'
export delimited using "table_TL07_abprod.csv", replace
display "SS_OUTPUT_FILE|file=table_TL07_abprod.csv|type=table|desc=abprod_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL07_abprod.dta", replace
display "SS_OUTPUT_FILE|file=data_TL07_abprod.dta|type=data|desc=abprod_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_ab_prod|value=`mean_ab_prod'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL07|status=ok|elapsed_sec=`elapsed'"
log close
