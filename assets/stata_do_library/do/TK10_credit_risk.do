* ==============================================================================
* SS_TEMPLATE: id=TK10  level=L2  module=K  title="Credit Risk"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK10_model_result.csv type=table desc="Model results"
*   - table_TK10_performance.csv type=table desc="Performance metrics"
*   - fig_TK10_roc.png type=figure desc="ROC curve"
*   - data_TK10_credit.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TK10|level=L2|title=Credit_Risk"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local default_var = "__DEFAULT_VAR__"
local predictors = "__PREDICTORS__"
local model = "__MODEL__"

if "`model'" == "" | ("`model'" != "logit" & "`model'" != "probit") {
    local model = "logit"
}

display ""
display ">>> 信用风险模型参数:"
display "    违约变量: `default_var'"
display "    预测变量: `predictors'"
display "    模型: `model'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
capture confirm numeric variable `default_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`default_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`default_var' not found"
    log close
    exit 200
}

local valid_predictors ""
foreach var of local predictors {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_predictors "`valid_predictors' `var'"
    }
}

* 违约率统计
quietly count if `default_var' == 1
local n_default = r(N)
local default_rate = `n_default' / `n_input'

display ""
display ">>> 样本统计:"
display "    总样本: `n_input'"
display "    违约数: `n_default'"
display "    违约率: " %6.2f `=`default_rate'*100' "%"

display "SS_METRIC|name=default_rate|value=`default_rate'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 模型估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: `=upper("`model'")'模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

`model' `default_var' `valid_predictors', robust

* 保存模型结果
local ll = e(ll)
local ll_0 = e(ll_0)
local pseudo_r2 = 1 - `ll' / `ll_0'
local aic = -2 * `ll' + 2 * e(k)
local bic = -2 * `ll' + ln(e(N)) * e(k)

display ""
display ">>> 模型拟合统计:"
display "    对数似然: " %12.4f `ll'
display "    Pseudo R2: " %8.4f `pseudo_r2'
display "    AIC: " %12.4f `aic'
display "    BIC: " %12.4f `bic'

display "SS_METRIC|name=pseudo_r2|value=`pseudo_r2'"

* 导出系数
tempname coefs
postfile `coefs' str32 variable double coef double se double z double p double odds_ratio ///
    using "temp_coefs.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    local or = exp(`coef')
    post `coefs' ("`vname'") (`coef') (`se') (`z') (`p') (`or')
}

postclose `coefs'

preserve
use "temp_coefs.dta", clear
export delimited using "table_TK10_model_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TK10_model_result.csv|type=table|desc=model_results"
restore

* ============ 预测违约概率 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 预测违约概率"
display "═══════════════════════════════════════════════════════════════════════════════"

predict double pd, pr
label variable pd "预测违约概率"

quietly summarize pd
display ""
display ">>> PD分布:"
display "    均值: " %8.4f r(mean)
display "    标准差: " %8.4f r(sd)
display "    范围: [" %6.4f r(min) ", " %6.4f r(max) "]"

* ============ 模型评估 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 模型评估"
display "═══════════════════════════════════════════════════════════════════════════════"

* KS统计量
quietly ksmirnov pd, by(`default_var')
local ks_stat = r(D)
local ks_p = r(p)

display ""
display ">>> KS检验:"
display "    KS统计量: " %8.4f `ks_stat'
display "    p值: " %8.4f `ks_p'

display "SS_METRIC|name=ks_stat|value=`ks_stat'"

* 计算ROC曲线和AUC
tempname roc_data
postfile `roc_data' double threshold double tpr double fpr ///
    using "temp_roc.dta", replace

local auc = 0
local prev_fpr = 0
local prev_tpr = 0

forvalues thresh = 0(0.01)1 {
    * True Positive Rate (Sensitivity)
    quietly count if pd >= `thresh' & `default_var' == 1
    local tp = r(N)
    quietly count if `default_var' == 1
    local p = r(N)
    local tpr = `tp' / `p'
    
    * False Positive Rate (1 - Specificity)
    quietly count if pd >= `thresh' & `default_var' == 0
    local fp = r(N)
    quietly count if `default_var' == 0
    local n = r(N)
    local fpr = `fp' / `n'
    
    post `roc_data' (`thresh') (`tpr') (`fpr')
    
    * 梯形法则计算AUC
    local auc = `auc' + (`prev_tpr' + `tpr') * (`prev_fpr' - `fpr') / 2
    local prev_tpr = `tpr'
    local prev_fpr = `fpr'
}

