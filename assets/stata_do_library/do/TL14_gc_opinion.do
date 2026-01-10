* ==============================================================================
* SS_TEMPLATE: id=TL14  level=L1  module=L  title="GC Opinion"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TL14_gc.csv type=table desc="GC opinion results"
*   - data_TL14_gc.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Going-concern opinion models are typically logistic with careful outcome definition; confirm `__GC__` coding (0/1) and timing.
* - Separation and rare events can cause non-convergence; treat AUC and pseudo-R2 as descriptive diagnostics, not final evidence.
* - Consider clustering or fixed effects when panel structure exists; this template keeps a portable baseline specification.
* 最佳实践审查（ZH）:
* - 持续经营意见模型通常用 logit；请确认 `__GC__` 的 0/1 编码与时间匹配。
* - 罕见事件/完全分离可能导致不收敛；AUC 与 pseudo-R2 更适合作为描述性诊断。
* - 若存在面板结构，可考虑聚类/固定效应；本模板提供可移植的基线设定。
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

display "SS_TASK_BEGIN|id=TL14|level=L1|title=GC_Opinion"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local gc = "__GC__"
local zscore = "__ZSCORE__"
local loss = "__LOSS__"
local laggc = "__LAGGC__"
local lnta = "__LNTA__"
local leverage = "__LEVERAGE__"

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
    display "SS_TASK_END|id=TL14|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TL14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables and numeric types.
* ZH: 校验关键变量存在且为数值型。
local required_vars "`gc' `zscore' `loss' `laggc' `lnta' `leverage'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TL14|status=fail|elapsed_sec=`elapsed'"
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
        display "SS_TASK_END|id=TL14|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Fit logistic model and report AUC via lroc when available.
* ZH: 拟合 logit 模型，并在可用时通过 lroc 报告 AUC。

count if !missing(`gc', `zscore', `loss', `laggc', `lnta', `leverage')
local n_reg = r(N)
display "SS_METRIC|name=n_reg|value=`n_reg'"
if `n_reg' < 50 {
    display "SS_RC|code=2001|cmd=count_complete_cases|msg=small_sample_for_logit|severity=warn"
}

count if `gc' == 0 & !missing(`gc')
local n0 = r(N)
count if `gc' == 1 & !missing(`gc')
local n1 = r(N)
display "SS_METRIC|name=n_outcome_0|value=`n0'"
display "SS_METRIC|name=n_outcome_1|value=`n1'"
if (`n0' == 0) | (`n1' == 0) {
    display "SS_RC|code=2002|cmd=validate_binary_outcome|msg=outcome_has_no_variation|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TL14|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2002
}

local model_ok = 1
local roc_ok = 1
local ll = .
local pseudo_r2 = .
local auc = .

capture noisily logit `gc' `zscore' `loss' `laggc' `lnta' `leverage'
local rc = _rc
if `rc' != 0 {
    local model_ok = 0
    local roc_ok = 0
    display "SS_RC|code=`rc'|cmd=logit|msg=model_fit_failed|severity=warn"
}
if `rc' == 0 {
    local ll = e(ll)
    local pseudo_r2 = e(r2_p)
    capture noisily lroc
    local rc_lroc = _rc
    if `rc_lroc' != 0 {
        local roc_ok = 0
        display "SS_RC|code=`rc_lroc'|cmd=lroc|msg=roc_failed|severity=warn"
    }
    if `rc_lroc' == 0 {
        local auc = r(area)
    }
}
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=pseudo_r2|value=`pseudo_r2'"
display "SS_METRIC|name=auc|value=`auc'"

preserve
clear
set obs 1
gen str32 model = "GC Opinion"
gen double pseudo_r2 = `pseudo_r2'
gen double auc = `auc'
export delimited using "table_TL14_gc.csv", replace
display "SS_OUTPUT_FILE|file=table_TL14_gc.csv|type=table|desc=gc_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TL14_gc.dta", replace
display "SS_OUTPUT_FILE|file=data_TL14_gc.dta|type=data|desc=gc_data"
local step_status "ok"
if (`model_ok' == 0) | (`roc_ok' == 0) {
    local step_status "warn"
}
display "SS_STEP_END|step=S03_analysis|status=`step_status'|elapsed_sec=0"

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

local task_status "ok"
if (`model_ok' == 0) | (`roc_ok' == 0) {
    local task_status "warn"
}
display "SS_TASK_END|id=TL14|status=`task_status'|elapsed_sec=`elapsed'"
log close
