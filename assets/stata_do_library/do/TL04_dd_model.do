* ==============================================================================
* SS_TEMPLATE: id=TL04  level=L1  module=L  title="DD Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL04_dd.csv type=table desc="DD results"
*   - data_TL04_dd.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Dechow-Dichev style accrual quality relies on lead/lag CFO; verify CFO is aligned to the same fiscal period and scaled consistently.
* - Lags/leads require correct `__PANELVAR__`/`__TIME_VAR__`; consider dropping first/last firm-years explicitly if needed.
* - Consider reporting the estimation sample size and checking for extreme scaled values/outliers.
* 最佳实践审查（ZH）:
* - Dechow-Dichev 类应计质量依赖 CFO 的前后期；请确认 CFO 与财务期匹配且缩放口径一致。
* - 滞后/超前项依赖正确的面板/时间设定；必要时可显式剔除每个公司首末期观测。
* - 建议报告回归有效样本量，并检查缩放后变量的极端值/异常值。
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

display "SS_TASK_BEGIN|id=TL04|level=L1|title=DD_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local wca = "__WCA__"
local cfo = "__CFO__"
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
    display "SS_TASK_END|id=TL04|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and numeric types.
* ZH: 校验关键变量存在且为数值型。
local required_vars "`wca' `cfo' `assets' `panelvar' `timevar'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL04|status=fail|elapsed_sec=`elapsed'"
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
        display "SS_TASK_END|id=TL04|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Estimate DD model; accrual quality is |residual| from WCA regression on CFO lead/lag/current.
* ZH: 估计 DD 模型；应计质量指标通常取 WCA 回归残差的绝对值。

capture xtset `panelvar' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset `panelvar' `timevar'|msg=xtset_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

generate wca_scaled = D.`wca' / L.`assets'
generate cfo_lag = L.`cfo' / L.`assets'
generate cfo_cur = `cfo' / L.`assets'
generate cfo_lead = F.`cfo' / L.`assets'

count if !missing(wca_scaled, cfo_lag, cfo_cur, cfo_lead)
local n_reg = r(N)
display "SS_METRIC|name=n_reg|value=`n_reg'"
if `n_reg' < 30 {
    display "SS_RC|code=2001|cmd=count_complete_cases|msg=small_sample_for_regression|severity=warn"
}

capture noisily regress wca_scaled cfo_lag cfo_cur cfo_lead
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress|msg=model_fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture noisily predict residual, residuals
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=predict|msg=predict_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL04|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
generate aq = abs(residual)

summarize aq
local mean_aq = r(mean)
local sd_aq = r(sd)
display "SS_METRIC|name=mean_aq|value=`mean_aq'"
display "SS_METRIC|name=sd_aq|value=`sd_aq'"

preserve
clear
set obs 1
gen str32 model = "DD"
gen double mean_aq = `mean_aq'
gen double sd_aq = `sd_aq'
export delimited using "table_TL04_dd.csv", replace
display "SS_OUTPUT_FILE|file=table_TL04_dd.csv|type=table|desc=dd_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL04_dd.dta", replace
display "SS_OUTPUT_FILE|file=data_TL04_dd.dta|type=data|desc=dd_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_aq|value=`mean_aq'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL04|status=ok|elapsed_sec=`elapsed'"
log close
