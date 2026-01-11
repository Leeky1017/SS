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

display "SS_TASK_BEGIN|id=TQ04|level=L2|title=ADF_Test"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

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
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    display "SS_TASK_END|id=TQ04|status=fail|elapsed_sec=."
    log close
    exit 601
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
        display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|severity=fail|var=`var'"
        display "SS_TASK_END|id=TQ04|status=fail|elapsed_sec=."
        log close
        exit 200
    }
}

tsset `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ ADF检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: ADF单位根检验"
display "═══════════════════════════════════════════════════════════════════════════════"

dfuller `series_var', lags(`lags') `trend'

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

pperron `series_var', lags(`lags') `trend'

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

generate double d_`series_var' = D.`series_var'

dfuller d_`series_var', lags(`lags') `trend'

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

export delimited using "table_TQ04_adf_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TQ04_adf_result.csv|type=table|desc=adf_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TQ04_adf.dta", replace
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
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ04|status=ok|elapsed_sec=`elapsed'"
log close
