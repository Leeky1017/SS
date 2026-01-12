* ==============================================================================
* SS_TEMPLATE: id=TQ12  level=L1  module=Q  title="Growth Curve"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ12_growth.csv type=table desc="Growth curve results"
*   - fig_TQ12_growth.png type=figure desc="Growth curve plot"
*   - data_TQ12_growth.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TQ12
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ12|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ12|level=L1|title=Growth_Curve"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: ensure time is correctly ordered within subject; check convergence and consider centering time for interpretability. /
*   最佳实践：确保时间在个体内部排序正确；关注收敛，并可对时间中心化以提升可解释性。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/mixed; warn on plot failures /
*   错误策略：缺少输入/mixed 失败→fail；绘图失败→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ12|ssc=none|output=csv_png_dta|policy=warn_fail"

local depvar = "__DEPVAR__"
local time_var = "__TIME_VAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"

display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TQ12 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
capture confirm variable `depvar'
if _rc {
    ss_fail_TQ12 200 "confirm variable `depvar'" "var_not_found"
}
capture confirm variable `time_var'
if _rc {
    ss_fail_TQ12 200 "confirm variable `time_var'" "var_not_found"
}
capture confirm variable `id_var'
if _rc {
    ss_fail_TQ12 200 "confirm variable `id_var'" "var_not_found"
}
local id "`id_var'"
capture confirm numeric variable `id'
if _rc {
    display "SS_RC|code=GROUP_NOT_NUMERIC|var=`id'|severity=warn"
    capture drop ss_id
    local rc_drop = _rc
    if `rc_drop' != 0 & `rc_drop' != 111 {
        display "SS_RC|code=`rc_drop'|cmd=drop ss_id|msg=drop_failed|severity=warn"
    }
    egen long ss_id = group(`id')
    local id "ss_id"
}
local tvar "`time_var'"
capture confirm numeric variable `tvar'
if _rc {
    display "SS_RC|code=TIMEVAR_NOT_NUMERIC|var=`tvar'|severity=warn"
    capture drop ss_time_index
    local rc_drop2 = _rc
    if `rc_drop2' != 0 & `rc_drop2' != 111 {
        display "SS_RC|code=`rc_drop2'|cmd=drop ss_time_index|msg=drop_failed|severity=warn"
    }
    bysort `id' (`tvar'): gen long ss_time_index = _n
    local tvar "ss_time_index"
    display "SS_METRIC|name=ts_timevar|value=ss_time_index"
}
local xlist "`tvar'"
foreach v of local indepvars {
    capture confirm numeric variable `v'
    if !_rc {
        local xlist "`xlist' `v'"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

capture mixed `depvar' `xlist' || `id': `tvar', covariance(independent)
if _rc {
    local rc_mixed = _rc
    display "SS_RC|code=`rc_mixed'|cmd=mixed|msg=mixed_fit_failed_fallback|severity=warn"
    capture mixed `depvar' `xlist' || `id':
    if _rc {
        ss_fail_TQ12 `=_rc' "mixed" "mixed_fit_failed"
    }
}
local ll = e(ll)
local n_obs = e(N)
display "SS_METRIC|name=log_likelihood|value=`ll'"
display "SS_METRIC|name=n_obs|value=`n_obs'"

capture predict yhat, fitted
if _rc {
    display "SS_RC|code=`=_rc'|cmd=predict yhat|msg=predict_failed_skip_plot|severity=warn"
}
capture twoway (scatter `depvar' `tvar', mcolor(gray%30)) ///
       (line yhat `tvar', sort lcolor(red)), ///
    title("Growth Curve Model") legend(order(1 "Observed" 2 "Fitted"))
capture graph export "fig_TQ12_growth.png", replace width(1200)
local rc_gexp = _rc
if `rc_gexp' != 0 {
    display "SS_RC|code=`rc_gexp'|cmd=graph export fig_TQ12_growth.png|msg=graph_export_failed|severity=warn"
}
display "SS_OUTPUT_FILE|file=fig_TQ12_growth.png|type=figure|desc=growth_plot"

preserve
clear
set obs 1
gen str32 model = "Growth Curve"
gen double ll = `ll'
export delimited using "table_TQ12_growth.csv", replace
if _rc {
    ss_fail_TQ12 `=_rc' "export delimited table_TQ12_growth.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ12_growth.csv|type=table|desc=growth_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
capture save "data_TQ12_growth.dta", replace
if _rc {
    ss_fail_TQ12 `=_rc' "save data_TQ12_growth.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TQ12_growth.dta|type=data|desc=growth_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

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

display "SS_TASK_END|id=TQ12|status=ok|elapsed_sec=`elapsed'"
log close
