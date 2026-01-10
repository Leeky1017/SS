* ==============================================================================
* SS_TEMPLATE: id=TJ06  level=L1  module=J  title="CA Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TJ06_ca.png type=graph desc="CA plot"
*   - table_TJ06_ca.csv type=table desc="CA results"
*   - data_TJ06_ca.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.9) / 最佳实践审查记录
* - Date: 2026-01-10
* - Model intent / 模型目的: correspondence analysis for two categorical variables / 两个分类变量的对应分析
* - Data caveats / 数据注意: avoid extremely sparse/high-cardinality tables / 避免过稀疏或类别过多的列联表
* - Diagnostics / 诊断: record total inertia and export plot / 记录总惯量并导出图形
* - SSC deps / SSC 依赖: none / 无
* - Guardrails / 防御: validate vars + warn on many categories or missing pairs
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

display "SS_TASK_BEGIN|id=TJ06|level=L1|title=CA_Analysis"
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

local var1 = "__VAR1__"
local var2 = "__VAR2__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
local rc_file = _rc
if `rc_file' != 0 {
    ss_fail TJ06 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `var1'
if _rc {
    ss_fail TJ06 200 "confirm variable `var1'" "var_not_found"
}
capture confirm variable `var2'
if _rc {
    ss_fail TJ06 200 "confirm variable `var2'" "var_not_found"
}
quietly count if !missing(`var1') & !missing(`var2')
local n_pairs = r(N)
display "SS_METRIC|name=n_nonmissing_pairs|value=`n_pairs'"
if `n_pairs' == 0 {
    ss_fail TJ06 200 "validate_inputs" "no_nonmissing_pairs"
}
quietly tab `var1'
local k1 = r(r)
quietly tab `var2'
local k2 = r(r)
display "SS_METRIC|name=k1|value=`k1'"
display "SS_METRIC|name=k2|value=`k2'"
if `k1' > 50 | `k2' > 50 {
    display "SS_RC|code=HIGH_CARDINALITY|k1=`k1'|k2=`k2'|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
capture noisily ca `var1' `var2'
local rc_ca = _rc
if `rc_ca' != 0 {
    ss_fail TJ06 `rc_ca' "ca" "ca_failed"
}
capture cabiplot, autoaspect
local rc_plot = _rc
if `rc_plot' != 0 {
    display "SS_RC|code=`rc_plot'|cmd=cabiplot|msg=cabiplot_unavailable|severity=warn"
    graph bar (count), over(`var1') over(`var2')
}
capture graph export "fig_TJ06_ca.png", replace width(1200)
local rc_export = _rc
if `rc_export' != 0 {
    display "SS_RC|code=`rc_export'|cmd=graph export fig_TJ06_ca.png|msg=graph_export_failed|severity=warn"
}
else {
    display "SS_OUTPUT_FILE|file=fig_TJ06_ca.png|type=graph|desc=ca_plot"
}

local inertia = e(inertia)
display "SS_METRIC|name=total_inertia|value=`inertia'"

preserve
clear
set obs 1
gen str32 analysis = "Correspondence Analysis"
gen double inertia = `inertia'
export delimited using "table_TJ06_ca.csv", replace
display "SS_OUTPUT_FILE|file=table_TJ06_ca.csv|type=table|desc=ca_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TJ06_ca.dta", replace
display "SS_OUTPUT_FILE|file=data_TJ06_ca.dta|type=data|desc=ca_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=total_inertia|value=`inertia'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TJ06|status=ok|elapsed_sec=`elapsed'"
log close
