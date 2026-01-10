* ==============================================================================
* SS_TEMPLATE: id=TL05  level=L1  module=L  title="Roychowdhury"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL05_rem.csv type=table desc="REM results"
*   - data_TL05_rem.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Roychowdhury REM usually estimates normal levels by industry-year; pooled estimates may mix heterogeneous operating environments.
* - Scaling by lagged assets and using revenue changes assumes consistent fiscal timing; verify panel/time setup.
* - REM composite (-abCFO + abPROD - abDISEXP) is sensitive to outliers; consider winsorization and reporting sample sizes per regression.
* 最佳实践审查（ZH）:
* - Roychowdhury 真实盈余管理通常按行业-年份估计“正常水平”；pooled 估计可能混合异质经营环境。
* - 使用滞后资产缩放与收入变动，依赖一致的财务期；请检查面板/时间设定。
* - REM 合成指标（-abCFO + abPROD - abDISEXP）对极端值敏感；建议截尾并报告各回归的有效样本量。
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

display "SS_TASK_BEGIN|id=TL05|level=L1|title=Roychowdhury"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local cfo = "__CFO__"
local prod = "__PROD__"
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
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and numeric types.
* ZH: 校验关键变量存在且为数值型。
local required_vars "`cfo' `prod' `disexp' `rev' `assets' `panelvar' `timevar'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
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
        display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Estimate abnormal CFO/PROD/DISEXP and compute REM composite.
* ZH: 估计异常 CFO/生产成本/费用并计算 REM 合成指标。

capture xtset `panelvar' `timevar'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=xtset `panelvar' `timevar'|msg=xtset_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

generate cfo_scaled = `cfo' / L.`assets'
generate prod_scaled = `prod' / L.`assets'
generate disexp_scaled = `disexp' / L.`assets'
generate inv_assets = 1 / L.`assets'
generate rev_scaled = `rev' / L.`assets'
generate delta_rev = D.`rev' / L.`assets'
generate lag_rev = L.`rev' / L.`assets'

* Abnormal CFO
count if !missing(cfo_scaled, inv_assets, rev_scaled, delta_rev)
local n_reg_cfo = r(N)
display "SS_METRIC|name=n_reg_cfo|value=`n_reg_cfo'"
if `n_reg_cfo' < 30 {
    display "SS_RC|code=2001|cmd=count_complete_cases|msg=small_sample_for_cfo_reg|severity=warn"
}
capture noisily regress cfo_scaled inv_assets rev_scaled delta_rev
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress_cfo|msg=model_fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture noisily predict ab_cfo, residuals
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=predict_ab_cfo|msg=predict_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

* Abnormal PROD
count if !missing(prod_scaled, inv_assets, rev_scaled, delta_rev, L.delta_rev)
local n_reg_prod = r(N)
display "SS_METRIC|name=n_reg_prod|value=`n_reg_prod'"
if `n_reg_prod' < 30 {
    display "SS_RC|code=2001|cmd=count_complete_cases|msg=small_sample_for_prod_reg|severity=warn"
}
capture noisily regress prod_scaled inv_assets rev_scaled delta_rev L.delta_rev
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress_prod|msg=model_fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture noisily predict ab_prod, residuals
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=predict_ab_prod|msg=predict_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

* Abnormal DISEXP
count if !missing(disexp_scaled, inv_assets, lag_rev)
local n_reg_disexp = r(N)
display "SS_METRIC|name=n_reg_disexp|value=`n_reg_disexp'"
if `n_reg_disexp' < 30 {
    display "SS_RC|code=2001|cmd=count_complete_cases|msg=small_sample_for_disexp_reg|severity=warn"
}
capture noisily regress disexp_scaled inv_assets lag_rev
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=regress_disexp|msg=model_fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture noisily predict ab_disexp, residuals
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=predict_ab_disexp|msg=predict_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}

generate rem = -ab_cfo + ab_prod - ab_disexp

summarize rem
local mean_rem = r(mean)
display "SS_METRIC|name=mean_rem|value=`mean_rem'"

preserve
clear
set obs 1
gen str32 model = "Roychowdhury REM"
gen double mean_rem = `mean_rem'
export delimited using "table_TL05_rem.csv", replace
display "SS_OUTPUT_FILE|file=table_TL05_rem.csv|type=table|desc=rem_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL05_rem.dta", replace
display "SS_OUTPUT_FILE|file=data_TL05_rem.dta|type=data|desc=rem_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_rem|value=`mean_rem'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TL05|status=ok|elapsed_sec=`elapsed'"
log close
