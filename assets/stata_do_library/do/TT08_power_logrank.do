* ==============================================================================
* SS_TEMPLATE: id=TT08  level=L1  module=T  title="Power Logrank"
* INPUTS:
*   - (parameters only)
* OUTPUTS:
*   - table_TT08_power.csv type=table desc="Power results"
*   - data_TT08_power.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
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

display "SS_TASK_BEGIN|id=TT08|level=L1|title=Power_Logrank"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local hr = __HR__
local p1 = __P1__
local alpha = __ALPHA__
local power = __POWER__

if `hr' <= 0 {
    local hr = 0.7
}
if `p1' <= 0 | `p1' >= 1 {
    local p1 = 0.5
}
if `alpha' <= 0 | `alpha' >= 1 {
    local alpha = 0.05
}
if `power' <= 0 | `power' >= 1 {
    local power = 0.8
}

display ""
display ">>> 生存分析样本量参数:"
display "    风险比(HR): `hr'"
display "    分组比例: `p1'"
display "    显著性水平: `alpha'"
display "    检验功效: `power'"

display "SS_STEP_BEGIN|step=S01_load_data"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 样本量计算 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 生存分析Log-rank检验样本量计算"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用 power logrank 命令
power logrank, hratio(`hr') p1(`p1') alpha(`alpha') power(`power')

local n = r(N)
local events = r(E)
local actual_power = r(power)

display ""
display ">>> 样本量计算结果:"
display "    所需样本量: " %8.0f `n'
display "    所需事件数: " %8.0f `events'
display "    实际功效: " %8.4f `actual_power'

display "SS_METRIC|name=sample_size|value=`n'"
display "SS_METRIC|name=events|value=`events'"
display "SS_METRIC|name=actual_power|value=`actual_power'"

* ============ 导出结果 ============
clear
set obs 1
gen double hr = `hr'
gen double p1 = `p1'
gen double alpha = `alpha'
gen double power = `power'
gen double sample_size = `n'
gen double events = `events'
gen double actual_power = `actual_power'

export delimited using "table_TT08_power.csv", replace
display "SS_OUTPUT_FILE|file=table_TT08_power.csv|type=table|desc=power_results"

local n_input = 1
local n_output = 1
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT08_power.dta", replace
display "SS_OUTPUT_FILE|file=data_TT08_power.dta|type=data|desc=power_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT08 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  风险比(HR):      " %10.4f `hr'
display "  分组比例:        " %10.4f `p1'
display "  所需样本量:      " %10.0f `n'
display "  所需事件数:      " %10.0f `events'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=sample_size|value=`n'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TT08|status=ok|elapsed_sec=`elapsed'"
log close
