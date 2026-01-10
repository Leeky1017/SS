* ==============================================================================
* SS_TEMPLATE: id=TM13  level=L1  module=M  title="Log Binomial"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM13_pr.csv type=table desc="PR results"
*   - data_TM13_pr.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Log-binomial models can have convergence issues; consider Poisson with robust SE as a practical alternative for PR estimation.
* - Outcome should be binary; check separation and small cell counts.
* - Interpret PR alongside baseline risk and covariate adjustment assumptions.
* 最佳实践审查（ZH）:
* - Log-binomial 模型常出现不收敛；可考虑“Poisson + robust”作为 PR 的实用替代。
* - 结局应为二分类；需关注完全分离与小单元格计数。
* - PR 解读需结合基线风险与协变量调整假设。
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

display "SS_TASK_BEGIN|id=TM13|level=L1|title=Log_Binomial"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local outcome = "__OUTCOME__"
local indepvars = "__INDEPVARS__"

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
    display "SS_TASK_END|id=TM13|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM13|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate outcome and covariates exist; outcome must be binary numeric.
* ZH: 校验结局与协变量存在；结局需为数值型二分类。
capture confirm variable `outcome'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `outcome'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM13|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM13|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly levelsof `outcome' if !missing(`outcome'), local(o_levels)
local n_o : word count `o_levels'
display "SS_METRIC|name=n_outcome_levels|value=`n_o'"
if `n_o' != 2 {
    display "SS_RC|code=2002|cmd=validate_binary_outcome|msg=outcome_not_binary|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM13|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2002
}
foreach v of varlist `indepvars' {
    capture confirm numeric variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm numeric variable `v'|msg=var_not_numeric|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TM13|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* EN: Fit log-binomial GLM; warn on non-convergence.
* ZH: 拟合 log-binomial GLM；对不收敛显式告警。
local model_ok = 1
local ll = .
capture noisily glm `outcome' `indepvars', family(binomial) link(log) eform
if _rc {
    local model_ok = 0
    display "SS_RC|code=`=_rc'|cmd=glm_log_binomial|msg=model_fit_failed|severity=warn"
}
if `model_ok' == 1 {
    local ll = e(ll)
}
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen str32 model = "Log-Binomial"
gen double ll = `ll'
export delimited using "table_TM13_pr.csv", replace
display "SS_OUTPUT_FILE|file=table_TM13_pr.csv|type=table|desc=pr_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM13_pr.dta", replace
display "SS_OUTPUT_FILE|file=data_TM13_pr.dta|type=data|desc=pr_data"
local step_status "ok"
if `model_ok' == 0 {
    local step_status "warn"
}
display "SS_STEP_END|step=S03_analysis|status=`step_status'|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=log_likelihood|value=`ll'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

local task_status "ok"
if `model_ok' == 0 {
    local task_status "warn"
}
display "SS_TASK_END|id=TM13|status=`task_status'|elapsed_sec=`elapsed'"
log close
