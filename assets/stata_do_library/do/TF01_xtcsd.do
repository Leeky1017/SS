* ==============================================================================
* SS_TEMPLATE: id=TF01  level=L0  module=F  title="XTCSD"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TF01_xtcsd.csv type=table desc="XTCSD results"
*   - data_TF01_xtcsd.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="xtcsd command"
* ==============================================================================

capture log close _all
if _rc != 0 {
    display "SS_RC|code=`=_rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TF01
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TF01|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TF01|level=L0|title=XTCSD"
display "SS_TASK_VERSION|version=2.0.1"
* ==============================================================================
* PHASE 5.6 REVIEW (Issue #246) / 最佳实践审查（阶段 5.6）
* - Best practice: Pesaran CD test after FE regression; interpret as evidence of cross-sectional dependence. /
*   最佳实践：在 FE 回归后做 Pesaran CD 检验；显著通常提示截面相关。
* - SSC deps: required:xtcsd (no safe built-in equivalent in this library) / SSC 依赖：必需 xtcsd（库内无等价内置替代）
* - Error policy: fail on missing inputs/xtset/estimation; warn on singleton groups /
*   错误策略：缺少输入/xtset/估计失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=246|template_id=TF01|ssc=required:xtcsd|output=csv|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

capture which xtcsd
if _rc {
    display "SS_DEP_CHECK|pkg=xtcsd|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=xtcsd"
    ss_fail_TF01 199 "which xtcsd" "dependency_missing"
}
display "SS_DEP_CHECK|pkg=xtcsd|source=ssc|status=ok"

local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TF01 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `panelvar'
if _rc {
    ss_fail_TF01 111 "confirm variable `panelvar'" "panel_var_missing"
}
capture confirm variable `timevar'
if _rc {
    ss_fail_TF01 111 "confirm variable `timevar'" "time_var_missing"
}
capture xtset `panelvar' `timevar'
if _rc {
    ss_fail_TF01 `=_rc' "xtset `panelvar' `timevar'" "xtset_failed"
}
tempvar _ss_n_i
bysort `panelvar': gen long `_ss_n_i' = _N
quietly count if `_ss_n_i' == 1
local n_singletons = r(N)
drop `_ss_n_i'
display "SS_METRIC|name=n_singletons|value=`n_singletons'"
if `n_singletons' > 0 {
    display "SS_RC|code=312|cmd=xtset|msg=singleton_groups_present|severity=warn"
}
capture noisily xtreg `depvar' `indepvars', fe
if _rc {
    ss_fail_TF01 `=_rc' "xtreg" "xtreg_failed"
}
capture noisily xtcsd, pesaran abs
if _rc {
    ss_fail_TF01 `=_rc' "xtcsd" "xtcsd_failed"
}

local cd_stat = r(pesaran)
local cd_p = r(p)
display "SS_METRIC|name=cd_stat|value=`cd_stat'"
display "SS_METRIC|name=cd_p|value=`cd_p'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
preserve
clear
set obs 1
gen str32 test = "Pesaran CD"
gen double stat = `cd_stat'
gen double p = `cd_p'
capture export delimited using "table_TF01_xtcsd.csv", replace
if _rc {
    ss_fail_TF01 `=_rc' "export delimited" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TF01_xtcsd.csv|type=table|desc=xtcsd_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TF01_xtcsd.dta", replace
if _rc {
    ss_fail_TF01 `=_rc' "save" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TF01_xtcsd.dta|type=data|desc=xtcsd_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=cd_stat|value=`cd_stat'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TF01|status=ok|elapsed_sec=`elapsed'"
log close
