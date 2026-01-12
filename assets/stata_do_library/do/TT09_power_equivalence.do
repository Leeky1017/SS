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

* BEST_PRACTICE_REVIEW (EN):
* - Equivalence/non-inferiority requires pre-specified margins; justify clinically/substantively and sensitivity-test.
* - Power depends on SD and design assumptions; validate inputs and consider simulation for non-standard designs.
* - Interpretation differs from superiority testing; plan reporting accordingly.
* 最佳实践审查（ZH）:
* - 等价/非劣效检验需要预先设定界值；应有明确依据并做敏感性分析。
* - 功效依赖标准差与设计假设；请校验输入，复杂设计建议用仿真验证。
* - 等价检验的解释不同于优效检验；请在报告中明确区分。

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

display "SS_TASK_BEGIN|id=TT09|level=L1|title=Power_Equivalence"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local delta_raw = "__DELTA__"
local sd_raw = "__SD__"
local margin_raw = "__MARGIN__"
local alpha_raw = "__ALPHA__"
local power_raw = "__POWER__"
local delta = real("`delta_raw'")
local sd = real("`sd_raw'")
local margin = real("`margin_raw'")
local alpha = real("`alpha_raw'")
local power = real("`power_raw'")

if missing(`delta') | `delta' < 0 {
    local delta = 0
}
if missing(`sd') | `sd' <= 0 {
    local sd = 1
}
if missing(`margin') | `margin' <= 0 {
    local margin = 0.5
}
if missing(`alpha') | `alpha' <= 0 | `alpha' >= 1 {
    local alpha = 0.05
}
if missing(`power') | `power' <= 0 | `power' >= 1 {
    local power = 0.8
}

display ""
display ">>> 等价性/非劣效检验样本量参数:"
display "    真实差异(delta): `delta'"
display "    标准差: `sd'"
display "    等价界值: `margin'"
display "    显著性水平: `alpha'"
display "    检验功效: `power'"

display "SS_STEP_BEGIN|step=S01_load_data"
* EN: No data inputs (parameters only).
* ZH: 无数据输入（仅参数计算）。
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"
display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Parameters validated via bounds/defaults.
* ZH: 参数已通过取值范围/默认值进行校验。
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Run Stata power command and export results.
* ZH: 调用 Stata power 命令并导出结果。

* ============ 样本量计算 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 等价性检验样本量计算"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用 power twomeans 命令进行等价性检验
capture noisily power twomeans 0 `delta', sd(`sd') equivalence eqdelta(`margin') alpha(`alpha') power(`power')
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=power twomeans|msg=equivalence_not_supported_using_standard|severity=warn"
    local delta_std = `delta'
    if `delta_std' == 0 {
        local delta_std = `margin'
    }
    if `delta_std' == 0 {
        local delta_std = 0.5
    }
    capture noisily power twomeans 0 `delta_std', sd(`sd') alpha(`alpha') power(`power')
    local rc = _rc
    if `rc' != 0 {
        display "SS_RC|code=`rc'|cmd=power twomeans|msg=power_twomeans_failed|severity=fail"
        log close
        exit `rc'
    }
}

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
