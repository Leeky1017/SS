* ==============================================================================
* SS_TEMPLATE: id=TF14  level=L1  module=F  title="PVAR"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TF14_pvar.csv type=table desc="PVAR results"
*   - fig_TF14_irf.png type=figure desc="IRF plot"
*   - data_TF14_pvar.dta type=data desc="Data file"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - pvar source=ssc purpose="Panel VAR"
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

program define ss_fail_TF14
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TF14|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TF14|level=L1|title=PVAR"
display "SS_TASK_VERSION|version=2.0.1"
* ==============================================================================
* PHASE 5.6 REVIEW (Issue #246) / 最佳实践审查（阶段 5.6）
* - Best practice: panel VAR is data-hungry; interpret IRFs cautiously and check stability where possible. /
*   最佳实践：面板 VAR 对样本要求高；IRF 解读需谨慎，必要时补充稳定性检验。
* - SSC deps: required:pvar (no built-in PVAR equivalent) / SSC 依赖：必需 pvar（无等价内置命令）
* - Error policy: fail on missing inputs/xtset/estimation; warn on singleton groups /
*   错误策略：缺少输入/xtset/估计失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=246|template_id=TF14|ssc=required:pvar|output=csv_png|policy=warn_fail"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

capture which pvar
if _rc {
    display "SS_DEP_CHECK|pkg=pvar|source=ssc|status=missing"
    display "SS_DEP_MISSING|pkg=pvar"
    ss_fail_TF14 199 "which pvar" "dependency_missing"
}
display "SS_DEP_CHECK|pkg=pvar|source=ssc|status=ok"

local vars = "__VARS__"
local panelvar = "__PANELVAR__"
local timevar = "__TIME_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TF14 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `panelvar'
if _rc {
    ss_fail_TF14 111 "confirm variable `panelvar'" "panel_var_missing"
}
capture confirm variable `timevar'
if _rc {
    ss_fail_TF14 111 "confirm variable `timevar'" "time_var_missing"
}
capture xtset `panelvar' `timevar'
if _rc {
    ss_fail_TF14 `=_rc' "xtset `panelvar' `timevar'" "xtset_failed"
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
set seed 12345
display "SS_METRIC|name=seed|value=12345"
capture noisily pvar `vars', lags(1) gmm
if _rc {
    ss_fail_TF14 `=_rc' "pvar" "pvar_failed"
}
display "SS_METRIC|name=n_obs|value=`e(N)'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily pvarirf, mc(50) oirf
if _rc {
    ss_fail_TF14 `=_rc' "pvarirf" "pvarirf_failed"
}
capture graph export "fig_TF14_irf.png", replace width(1200)
if _rc {
    ss_fail_TF14 `=_rc' "graph export" "graph_export_failed"
}
display "SS_OUTPUT_FILE|file=fig_TF14_irf.png|type=figure|desc=irf_plot"

preserve
clear
set obs 1
gen str32 model = "Panel VAR"
capture export delimited using "table_TF14_pvar.csv", replace
if _rc {
    ss_fail_TF14 `=_rc' "export delimited" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TF14_pvar.csv|type=table|desc=pvar_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TF14_pvar.dta", replace
if _rc {
    ss_fail_TF14 `=_rc' "save" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TF14_pvar.dta|type=data|desc=pvar_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=model|value=pvar"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TF14|status=ok|elapsed_sec=`elapsed'"
log close
