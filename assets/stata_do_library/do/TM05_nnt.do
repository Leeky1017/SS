* ==============================================================================
* SS_TEMPLATE: id=TM05  level=L1  module=M  title="NNT"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM05_nnt.csv type=table desc="NNT results"
*   - data_TM05_nnt.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - NNT is derived from absolute risk reduction; report baseline risk and direction (benefit vs harm).
* - Ensure outcome and treatment are binary and coded consistently; zero cells can make ARR/NN T undefined.
* - Consider confidence intervals for ARR/NNT, especially in small samples.
* 最佳实践审查（ZH）:
* - NNT 来自绝对风险差（ARR）；建议同时报告基线风险与方向（获益/伤害）。
* - 请确保结局与处理变量为二分类且编码一致；零单元格会导致 ARR/NNT 不可定义。
* - 小样本建议报告 ARR/NNT 的置信区间。
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

display "SS_TASK_BEGIN|id=TM05|level=L1|title=NNT"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local outcome = "__OUTCOME__"
local treatment = "__TREATMENT__"

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
    display "SS_TASK_END|id=TM05|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate binary variables and non-missingness for 2x2 table.
* ZH: 校验二分类变量并确保可形成四格表。
capture confirm variable `outcome'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `outcome'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `treatment'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `treatment'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM05|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `treatment'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `treatment'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
quietly levelsof `outcome' if !missing(`outcome'), local(o_levels)
quietly levelsof `treatment' if !missing(`treatment'), local(t_levels)
local n_o : word count `o_levels'
local n_t : word count `t_levels'
display "SS_METRIC|name=n_outcome_levels|value=`n_o'"
display "SS_METRIC|name=n_treatment_levels|value=`n_t'"
if (`n_o' != 2) | (`n_t' != 2) {
    display "SS_RC|code=2002|cmd=validate_binary_vars|msg=non_binary_detected|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM05|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2002
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* EN: Build 2x2 table and derive CER/EER/ARR/NNT/RR.
* ZH: 构建四格表并计算 CER/EER/ARR/NNT/RR。
tabulate `treatment' `outcome', matcell(freq)
local a = freq[2,2]
local b = freq[2,1]
local c = freq[1,2]
local d = freq[1,1]

local cer = `c' / (`c' + `d')
local eer = `a' / (`a' + `b')
local arr = `cer' - `eer'
local nnt = .
if abs(`arr') > 0 {
    local nnt = 1 / abs(`arr')
}
if abs(`arr') == 0 {
    display "SS_RC|code=2004|cmd=calc_nnt|msg=undefined_due_to_zero_arr|severity=warn"
}
local rr = `eer' / `cer'

display "SS_METRIC|name=nnt|value=`nnt'"
display "SS_METRIC|name=arr|value=`arr'"
display "SS_METRIC|name=rr|value=`rr'"

preserve
clear
set obs 1
gen double cer = `cer'
gen double eer = `eer'
gen double arr = `arr'
gen double nnt = `nnt'
gen double rr = `rr'
export delimited using "table_TM05_nnt.csv", replace
display "SS_OUTPUT_FILE|file=table_TM05_nnt.csv|type=table|desc=nnt_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM05_nnt.dta", replace
display "SS_OUTPUT_FILE|file=data_TM05_nnt.dta|type=data|desc=nnt_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=nnt|value=`nnt'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM05|status=ok|elapsed_sec=`elapsed'"
log close
