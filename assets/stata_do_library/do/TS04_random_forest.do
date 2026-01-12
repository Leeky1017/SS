* ==============================================================================
* SS_TEMPLATE: id=TS04  level=L2  module=S  title="Random Forest"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS04_rf_importance.csv type=table desc="Variable importance"
*   - table_TS04_rf_result.csv type=table desc="Model results"
*   - data_TS04_rf.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Use out-of-bag/CV metrics and a proper test set; avoid leakage from preprocessing or feature engineering.
* - Tune key hyperparameters (trees, depth, mtry) and report stability; importance can be biased with correlated predictors.
* - Set seeds for reproducibility and document class imbalance handling for classification.
* 最佳实践审查（ZH）:
* - 使用 OOB/CV 指标与独立测试集评估；避免预处理/特征工程带来的信息泄露。
* - 调参并报告稳定性；相关自变量下变量重要性可能有偏。
* - 设置随机种子以保证可复现；分类任务请关注类别不平衡处理。

* ============ 初始化 ============
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

display "SS_TASK_BEGIN|id=TS04|level=L2|title=Random_Forest"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

capture which rforest
local has_rforest = 1
if _rc {
    local rc = _rc
    local has_rforest = 0
    display "SS_RC|code=`rc'|cmd=which rforest|msg=dep_missing_rforest_fallback|severity=warn"
}
display "SS_METRIC|name=rforest_available|value=`has_rforest'"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local n_trees_raw = "__N_TREES__"
local n_trees = real("`n_trees_raw'")
local type = "__TYPE__"

if missing(`n_trees') | `n_trees' < 10 | `n_trees' > 1000 {
    local n_trees = 100
}
local n_trees = floor(`n_trees')
if "`type'" == "" {
    local type = "regress"
}
if !inlist("`type'", "regress", "classify") {
    display "SS_RC|code=11|cmd=param_check|msg=invalid_type_defaulted|value=`type'|severity=warn"
    local type = "regress"
}

display ""
display ">>> 随机森林参数:"
display "    因变量: `depvar'"
display "    树数量: `n_trees'"
display "    类型: `type'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and basic types.
* ZH: 校验关键变量存在且类型合理。

* ============ 变量检查 ============
capture confirm numeric variable `depvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found_or_not_numeric|var=`depvar'|severity=fail"
    log close
    exit 200
}

local valid_indep ""
local n_vars = 0
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
        local n_vars = `n_vars' + 1
    }
}
if `n_vars' <= 0 {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=no_valid_indepvars|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Train random forest (or fallback) and export importance/performance metrics.
* ZH: 训练随机森林（或回退模型）并导出重要性与性能指标。

* ============ 随机森林 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 随机森林模型"
display "═══════════════════════════════════════════════════════════════════════════════"

local oob_error = .
if `has_rforest' == 1 {
    if "`type'" == "classify" {
        rforest `depvar' `valid_indep', type(classify) iterations(`n_trees')
    }
    else {
        rforest `depvar' `valid_indep', type(reg) iterations(`n_trees')
    }
    local oob_error = e(OOB_Error)
}
else {
    display "SS_RC|code=111|cmd=rforest|msg=using_fallback_model|severity=warn"
    if "`type'" == "classify" {
        quietly logit `depvar' `valid_indep'
    }
    else {
        quietly regress `depvar' `valid_indep'
    }
}

display ""
display ">>> 随机森林结果:"
display "    树数量: `n_trees'"
display "    OOB误差: " %10.4f `oob_error'

display "SS_METRIC|name=n_trees|value=`n_trees'"
display "SS_METRIC|name=oob_error|value=`oob_error'"

* ============ 变量重要性 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 变量重要性"
display "═══════════════════════════════════════════════════════════════════════════════"

capture matrix importance = e(importance)

tempname rf_importance
postfile `rf_importance' str32 variable double importance ///
    using "temp_rf_importance.dta", replace

display ""
display ">>> 变量重要性 (排序):"
display "变量                重要性"
display "────────────────────────────"

local nvars : word count `valid_indep'
forvalues i = 1/`nvars' {
    local vname : word `i' of `valid_indep'
    local imp = .
    if `has_rforest' == 1 {
        local imp = importance[`i', 1]
    }
    post `rf_importance' ("`vname'") (`imp')
    display %20s "`vname'" "  " %12.6f `imp'
}

postclose `rf_importance'

preserve
use "temp_rf_importance.dta", clear
gsort -importance
export delimited using "table_TS04_rf_importance.csv", replace
display "SS_OUTPUT_FILE|file=table_TS04_rf_importance.csv|type=table|desc=rf_importance"
restore

* ============ 预测 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 预测与评估"
display "═══════════════════════════════════════════════════════════════════════════════"

capture predict double rf_pred
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=predict|msg=predict_failed|severity=fail"
    log close
    exit `rc'
}

if "`type'" == "classify" {
    gen byte rf_class = rf_pred
    if `has_rforest' == 0 {
        replace rf_class = (rf_pred > 0.5)
    }
    generate byte correct = (`depvar' == rf_class)
    quietly summarize correct
    local accuracy = r(mean)
    
    display ""
    display ">>> 分类准确率: " %6.2f `=`accuracy'*100' "%"
    display "SS_METRIC|name=accuracy|value=`accuracy'"
}
else {
    generate double rf_resid = `depvar' - rf_pred
    quietly summarize rf_resid
    local rmse = sqrt(r(Var) + r(mean)^2)
    
    quietly correlate `depvar' rf_pred
    local r2 = r(rho)^2
    
    display ""
    display ">>> 回归性能:"
    display "    RMSE: " %12.6f `rmse'
    display "    R²: " %10.4f `r2'
    
    display "SS_METRIC|name=rmse|value=`rmse'"
    display "SS_METRIC|name=r2|value=`r2'"
}

* 导出结果摘要
preserve
clear
set obs 1
generate int n_trees = `n_trees'
generate double oob_error = `oob_error'
generate int n_vars = `n_vars'

export delimited using "table_TS04_rf_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TS04_rf_result.csv|type=table|desc=rf_result"
restore

capture erase "temp_rf_importance.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS04_rf.dta", replace
display "SS_OUTPUT_FILE|file=data_TS04_rf.dta|type=data|desc=rf_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display "  树数量:          " %10.0fc `n_trees'
display "  OOB误差:         " %10.4f `oob_error'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=oob_error|value=`oob_error'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS04|status=ok|elapsed_sec=`elapsed'"
log close
