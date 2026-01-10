* ==============================================================================
* SS_TEMPLATE: id=TM01  level=L1  module=M  title="ROC Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TM01_roc.png type=graph desc="ROC curve"
*   - table_TM01_roc.csv type=table desc="ROC results"
*   - data_TM01_roc.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Confirm `__OUTCOME__` is binary (two distinct values) and the positive class definition matches your clinical question.
* - ROC/AUC describes discrimination, not calibration; consider reporting prevalence and sensitivity/specificity at clinically meaningful cutoffs.
* - Small samples and separation can destabilize logit-based ROC; handle failures explicitly and report warnings.
* 最佳实践审查（ZH）:
* - 请确认 `__OUTCOME__` 为二分类（仅两个取值），且“阳性/事件”定义符合临床问题。
* - ROC/AUC 衡量区分度而非校准；建议同时报告患病率与关键阈值下的敏感度/特异度。
* - 小样本/完全分离会导致 logit 不稳定；应显式处理失败并给出告警。
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

display "SS_TASK_BEGIN|id=TM01|level=L1|title=ROC_Analysis"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local outcome = "__OUTCOME__"
local predictor = "__PREDICTOR__"

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
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate outcome/predictor existence and basic requirements for ROC.
* ZH: 校验结局/预测变量存在且满足 ROC 的基本要求。
capture confirm variable `outcome'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `outcome'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `predictor'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `predictor'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `predictor'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `predictor'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `outcome'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `outcome'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly levelsof `outcome' if !missing(`outcome'), local(levels)
local n_levels : word count `levels'
display "SS_METRIC|name=n_outcome_levels|value=`n_levels'"
if `n_levels' != 2 {
    display "SS_RC|code=2002|cmd=validate_binary_outcome|msg=outcome_not_binary|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2002
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Fit logit model and derive ROC/AUC; handle non-convergence/separation explicitly.
* ZH: 拟合 logit 并计算 ROC/AUC；对不收敛/完全分离显式处理。
capture noisily logit `outcome' `predictor'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=logit|msg=model_fit_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture noisily lroc, title("ROC曲线")
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=lroc|msg=roc_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM01|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
graph export "fig_TM01_roc.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TM01_roc.png|type=graph|desc=roc_curve"

local auc = r(area)
display "SS_METRIC|name=auc|value=`auc'"

local cutoff = .
local sens = .
local spec = .
capture noisily lsens
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=lsens|msg=sens_spec_failed|severity=warn"
}
if _rc == 0 {
    local cutoff = r(cutoff)
    local sens = r(sens)
    local spec = r(spec)
}
display "SS_METRIC|name=cutoff|value=`cutoff'"
display "SS_METRIC|name=sensitivity|value=`sens'"
display "SS_METRIC|name=specificity|value=`spec'"

preserve
clear
set obs 1
gen str32 analysis = "ROC"
gen double auc = `auc'
gen double sens = `sens'
gen double spec = `spec'
export delimited using "table_TM01_roc.csv", replace
display "SS_OUTPUT_FILE|file=table_TM01_roc.csv|type=table|desc=roc_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM01_roc.dta", replace
display "SS_OUTPUT_FILE|file=data_TM01_roc.dta|type=data|desc=roc_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

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

display "SS_TASK_END|id=TM01|status=ok|elapsed_sec=`elapsed'"
log close
