* ==============================================================================
* SS_TEMPLATE: id=TT06  level=L1  module=T  title="Power R-squared"
* INPUTS:
*   - (parameters only)
* OUTPUTS:
*   - table_TT06_power.csv type=table desc="Power results"
*   - data_TT06_power.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Power analysis depends on assumed effect size (R²) and model complexity; justify assumptions and run sensitivity ranges.
* - Use realistic α/power targets given multiple testing and study constraints.
* - Treat this as planning support, not a guarantee; validate with simulation for complex designs.
* 最佳实践审查（ZH）:
* - 功效分析依赖假设效应量（R²）与模型复杂度；请说明依据并做敏感性区间分析。
* - 根据多重检验与研究约束选择合理的 α/功效目标。
* - 该计算用于规划支持而非保证；复杂设计建议用仿真验证。

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

display "SS_TASK_BEGIN|id=TT06|level=L1|title=Power_Rsquared"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local rsquared_raw = "__RSQUARED__"
local n_predictors_raw = "__N_PREDICTORS__"
local alpha_raw = "__ALPHA__"
local power_raw = "__POWER__"
local rsquared = real("`rsquared_raw'")
local n_predictors = real("`n_predictors_raw'")
local alpha = real("`alpha_raw'")
local power = real("`power_raw'")

if missing(`rsquared') | `rsquared' <= 0 | `rsquared' >= 1 {
    local rsquared = 0.1
}
if missing(`n_predictors') | `n_predictors' < 1 {
    local n_predictors = 3
}
local n_predictors = floor(`n_predictors')
if missing(`alpha') | `alpha' <= 0 | `alpha' >= 1 {
    local alpha = 0.05
}
if missing(`power') | `power' <= 0 | `power' >= 1 {
    local power = 0.8
}

display ""
display ">>> 回归R²检验样本量参数:"
display "    目标R²: `rsquared'"
display "    预测变量数: `n_predictors'"
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
display "SECTION 1: 回归R²检验样本量计算"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算效应量 f² = R² / (1 - R²)
local f2 = `rsquared' / (1 - `rsquared')

* 使用 power rsquared 命令
capture noisily power rsquared `rsquared', ntested(`n_predictors') alpha(`alpha') power(`power')
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=power rsquared|msg=power_failed|severity=fail"
    log close
    exit `rc'
}

local n = r(N)
local actual_power = r(power)

display ""
display ">>> 样本量计算结果:"
display "    效应量 f²: " %8.4f `f2'
display "    所需样本量: " %8.0f `n'
display "    实际功效: " %8.4f `actual_power'

display "SS_METRIC|name=sample_size|value=`n'"
display "SS_METRIC|name=effect_size_f2|value=`f2'"
display "SS_METRIC|name=actual_power|value=`actual_power'"

* ============ 导出结果 ============
clear
set obs 1
gen double rsquared = `rsquared'
gen int n_predictors = `n_predictors'
gen double alpha = `alpha'
gen double power = `power'
gen double effect_size_f2 = `f2'
gen double sample_size = `n'
gen double actual_power = `actual_power'

export delimited using "table_TT06_power.csv", replace
display "SS_OUTPUT_FILE|file=table_TT06_power.csv|type=table|desc=power_results"

local n_input = 1
local n_output = 1
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT06_power.dta", replace
display "SS_OUTPUT_FILE|file=data_TT06_power.dta|type=data|desc=power_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT06 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  目标R²:          " %10.4f `rsquared'
display "  预测变量数:      " %10.0f `n_predictors'
display "  所需样本量:      " %10.0f `n'
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

display "SS_TASK_END|id=TT06|status=ok|elapsed_sec=`elapsed'"
log close
