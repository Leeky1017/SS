* ==============================================================================
* SS_TEMPLATE: id=TT09  level=L1  module=T  title="Power Equivalence"
* INPUTS:
*   - (parameters only)
* OUTPUTS:
*   - table_TT09_power.csv type=table desc="Power results"
*   - data_TT09_power.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TT09|level=L1|title=Power_Equivalence"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local delta = __DELTA__
local sd = __SD__
local margin = __MARGIN__
local alpha = __ALPHA__
local power = __POWER__

if `delta' < 0 { local delta = 0 }
if `sd' <= 0 { local sd = 1 }
if `margin' <= 0 { local margin = 0.5 }
if `alpha' <= 0 | `alpha' >= 1 { local alpha = 0.05 }
if `power' <= 0 | `power' >= 1 { local power = 0.8 }

display ""
display ">>> 等价性/非劣效检验样本量参数:"
display "    真实差异(delta): `delta'"
display "    标准差: `sd'"
display "    等价界值: `margin'"
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
display "SECTION 1: 等价性检验样本量计算"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用 power twomeans 命令进行等价性检验
power twomeans 0 `delta', sd(`sd') equivalence eqdelta(`margin') alpha(`alpha') power(`power')

local n = r(N)
local n_per_group = r(N_per_group)
local actual_power = r(power)

display ""
display ">>> 样本量计算结果:"
display "    总样本量: " %8.0f `n'
display "    每组样本量: " %8.0f `n_per_group'
display "    实际功效: " %8.4f `actual_power'

display "SS_METRIC|name=sample_size|value=`n'"
display "SS_METRIC|name=n_per_group|value=`n_per_group'"
display "SS_METRIC|name=actual_power|value=`actual_power'"

* ============ 导出结果 ============
clear
set obs 1
gen double delta = `delta'
gen double sd = `sd'
gen double margin = `margin'
gen double alpha = `alpha'
gen double power = `power'
gen double sample_size = `n'
gen double n_per_group = `n_per_group'
gen double actual_power = `actual_power'

export delimited using "table_TT09_power.csv", replace
display "SS_OUTPUT_FILE|file=table_TT09_power.csv|type=table|desc=power_results"

local n_input = 1
local n_output = 1
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT09_power.dta", replace
display "SS_OUTPUT_FILE|file=data_TT09_power.dta|type=data|desc=power_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT09 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  真实差异:        " %10.4f `delta'
display "  等价界值:        " %10.4f `margin'
display "  总样本量:        " %10.0f `n'
display "  每组样本量:      " %10.0f `n_per_group'
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

display "SS_TASK_END|id=TT09|status=ok|elapsed_sec=`elapsed'"
log close
