* ==============================================================================
* SS_TEMPLATE: id=TM02  level=L1  module=M  title="Diagnostic Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM02_diag.csv type=table desc="Diagnostic results"
*   - data_TM02_diag.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Confirm `__GOLD__` and `__TEST__` are coded consistently as binary variables; define which level is “positive” for interpretation.
* - Report the 2x2 table counts (TP/FP/FN/TN) and handle zero cells explicitly (some metrics may be undefined).
* - Consider confidence intervals and prevalence context; point estimates alone can be misleading in small samples.
* 最佳实践审查（ZH）:
* - 请确认 `__GOLD__` 与 `__TEST__` 均为二分类且编码一致，并明确哪个取值代表“阳性”。
* - 建议同时报告四格表计数（TP/FP/FN/TN），并显式处理零单元格（部分指标可能不可定义）。
* - 建议结合置信区间与患病率语境解读；小样本下点估计易误导。
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

display "SS_TASK_BEGIN|id=TM02|level=L1|title=Diagnostic_Test"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"
local test = "__TEST__"
local gold = "__GOLD__"

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
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate gold/test variables are binary numeric with two distinct levels.
* ZH: 校验金标准/检测变量为数值型二分类（仅两个取值）。
capture confirm variable `gold'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `gold'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `test'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `test'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `gold'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `gold'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `test'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `test'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly levelsof `gold' if !missing(`gold'), local(g_levels)
quietly levelsof `test' if !missing(`test'), local(t_levels)
local n_g : word count `g_levels'
local n_t : word count `t_levels'
display "SS_METRIC|name=n_gold_levels|value=`n_g'"
display "SS_METRIC|name=n_test_levels|value=`n_t'"
if (`n_g' != 2) | (`n_t' != 2) {
    display "SS_RC|code=2002|cmd=validate_binary_vars|msg=non_binary_detected|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM02|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2002
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Compute 2x2 diagnostic accuracy metrics (no SSC dependency).
* ZH: 计算四格表诊断效能指标（不依赖 SSC）。

local g0 : word 1 of `g_levels'
local g1 : word 2 of `g_levels'
local t0 : word 1 of `t_levels'
local t1 : word 2 of `t_levels'

count if `gold' == `g1' & `test' == `t1'
local tp = r(N)
count if `gold' == `g0' & `test' == `t1'
local fp = r(N)
count if `gold' == `g1' & `test' == `t0'
local fn = r(N)
count if `gold' == `g0' & `test' == `t0'
local tn = r(N)

display "SS_METRIC|name=tp|value=`tp'"
display "SS_METRIC|name=fp|value=`fp'"
display "SS_METRIC|name=fn|value=`fn'"
display "SS_METRIC|name=tn|value=`tn'"

local sens = .
local spec = .
local ppv = .
local npv = .
local plr = .
local nlr = .

local denom_sens = `tp' + `fn'
if `denom_sens' > 0 {
    local sens = `tp' / `denom_sens'
}
if `denom_sens' == 0 {
    display "SS_RC|code=2004|cmd=calc_sensitivity|msg=undefined_due_to_zero_denominator|severity=warn"
}
local denom_spec = `tn' + `fp'
if `denom_spec' > 0 {
    local spec = `tn' / `denom_spec'
}
if `denom_spec' == 0 {
    display "SS_RC|code=2004|cmd=calc_specificity|msg=undefined_due_to_zero_denominator|severity=warn"
}
local denom_ppv = `tp' + `fp'
if `denom_ppv' > 0 {
    local ppv = `tp' / `denom_ppv'
}
if `denom_ppv' == 0 {
    display "SS_RC|code=2004|cmd=calc_ppv|msg=undefined_due_to_zero_denominator|severity=warn"
}
local denom_npv = `tn' + `fn'
if `denom_npv' > 0 {
    local npv = `tn' / `denom_npv'
}
if `denom_npv' == 0 {
    display "SS_RC|code=2004|cmd=calc_npv|msg=undefined_due_to_zero_denominator|severity=warn"
}

if (`spec' < .) & (`spec' < 1) {
    local plr = `sens' / (1 - `spec')
}
if (`spec' < .) & (`spec' == 1) {
    display "SS_RC|code=2004|cmd=calc_plr|msg=undefined_due_to_specificity_one|severity=warn"
}
if (`spec' < .) & (`spec' > 0) {
    local nlr = (1 - `sens') / `spec'
}
if (`spec' < .) & (`spec' == 0) {
    display "SS_RC|code=2004|cmd=calc_nlr|msg=undefined_due_to_specificity_zero|severity=warn"
}

display "SS_METRIC|name=sensitivity|value=`sens'"
display "SS_METRIC|name=specificity|value=`spec'"
display "SS_METRIC|name=ppv|value=`ppv'"
display "SS_METRIC|name=npv|value=`npv'"

preserve
clear
set obs 1
gen double sens = `sens'
gen double spec = `spec'
gen double ppv = `ppv'
gen double npv = `npv'
gen double plr = `plr'
gen double nlr = `nlr'
export delimited using "table_TM02_diag.csv", replace
display "SS_OUTPUT_FILE|file=table_TM02_diag.csv|type=table|desc=diag_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM02_diag.dta", replace
display "SS_OUTPUT_FILE|file=data_TM02_diag.dta|type=data|desc=diag_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=sensitivity|value=`sens'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM02|status=ok|elapsed_sec=`elapsed'"
log close
