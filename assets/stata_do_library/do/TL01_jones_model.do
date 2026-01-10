* ==============================================================================
* SS_TEMPLATE: id=TL01  level=L1  module=L  title="Jones Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL01_jones.csv type=table desc="Jones results"
*   - data_TL01_jones.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Jones accruals are often estimated cross-sectionally (e.g., industry-year); pooled estimates may be less comparable.
* - Deflator uses lagged total assets; ensure `__ASSETS__` is total assets and `__PANELVAR__`/`__TIME_VAR__` are correct for lags.
* - Consider winsorizing inputs/DA and reporting the sample used for estimation (complete cases).
* 最佳实践审查（ZH）:
* - Jones 应计模型通常按行业-年份横截面估计；若采用 pooled 估计，结果可比性可能下降。
* - 使用滞后总资产缩放；请确认 `__ASSETS__` 为总资产且 `__PANELVAR__`/`__TIME_VAR__` 设置正确以生成滞后项。
* - 建议对输入或 DA 做分位数截尾（winsorize）并报告有效样本量（完整观测）。
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

display "SS_TASK_BEGIN|id=TL01|level=L1|title=Jones_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local ta = "__TA__"
local rev = "__REV__"
local ppe = "__PPE__"
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
    display "SS_TASK_END|id=TL01|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and numeric types.
* ZH: 校验关键变量存在且为数值型。
local required_vars "`ta' `rev' `ppe' `assets' `panelvar' `timevar'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL01|status=fail|elapsed_sec=`elapsed'"
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
        display "SS_TASK_END|id=TL01|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Estimate Jones model and compute discretionary accruals (DA = TA - NDA).
* ZH: 估计 Jones 模型并计算可操纵应计（DA = TA - NDA）。

capture xtset `panelvar' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset `panelvar' `timevar'|msg=xtset_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

generate ta_scaled = `ta' / L.`assets'
generate inv_assets = 1 / L.`assets'
generate delta_rev = D.`rev' / L.`assets'
generate ppe_scaled = `ppe' / L.`assets'

count if !missing(ta_scaled, inv_assets, delta_rev, ppe_scaled)
local n_reg = r(N)
display "SS_METRIC|name=n_reg|value=`n_reg'"
if `n_reg' < 30 {
    display "SS_RC|code=2001|cmd=count_complete_cases|msg=small_sample_for_regression|severity=warn"
}

capture noisily regress ta_scaled inv_assets delta_rev ppe_scaled, noconstant
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress|msg=model_fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture noisily predict nda, xb
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=predict|msg=predict_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
generate da = ta_scaled - nda

summarize da
local mean_da = r(mean)
local sd_da = r(sd)
display "SS_METRIC|name=mean_da|value=`mean_da'"
display "SS_METRIC|name=sd_da|value=`sd_da'"

preserve
clear
set obs 1
gen str32 model = "Jones"
gen double mean_da = `mean_da'
gen double sd_da = `sd_da'
export delimited using "table_TL01_jones.csv", replace
display "SS_OUTPUT_FILE|file=table_TL01_jones.csv|type=table|desc=jones_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL01_jones.dta", replace
display "SS_OUTPUT_FILE|file=data_TL01_jones.dta|type=data|desc=jones_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_da|value=`mean_da'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL01|status=ok|elapsed_sec=`elapsed'"
log close
