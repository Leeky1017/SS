* ==============================================================================
* SS_TEMPLATE: id=TM12  level=L1  module=M  title="Stratified Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TM12_mh.csv type=table desc="MH results"
*   - data_TM12_mh.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Mantel-Haenszel pooled estimates assume a common effect across strata; check for interaction/heterogeneity when plausible.
* - Ensure stratification variable is meaningful and not too sparse; sparse strata can destabilize estimates.
* - Report stratum-specific counts/effects when needed for transparency.
* 最佳实践审查（ZH）:
* - MH 汇总假设各层效应一致；若存在交互/异质性，应先检验或分层报告。
* - 分层变量不宜过于稀疏；稀疏层会导致估计不稳定。
* - 建议在需要时报告各层计数/效应以增强透明度。
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

display "SS_TASK_BEGIN|id=TM12|level=L1|title=Stratified_Analysis"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local outcome = "__OUTCOME__"
local exposure = "__EXPOSURE__"
local strata = "__STRATA__"

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
    display "SS_TASK_END|id=TM12|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM12|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate binary outcome/exposure and strata existence.
* ZH: 校验结局/暴露为二分类，且分层变量存在。
local required_vars "`outcome' `exposure' `strata'"
foreach v of local required_vars {
    capture confirm variable `v'
    if _rc {
        local rc = _rc
        display "SS_RC|code=`rc'|cmd=confirm variable `v'|msg=var_not_found|severity=fail"
        timer off 1
        quietly timer list 1
        local elapsed = r(t1)
        display "SS_TASK_END|id=TM12|status=fail|elapsed_sec=`elapsed'"
        log close
        exit `rc'
    }
}
capture confirm numeric variable `outcome'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `outcome'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM12|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM12|status=fail|elapsed_sec=`elapsed'"
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
    display "SS_TASK_END|id=TM12|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2002
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* EN: Mantel-Haenszel pooled estimate via cc, by(strata).
* ZH: 使用 cc 按 strata 分层并给出 MH 汇总。
capture noisily cc `outcome' `exposure', by(`strata')
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=cc_by|msg=mh_failed|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM12|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
local or_mh = r(or_mh)
local chi2_mh = r(chi2_mh)
local p_mh = r(p_mh)
display "SS_METRIC|name=mh_or|value=`or_mh'"
display "SS_METRIC|name=mh_chi2|value=`chi2_mh'"

preserve
clear
set obs 1
gen double or_mh = `or_mh'
gen double chi2_mh = `chi2_mh'
gen double p_mh = `p_mh'
export delimited using "table_TM12_mh.csv", replace
display "SS_OUTPUT_FILE|file=table_TM12_mh.csv|type=table|desc=mh_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM12_mh.dta", replace
display "SS_OUTPUT_FILE|file=data_TM12_mh.dta|type=data|desc=mh_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mh_or|value=`or_mh'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM12|status=ok|elapsed_sec=`elapsed'"
log close
