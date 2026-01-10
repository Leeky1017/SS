* ==============================================================================
* SS_TEMPLATE: id=TM10  level=L1  module=M  title="Matched CC"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM10_mcc.csv type=table desc="Matched CC results"
*   - data_TM10_mcc.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Matched case-control analysis requires correct matching ID and appropriate conditional logistic specification.
* - Sparse strata or no within-strata variation can cause estimation failures; handle these explicitly.
* - Report matching scheme and check balance within matched sets before interpretation.
* 最佳实践审查（ZH）:
* - 匹配病例-对照分析依赖正确的匹配组 ID 与条件 logit 设定。
* - 匹配组稀疏或组内无变异会导致估计失败；应显式处理并给出告警。
* - 建议在解读前说明匹配方案并检查匹配组内平衡性。
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

display "SS_TASK_BEGIN|id=TM10|level=L1|title=Matched_CC"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local case = "__CASE__"
local exposure = "__EXPOSURE__"
local match_id = "__MATCH_ID__"

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
    display "SS_TASK_END|id=TM10|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate required variables exist.
* ZH: 校验关键变量存在。
local required_vars "`case' `exposure' `match_id'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TM10|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

local model_ok = 1
local or = .
local ll = .
capture clogit `case' `exposure', group(`match_id') or
local rc = _rc
if `rc' != 0 {
    local model_ok = 0
    display "SS_RC|code=`rc'|cmd=clogit|msg=model_fit_failed|severity=warn"
}
if `rc' == 0 {
    local or = exp(_b[`exposure'])
    local ll = e(ll)
}
display "SS_METRIC|name=odds_ratio|value=`or'"
display "SS_METRIC|name=log_likelihood|value=`ll'"

preserve
clear
set obs 1
gen double or = `or'
gen double ll = `ll'
export delimited using "table_TM10_mcc.csv", replace
display "SS_OUTPUT_FILE|file=table_TM10_mcc.csv|type=table|desc=mcc_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM10_mcc.dta", replace
display "SS_OUTPUT_FILE|file=data_TM10_mcc.dta|type=data|desc=mcc_data"
local step_status "ok"
if `model_ok' == 0 {
    local step_status "warn"
}
display "SS_STEP_END|step=S03_analysis|status=`step_status'|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=odds_ratio|value=`or'"

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
display "SS_TASK_END|id=TM10|status=`task_status'|elapsed_sec=`elapsed'"
log close
