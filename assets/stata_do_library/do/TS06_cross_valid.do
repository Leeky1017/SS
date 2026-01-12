* ==============================================================================
* SS_TEMPLATE: id=TS06  level=L2  module=S  title="Cross Valid"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS06_cv_folds.csv type=table desc="Fold results"
*   - table_TS06_cv_summary.csv type=table desc="CV summary"
*   - data_TS06_cv.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Cross-validation must avoid leakage: preprocessing/feature engineering should be learned within training folds only.
* - For classification, consider stratified folds and metrics beyond accuracy (AUC, F1), especially under class imbalance.
* - Report variability across folds (mean/SD) and keep a final hold-out test when possible.
* 最佳实践审查（ZH）:
* - 交叉验证要避免信息泄露：标准化/特征工程等预处理应仅在训练折中拟合。
* - 分类任务建议分层抽样并使用多指标（AUC、F1 等），尤其在类别不平衡时。
* - 报告各折波动（均值/标准差）；条件允许时保留最终独立测试集。

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

display "SS_TASK_BEGIN|id=TS06|level=L2|title=Cross_Valid"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local k_folds_raw = "__K_FOLDS__"
local k_folds = real("`k_folds_raw'")
local model = "__MODEL__"

if missing(`k_folds') | `k_folds' < 2 | `k_folds' > 20 {
    local k_folds = 5
}
local k_folds = floor(`k_folds')
if "`model'" == "" {
    local model = "ols"
}
if !inlist("`model'", "ols", "logit") {
    display "SS_RC|code=11|cmd=param_check|msg=invalid_model_defaulted|value=`model'|severity=warn"
    local model = "ols"
}

display ""
display ">>> 交叉验证参数:"
display "    因变量: `depvar'"
display "    K折: `k_folds'"
display "    模型: `model'"

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
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found|severity=fail"
    log close
    exit 200
}

local valid_indep ""
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
    }
}
if "`valid_indep'" == "" {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=no_valid_indepvars|severity=fail"
    log close
    exit 200
}
if "`model'" == "logit" {
    quietly count if !inlist(`depvar', 0, 1) & !missing(`depvar')
    if r(N) > 0 {
        display "SS_RC|code=10|cmd=depvar_check|msg=depvar_not_binary_for_logit|severity=warn"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Run K-fold CV and summarize fold metrics.
* ZH: 执行 K 折交叉验证并汇总各折指标。

* ============ 创建折 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 创建K折"
display "═══════════════════════════════════════════════════════════════════════════════"

set seed 12345
generate double _rand = runiform()
sort _rand
generate int _fold = mod(_n - 1, `k_folds') + 1
drop _rand

display ">>> 已创建 `k_folds' 折"
tabulate _fold

* ============ K折交叉验证 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 执行交叉验证"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname cv_results
postfile `cv_results' int fold int n_train int n_test double metric ///
    using "temp_cv_folds.dta", replace

generate double _cv_pred = .

forvalues k = 1/`k_folds' {
    display ">>> 折 `k' / `k_folds'..."
    
    * 训练集和测试集
    quietly count if _fold != `k'
    local n_train = r(N)
    quietly count if _fold == `k'
    local n_test = r(N)
    
    * 训练模型
    if "`model'" == "logit" {
        quietly logit `depvar' `valid_indep' if _fold != `k'
        predict double _temp_pred if _fold == `k', pr
    }
    else {
        quietly regress `depvar' `valid_indep' if _fold != `k'
        predict double _temp_pred if _fold == `k', xb
    }
    
    replace _cv_pred = _temp_pred if _fold == `k'
    
    * 计算性能指标
    if "`model'" == "logit" {
        * 准确率
        generate byte _correct = (`depvar' == (_temp_pred > 0.5)) if _fold == `k'
        quietly summarize _correct if _fold == `k'
        local metric = r(mean)
        drop _correct
    }
    else {
        * MSE
        generate double _resid2 = (`depvar' - _temp_pred)^2 if _fold == `k'
        quietly summarize _resid2 if _fold == `k'
        local metric = r(mean)
        drop _resid2
    }
    
    post `cv_results' (`k') (`n_train') (`n_test') (`metric')
    
    drop _temp_pred
}

postclose `cv_results'

* ============ CV结果汇总 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 交叉验证结果"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_cv_folds.dta", clear

display ""
display ">>> 各折结果:"
if "`model'" == "logit" {
    display "折    训练集    测试集    准确率"
}
else {
    display "折    训练集    测试集    MSE"
}
display "────────────────────────────────────"
list fold n_train n_test metric, noobs

quietly summarize metric
local cv_mean = r(mean)
local cv_sd = r(sd)

display ""
if "`model'" == "logit" {
    display ">>> CV平均准确率: " %8.4f `cv_mean' " (SD=" %6.4f `cv_sd' ")"
}
else {
    display ">>> CV平均MSE: " %12.6f `cv_mean' " (SD=" %10.6f `cv_sd' ")"
    local cv_rmse = sqrt(`cv_mean')
    display ">>> CV RMSE: " %12.6f `cv_rmse'
}

export delimited using "table_TS06_cv_folds.csv", replace
display "SS_OUTPUT_FILE|file=table_TS06_cv_folds.csv|type=table|desc=cv_folds"
restore

display "SS_METRIC|name=cv_mean|value=`cv_mean'"
display "SS_METRIC|name=cv_sd|value=`cv_sd'"

* 导出汇总
preserve
clear
set obs 1
generate int k_folds = `k_folds'
generate str10 model = "`model'"
generate double cv_mean = `cv_mean'
generate double cv_sd = `cv_sd'

export delimited using "table_TS06_cv_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TS06_cv_summary.csv|type=table|desc=cv_summary"
restore

capture erase "temp_cv_folds.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS06_cv.dta", replace
display "SS_OUTPUT_FILE|file=data_TS06_cv.dta|type=data|desc=cv_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS06 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  K折:             " %10.0fc `k_folds'
display "  模型:            `model'"
display ""
display "  交叉验证结果:"
if "`model'" == "logit" {
    display "    平均准确率:    " %10.4f `cv_mean'
}
else {
    display "    平均MSE:       " %12.6f `cv_mean'
}
display "    标准差:        " %10.4f `cv_sd'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=cv_mean|value=`cv_mean'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS06|status=ok|elapsed_sec=`elapsed'"
log close
