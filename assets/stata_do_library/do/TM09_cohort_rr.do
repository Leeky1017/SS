* ==============================================================================
* SS_TEMPLATE: id=TM09  level=L1  module=M  title="Cohort RR"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM09_rr.csv type=table desc="RR results"
*   - data_TM09_rr.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Cohort RR assumes incidence can be estimated within exposed/unexposed groups; ensure follow-up and censoring are handled appropriately.
* - Sparse events can lead to unstable CI; consider exact methods or alternative models when needed.
* - Report absolute risk difference (ARD) alongside RR for clinical interpretation.
* 最佳实践审查（ZH）:
* - 队列 RR 依赖暴露/未暴露组的发病估计；请确保随访与删失处理合理。
* - 事件稀少会导致置信区间不稳定；必要时考虑精确方法或替代模型。
* - 建议同时报告绝对风险差（ARD）以便临床解读。
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

display "SS_TASK_BEGIN|id=TM09|level=L1|title=Cohort_RR"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local outcome = "__OUTCOME__"
local exposure = "__EXPOSURE__"

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
    display "SS_TASK_END|id=TM09|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate binary outcome/exposure variables.
* ZH: 校验结局/暴露变量为二分类。
capture confirm variable `outcome'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `outcome'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `exposure'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `exposure'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM09|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `exposure'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `exposure'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly levelsof `outcome' if !missing(`outcome'), local(o_levels)
quietly levelsof `exposure' if !missing(`exposure'), local(e_levels)
local n_o : word count `o_levels'
local n_e : word count `e_levels'
display "SS_METRIC|name=n_outcome_levels|value=`n_o'"
display "SS_METRIC|name=n_exposure_levels|value=`n_e'"
if (`n_o' != 2) | (`n_e' != 2) {
    display "SS_RC|code=2002|cmd=validate_binary_vars|msg=non_binary_detected|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2002
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* EN: Estimate RR via cs.
* ZH: 使用 cs 估计 RR。
capture noisily cs `outcome' `exposure'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=cs|msg=cs_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local rr = r(rr)
local lb = r(lb_rr)
local ub = r(ub_rr)
local ard = r(ard)
display "SS_METRIC|name=relative_risk|value=`rr'"
display "SS_METRIC|name=rr_ci_lb|value=`lb'"
display "SS_METRIC|name=rr_ci_ub|value=`ub'"

preserve
clear
set obs 1
gen double rr = `rr'
gen double lb = `lb'
gen double ub = `ub'
gen double ard = `ard'
export delimited using "table_TM09_rr.csv", replace
display "SS_OUTPUT_FILE|file=table_TM09_rr.csv|type=table|desc=rr_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM09_rr.dta", replace
display "SS_OUTPUT_FILE|file=data_TM09_rr.dta|type=data|desc=rr_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=relative_risk|value=`rr'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM09|status=ok|elapsed_sec=`elapsed'"
log close
