* ==============================================================================
* SS_TEMPLATE: id=TQ03  level=L2  module=Q  title="VECM Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ03_johansen.csv type=table desc="Johansen test"
*   - table_TQ03_vecm_result.csv type=table desc="VECM results"
*   - data_TQ03_vecm.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
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

program define ss_fail_TQ03
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ03|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ03|level=L2|title=VECM_Model"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: VECM is appropriate only when variables are cointegrated; choose lag length carefully and interpret rank selection cautiously. /
*   最佳实践：VECM 仅在存在协整关系时适用；滞后阶与协整秩选择需谨慎。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/tsset; warn when vecrank/vec fails and produce a placeholder table /
*   错误策略：缺少输入/tsset 失败→fail；vecrank/vec 失败→warn 并输出占位结果表
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ03|ssc=none|output=csv_dta|policy=warn_fail"

* ============ 参数设置 ============
local endog_vars "__ENDOG_VARS__"
local time_var "__TIME_VAR__"
local lags = __LAGS__
local trend "__TREND__"

if `lags' < 1 | `lags' > 10 {
    local lags = 2
}
display ""
display ">>> VECM参数:"
display "    内生变量: `endog_vars'"
display "    滞后阶数: `lags'"
display "    趋势项: `trend'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TQ03 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
capture confirm variable `time_var'
if _rc {
    ss_fail_TQ03 200 "confirm variable `time_var'" "time_var_missing"
}

local valid_endog ""
foreach var of local endog_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_endog "`valid_endog' `var'"
    }
}

local n_endog : word count `valid_endog'
display "SS_METRIC|name=n_endog|value=`n_endog'"
if `n_endog' < 2 {
    ss_fail_TQ03 200 "validate endog_vars" "endog_vars_too_short"
}

local tsvar "`time_var'"
local _ss_need_index = 0
capture confirm numeric variable `time_var'
if _rc {
    local _ss_need_index = 1
    display "SS_RC|code=TIMEVAR_NOT_NUMERIC|var=`time_var'|severity=warn"
}
if `_ss_need_index' == 0 {
    capture isid `time_var'
    if _rc {
        local _ss_need_index = 1
        display "SS_RC|code=TIMEVAR_NOT_UNIQUE|var=`time_var'|severity=warn"
    }
}
if `_ss_need_index' == 1 {
    sort `time_var'
    capture drop ss_time_index
    local rc_drop = _rc
    if `rc_drop' != 0 & `rc_drop' != 111 {
        display "SS_RC|code=`rc_drop'|cmd=drop ss_time_index|msg=drop_failed|severity=warn"
    }
    gen long ss_time_index = _n
    local tsvar "ss_time_index"
    display "SS_METRIC|name=ts_timevar|value=ss_time_index"
}
capture tsset `tsvar'
if _rc {
    ss_fail_TQ03 `=_rc' "tsset `tsvar'" "tsset_failed"
}
capture tsreport, report
if _rc == 0 {
    display "SS_METRIC|name=ts_n_gaps|value=`=r(N_gaps)'"
    if r(N_gaps) > 0 {
        display "SS_RC|code=TIME_GAPS|n_gaps=`=r(N_gaps)'|severity=warn"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ Johansen协整检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Johansen协整检验"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly capture vecrank `valid_endog', lags(`lags') `trend'
local rc_vecrank = _rc
if `rc_vecrank' != 0 {
    display "SS_RC|code=`rc_vecrank'|cmd=vecrank|msg=vecrank_failed_skipped|severity=warn"
    local n_coint = 0
}
else {
    local n_coint = e(r)
}

display ""
display ">>> 协整秩: `n_coint'"

display "SS_METRIC|name=n_coint|value=`n_coint'"

* 导出Johansen检验结果
preserve
clear
set obs 1
generate int cointegration_rank = `n_coint'
generate str20 trend = "`trend'"
generate int lags = `lags'
generate int rc_vecrank = `rc_vecrank'
capture export delimited using "table_TQ03_johansen.csv", replace
if _rc {
    ss_fail_TQ03 `=_rc' "export delimited table_TQ03_johansen.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ03_johansen.csv|type=table|desc=johansen_test"
restore

* ============ VECM估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: VECM估计"
display "═══════════════════════════════════════════════════════════════════════════════"

if `n_coint' > 0 {
    capture noisily vec `valid_endog', lags(`lags') rank(`n_coint') `trend'
    local rc_vec = _rc
    if `rc_vec' != 0 {
        display "SS_RC|code=`rc_vec'|cmd=vec|msg=vec_failed_skipped|severity=warn"
        local n_coint = 0
    }
}

if `n_coint' > 0 {
    
    local ll = e(ll)
    
    display ""
    display ">>> VECM拟合:"
    display "    对数似然: " %12.4f `ll'
    display "    协整秩: `n_coint'"
    
    display "SS_METRIC|name=ll|value=`ll'"
    
    * 导出结果
    tempname vecm_results
    postfile `vecm_results' str32 parameter double coef double se double z double p ///
        using "temp_vecm_results.dta", replace
    
    matrix b = e(b)
    matrix V = e(V)
    local varnames : colnames b
    local nvars : word count `varnames'
    
    forvalues i = 1/`nvars' {
        local vname : word `i' of `varnames'
        local coef = b[1, `i']
        local se = sqrt(V[`i', `i'])
        if `se' > 0 {
            local z = `coef' / `se'
            local p = 2 * (1 - normal(abs(`z')))
        }
        else {
            local z = .
            local p = .
        }
        post `vecm_results' ("`vname'") (`coef') (`se') (`z') (`p')
    }
    
    postclose `vecm_results'
    
    preserve
    use "temp_vecm_results.dta", clear
    capture export delimited using "table_TQ03_vecm_result.csv", replace
    if _rc {
        ss_fail_TQ03 `=_rc' "export delimited table_TQ03_vecm_result.csv" "export_failed"
    }
    display "SS_OUTPUT_FILE|file=table_TQ03_vecm_result.csv|type=table|desc=vecm_results"
    restore
    
    capture erase "temp_vecm_results.dta"
    local rc_last = _rc
    if `rc_last' != 0 {
        display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
    }
}
else {
    display ""
    display ">>> 无协整关系，建议使用VAR模型"
    display "SS_RC|code=0|cmd=vec|msg=no_cointegration_or_vecm_skipped|severity=warn"

    preserve
    clear
    set obs 1
    gen str32 parameter = "status"
    gen double coef = .
    gen double se = .
    gen double z = .
    gen double p = .
    gen str80 note = "no_cointegration_or_vecm_skipped"
    capture export delimited using "table_TQ03_vecm_result.csv", replace
    if _rc {
        ss_fail_TQ03 `=_rc' "export delimited table_TQ03_vecm_result.csv" "export_failed"
    }
    display "SS_OUTPUT_FILE|file=table_TQ03_vecm_result.csv|type=table|desc=vecm_results"
    restore
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TQ03_vecm.dta", replace
if _rc {
    ss_fail_TQ03 `=_rc' "save data_TQ03_vecm.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TQ03_vecm.dta|type=data|desc=vecm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TQ03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  协整秩:          " %10.0fc `n_coint'
display "  滞后阶数:        " %10.0fc `lags'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_coint|value=`n_coint'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ03|status=ok|elapsed_sec=`elapsed'"
log close
