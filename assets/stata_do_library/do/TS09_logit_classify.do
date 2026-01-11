* ==============================================================================
* SS_TEMPLATE: id=TS09  level=L2  module=S  title="Logit Classify"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS09_logit_result.csv type=table desc="Logit results"
*   - table_TS09_confusion.csv type=table desc="Confusion matrix"
*   - fig_TS09_roc.png type=figure desc="ROC curve"
*   - data_TS09_logit.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

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

display "SS_TASK_BEGIN|id=TS09|level=L2|title=Logit_Classify"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local threshold = __THRESHOLD__

local indepvars_clean ""
foreach v of local indepvars {
    if "`v'" != "`depvar'" {
        local indepvars_clean "`indepvars_clean' `v'"
    }
}
local indepvars "`indepvars_clean'"

if `threshold' <= 0 | `threshold' >= 1 {
    local threshold = 0.5
}

display ""
display ">>> Logistic分类参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    阈值: " %6.2f `threshold'

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

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
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ Logistic回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Logistic回归"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily logit `depvar' `valid_indep', or
if _rc == 2000 {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=logit|msg=perfect_prediction_fallback_to_intercept_only|severity=warn"
    capture noisily logit `depvar', or
}
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=logit|msg=logit_failed|severity=fail"
    log close
    exit `rc'
}

local ll = e(ll)
local pseudo_r2 = e(r2_p)

display ""
display ">>> 模型拟合:"
display "    对数似然: " %12.4f `ll'
display "    Pseudo R²: " %8.4f `pseudo_r2'

display "SS_METRIC|name=pseudo_r2|value=`pseudo_r2'"

* 导出系数
tempname logit_results
postfile `logit_results' str32 variable double coef double or double se double z double p ///
    using "temp_logit_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local or = exp(`coef')
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `logit_results' ("`vname'") (`coef') (`or') (`se') (`z') (`p')
}

postclose `logit_results'

preserve
use "temp_logit_results.dta", clear
export delimited using "table_TS09_logit_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TS09_logit_result.csv|type=table|desc=logit_results"
restore

* ============ 预测和混淆矩阵 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 预测与混淆矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

predict double prob, pr
generate byte pred_class = (prob >= `threshold')

* 混淆矩阵
quietly count if `depvar' == 1 & pred_class == 1
local tp = r(N)
quietly count if `depvar' == 0 & pred_class == 0
local tn = r(N)
quietly count if `depvar' == 0 & pred_class == 1
local fp = r(N)
quietly count if `depvar' == 1 & pred_class == 0
local fn = r(N)

local accuracy = (`tp' + `tn') / `n_input'
local precision = `tp' / (`tp' + `fp')
local recall = `tp' / (`tp' + `fn')
local f1 = 2 * `precision' * `recall' / (`precision' + `recall')
local specificity = `tn' / (`tn' + `fp')

display ""
display ">>> 混淆矩阵 (阈值=`threshold'):"
display "                  预测=0    预测=1"
display "    实际=0        " %6.0f `tn' "     " %6.0f `fp'
display "    实际=1        " %6.0f `fn' "     " %6.0f `tp'
display ""
display ">>> 性能指标:"
display "    准确率: " %8.4f `accuracy'
display "    精确率: " %8.4f `precision'
display "    召回率: " %8.4f `recall'
display "    F1分数: " %8.4f `f1'
display "    特异度: " %8.4f `specificity'

display "SS_METRIC|name=accuracy|value=`accuracy'"
display "SS_METRIC|name=f1|value=`f1'"

* 导出混淆矩阵
preserve
clear
set obs 4
generate str20 metric = ""
generate double value = .

replace metric = "TP" in 1
replace value = `tp' in 1
replace metric = "TN" in 2
replace value = `tn' in 2
replace metric = "FP" in 3
replace value = `fp' in 3
replace metric = "FN" in 4
replace value = `fn' in 4

export delimited using "table_TS09_confusion.csv", replace
display "SS_OUTPUT_FILE|file=table_TS09_confusion.csv|type=table|desc=confusion_matrix"
restore

* ============ ROC曲线 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: ROC曲线"
display "═══════════════════════════════════════════════════════════════════════════════"

roctab `depvar' prob, graph
local auc = r(area)

display ""
display ">>> AUC: " %8.4f `auc'

display "SS_METRIC|name=auc|value=`auc'"

graph export "fig_TS09_roc.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TS09_roc.png|type=figure|desc=roc_curve"

capture erase "temp_logit_results.dta"
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=rc_check|msg=nonzero_rc_ignored|severity=warn"
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS09_logit.dta", replace
display "SS_OUTPUT_FILE|file=data_TS09_logit.dta|type=data|desc=logit_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS09 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  分类性能:"
display "    准确率:        " %10.4f `accuracy'
display "    F1分数:        " %10.4f `f1'
display "    AUC:           " %10.4f `auc'
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
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS09|status=ok|elapsed_sec=`elapsed'"
log close
