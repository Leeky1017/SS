* ==============================================================================
* SS_TEMPLATE: id=TJ05  level=L1  module=J  title="MDS Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TJ05_mds.png type=graph desc="MDS plot"
*   - data_TJ05_mds.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.9) / 最佳实践审查记录
* - Date: 2026-01-10
* - Model intent / 模型目的: MDS visualization via `mds` / 多维尺度分析可视化
* - Data caveats / 数据注意: ensure variables represent a suitable dissimilarity structure / 需确保输入变量适合表示“距离/相异度”结构
* - Diagnostics / 诊断: record stress value / 记录 stress 指标
* - SSC deps / SSC 依赖: none / 无
* - Guardrails / 防御: validate var list + warn on missing rows
* ------------------------------------------------------------------------------
capture log close _all
local rc_log_close = _rc
if `rc_log_close' != 0 {
    display "SS_RC|code=`rc_log_close'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TJ05|level=L1|title=MDS_Analysis"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

program define ss_fail
    args template_id code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=`template_id'|status=fail|elapsed_sec=`elapsed'"
    capture log close
    local rc_log = _rc
    if `rc_log' != 0 {
        display "SS_RC|code=`rc_log'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

local vars = "__VARS__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TJ05 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
local n_vars : word count `vars'
display "SS_METRIC|name=n_vars|value=`n_vars'"
if `n_vars' < 2 {
    ss_fail TJ05 200 "vars" "vars_empty_or_too_short"
}
foreach v of local vars {
    capture confirm variable `v'
    if _rc {
        ss_fail TJ05 200 "confirm variable `v'" "var_not_found"
    }
}
capture egen byte ss_rowmiss = rowmiss(`vars')
local rc_rowmiss = _rc
if `rc_rowmiss' == 0 {
    quietly count if ss_rowmiss > 0
    local n_missing_rows = r(N)
    display "SS_METRIC|name=n_missing_rows|value=`n_missing_rows'"
    if `n_missing_rows' > 0 {
        display "SS_RC|code=MISSING_INPUT_ROWS|n=`n_missing_rows'|severity=warn"
    }
    drop ss_rowmiss
}
else {
    display "SS_RC|code=`rc_rowmiss'|cmd=egen rowmiss|msg=rowmiss_unavailable|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
local idvar "id"
capture confirm variable `idvar'
local rc_id = _rc
if `rc_id' != 0 {
    gen long ss_id = _n
    local idvar "ss_id"
    display "SS_RC|code=111|cmd=confirm variable id|msg=id_var_missing_created|severity=warn"
}
capture noisily mds `vars', id(`idvar')
local rc_mds = _rc
if `rc_mds' != 0 {
    ss_fail TJ05 `rc_mds' "mds" "mds_failed"
}
capture noisily mdsconfig, autoaspect
local rc_cfg = _rc
if `rc_cfg' != 0 {
    display "SS_RC|code=`rc_cfg'|cmd=mdsconfig|msg=mdsconfig_failed|severity=warn"
}
capture graph export "fig_TJ05_mds.png", replace width(1200)
local rc_export = _rc
if `rc_export' != 0 {
    display "SS_RC|code=`rc_export'|cmd=graph export fig_TJ05_mds.png|msg=graph_export_failed|severity=warn"
}
else {
    display "SS_OUTPUT_FILE|file=fig_TJ05_mds.png|type=graph|desc=mds_plot"
}

local stress = e(stress)
display "SS_METRIC|name=stress|value=`stress'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TJ05_mds.dta", replace
display "SS_OUTPUT_FILE|file=data_TJ05_mds.dta|type=data|desc=mds_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=stress|value=`stress'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TJ05|status=ok|elapsed_sec=`elapsed'"
log close