postclose `roc_data'

* Gini系数
local gini = 2 * `auc' - 1

display ""
display ">>> ROC分析:"
display "    AUC: " %8.4f `auc'
display "    Gini系数: " %8.4f `gini'

display "SS_METRIC|name=auc|value=`auc'"
display "SS_METRIC|name=gini|value=`gini'"

* 混淆矩阵（以0.5为阈值）
generate byte pred_default = (pd >= 0.5)

quietly count if pred_default == 1 & `default_var' == 1
local tp = r(N)
quietly count if pred_default == 0 & `default_var' == 0
local tn = r(N)
quietly count if pred_default == 1 & `default_var' == 0
local fp = r(N)
quietly count if pred_default == 0 & `default_var' == 1
local fn = r(N)

local accuracy = (`tp' + `tn') / `n_input'
local precision = `tp' / (`tp' + `fp')
local recall = `tp' / (`tp' + `fn')
local f1 = 2 * `precision' * `recall' / (`precision' + `recall')

display ""
display ">>> 混淆矩阵 (阈值=0.5):"
display "    真正例(TP): `tp'"
display "    真负例(TN): `tn'"
display "    假正例(FP): `fp'"
display "    假负例(FN): `fn'"
display ""
display ">>> 性能指标:"
display "    准确率: " %8.4f `accuracy'
display "    精确率: " %8.4f `precision'
display "    召回率: " %8.4f `recall'
display "    F1分数: " %8.4f `f1'

* 导出性能指标
preserve
clear
set obs 6
generate str20 metric = ""
generate double value = .

replace metric = "AUC" in 1
replace value = `auc' in 1
replace metric = "Gini" in 2
replace value = `gini' in 2
replace metric = "KS" in 3
replace value = `ks_stat' in 3
replace metric = "Accuracy" in 4
replace value = `accuracy' in 4
replace metric = "Precision" in 5
replace value = `precision' in 5
replace metric = "Recall" in 6
replace value = `recall' in 6

export delimited using "table_TK10_performance.csv", replace
display "SS_OUTPUT_FILE|file=table_TK10_performance.csv|type=table|desc=performance"
restore

* ============ 生成ROC曲线 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成ROC曲线"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_roc.dta", clear

twoway (line tpr fpr, lcolor(navy) lwidth(medium)) ///
       (function y = x, range(0 1) lcolor(gray) lpattern(dash)), ///
       legend(order(1 "ROC曲线" 2 "随机猜测") position(6)) ///
       xtitle("假正例率 (1-特异性)") ytitle("真正例率 (敏感性)") ///
       title("ROC曲线") ///
       note("AUC=" %5.3f `auc' ", Gini=" %5.3f `gini')
graph export "fig_TK10_roc.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK10_roc.png|type=figure|desc=roc_curve"
restore

* 清理
capture erase "temp_coefs.dta"
if _rc != 0 { }
capture erase "temp_roc.dta"
if _rc != 0 { }

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK10_credit.dta", replace
display "SS_OUTPUT_FILE|file=data_TK10_credit.dta|type=data|desc=credit_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK10 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  违约数:          " %10.0fc `n_default'
display "  违约率:          " %10.2f `=`default_rate'*100' "%"
display ""
display "  模型性能:"
display "    Pseudo R2:     " %10.4f `pseudo_r2'
display "    AUC:           " %10.4f `auc'
display "    Gini:          " %10.4f `gini'
display "    KS:            " %10.4f `ks_stat'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=auc|value=`auc'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK10|status=ok|elapsed_sec=`elapsed'"
log close
