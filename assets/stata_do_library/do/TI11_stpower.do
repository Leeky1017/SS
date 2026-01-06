* ==============================================================================
* SS_TEMPLATE: id=TI11  level=L0  module=I  title="Sample Size Power"
* INPUTS:
*   - (parameters only)
* OUTPUTS:
*   - table_TI11_power.csv type=table desc="Power results"
*   - data_TI11_power.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TI11|level=L0|title=Sample_Size_Power"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

display "SS_STEP_BEGIN|step=S01_load_data"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"
display "SS_STEP_BEGIN|step=S02_validate_inputs"

local hr = __HR__
local p1 = __P1__
local alpha = __ALPHA__
local power = __POWER__

if `hr' <= 0 { local hr = 0.7 }
if `p1' <= 0 | `p1' >= 1 { local p1 = 0.5 }
if `alpha' <= 0 | `alpha' >= 1 { local alpha = 0.05 }
if `power' <= 0 | `power' >= 1 { local power = 0.8 }

display ""
display ">>> 样本量计算参数:"
display "    风险比(HR): `hr'"
display "    分组比例: `p1'"
display "    显著性水平: `alpha'"
display "    检验功效: `power'"

power logrank, hratio(`hr') p1(`p1') alpha(`alpha') power(`power')
local n = r(N)
local events = r(E)

display ""
display ">>> 样本量计算结果:"
display "    所需样本量: `n'"
display "    所需事件数: `events'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
display "SS_METRIC|name=sample_size|value=`n'"
display "SS_METRIC|name=events|value=`events'"

clear
set obs 1
gen double hr = `hr'
gen double p1 = `p1'
gen double alpha = `alpha'
gen double power = `power'
gen double n = `n'
gen double events = `events'

export delimited using "table_TI11_power.csv", replace
display "SS_OUTPUT_FILE|file=table_TI11_power.csv|type=table|desc=power_results"

local n_input = 1
local n_output = 1
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TI11_power.dta", replace
display "SS_OUTPUT_FILE|file=data_TI11_power.dta|type=data|desc=power_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=sample_size|value=`n'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TI11|status=ok|elapsed_sec=`elapsed'"
log close
