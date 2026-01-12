* ==============================================================================
* SS_TEMPLATE: id=TQ04  level=L2  module=Q  title="ADF Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ04_adf_result.csv type=table desc="ADF test results"
*   - data_TQ04_adf.dta type=data desc="Output data"
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

program define ss_fail_TQ04
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ04|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ04|level=L2|title=ADF_Test"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: unit-root results depend on lag selection and deterministic terms; use multiple tests and treat as input to modeling choices. /
*   最佳实践：单位根结论受滞后与确定性项选择影响；建议多检验并用于指导建模。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/tsset/tests; warn on time gaps /
*   错误策略：缺少输入/tsset/检验失败→fail；时间缺口→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ04|ssc=none|output=csv_dta|policy=warn_fail"

* ============ 参数设置 ============
local series_var = "__SERIES_VAR__"
local time_var = "__TIME_VAR__"
local lags = __LAGS__
local trend = "__TREND__"

if `lags' < 0 | `lags' > 20 {
    local lags = 4
}
if "`trend'" == "" {
    local trend = "drift"
}

display ""
display ">>> ADF检验参数:"
display "    检验变量: `series_var'"
display "    滞后阶数: `lags'"
display "    趋势项: `trend'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TQ04 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `series_var' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TQ04 200 "confirm variable `var'" "var_not_found"
    }
}

capture confirm numeric variable `series_var'
if _rc {
    ss_fail_TQ04 200 "confirm numeric variable `series_var'" "series_var_not_numeric"
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
    ss_fail_TQ04 `=_rc' "tsset `tsvar'" "tsset_failed"
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

* ============ ADF检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: ADF单位根检验"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily dfuller `series_var', lags(`lags') `trend'
if _rc {
    ss_fail_TQ04 `=_rc' "dfuller" "adf_failed"
}

local adf_stat = r(Zt)
local adf_p = r(p)
local n_obs = r(N)

display ""
display ">>> ADF检验 (H0: 有单位根):"
display "    t统计量: " %10.4f `adf_stat'
display "    p值: " %10.4f `adf_p'
display "    观测数: `n_obs'"

if `adf_p' < 0.05 {
    display "    结论: 拒绝H0，序列平稳"
    local conclusion = "平稳"
}
else {
    display "    结论: 不能拒绝H0，序列非平稳"
    local conclusion = "非平稳"
}

display "SS_METRIC|name=adf_stat|value=`adf_stat'"
display "SS_METRIC|name=adf_p|value=`adf_p'"

* ============ PP检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Phillips-Perron检验"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily pperron `series_var', lags(`lags') `trend'
if _rc {
    ss_fail_TQ04 `=_rc' "pperron" "pp_failed"
}

local pp_stat = r(Zt)
local pp_p = r(p)

display ""
display ">>> PP检验 (H0: 有单位根):"
display "    Z(t)统计量: " %10.4f `pp_stat'
display "    p值: " %10.4f `pp_p'

display "SS_METRIC|name=pp_stat|value=`pp_stat'"
display "SS_METRIC|name=pp_p|value=`pp_p'"

* ============ 一阶差分检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 一阶差分后ADF检验"
display "═══════════════════════════════════════════════════════════════════════════════"

capture drop d_`series_var'
local rc_drop = _rc
if `rc_drop' != 0 & `rc_drop' != 111 {
    display "SS_RC|code=`rc_drop'|cmd=drop d_`series_var'|msg=drop_failed|severity=warn"
}
generate double d_`series_var' = D.`series_var'

capture noisily dfuller d_`series_var', lags(`lags') `trend'
if _rc {
    ss_fail_TQ04 `=_rc' "dfuller diff" "adf_failed"
}

local adf_d_stat = r(Zt)
local adf_d_p = r(p)

display ""
display ">>> 差分后ADF检验:"
display "    t统计量: " %10.4f `adf_d_stat'
display "    p值: " %10.4f `adf_d_p'

if `adf_d_p' < 0.05 {
    display "    结论: 差分后平稳，原序列I(1)"
    local integration_order = 1
}
else {
    display "    结论: 差分后仍非平稳，可能I(2)"
    local integration_order = 2
}

* 导出结果
preserve
clear
set obs 3
generate str20 test = ""
generate double statistic = .
generate double p_value = .
generate str20 conclusion = ""

replace test = "ADF (level)" in 1
replace statistic = `adf_stat' in 1
replace p_value = `adf_p' in 1
replace conclusion = "`conclusion'" in 1

replace test = "PP (level)" in 2
replace statistic = `pp_stat' in 2
replace p_value = `pp_p' in 2

replace test = "ADF (diff)" in 3
replace statistic = `adf_d_stat' in 3
replace p_value = `adf_d_p' in 3
replace conclusion = "I(`integration_order')" in 3

capture export delimited using "table_TQ04_adf_result.csv", replace
if _rc {
    ss_fail_TQ04 `=_rc' "export delimited table_TQ04_adf_result.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ04_adf_result.csv|type=table|desc=adf_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TQ04_adf.dta", replace
if _rc {
    ss_fail_TQ04 `=_rc' "save data_TQ04_adf.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TQ04_adf.dta|type=data|desc=adf_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TQ04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  单位根检验:"
display "    ADF p值:       " %10.4f `adf_p'
display "    PP p值:        " %10.4f `pp_p'
display "    结论:          `conclusion'"
display "    积分阶数:      I(`integration_order')"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=adf_p|value=`adf_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ04|status=ok|elapsed_sec=`elapsed'"
log close
