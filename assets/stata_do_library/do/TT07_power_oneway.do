* ==============================================================================
* SS_TEMPLATE: id=TT07  level=L1  module=T  title="Power Oneway ANOVA"
* INPUTS:
*   - (parameters only)
* OUTPUTS:
*   - table_TT07_power.csv type=table desc="Power results"
*   - data_TT07_power.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Power for ANOVA depends on effect size assumptions; justify f and run sensitivity ranges.
* - Check design constraints (balanced groups, unequal variances) and adjust planning accordingly.
* - Treat this as planning support; simulation may be needed for complex sampling/clustered designs.
* 最佳实践审查（ZH）:
* - ANOVA 功效依赖效应量假设；请说明 f 的依据并做敏感性区间分析。
* - 注意设计约束（是否平衡、方差是否相等）并据此调整样本量规划。
* - 该计算用于规划支持；复杂抽样/聚类设计建议使用仿真。

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

display "SS_TASK_BEGIN|id=TT07|level=L1|title=Power_Oneway_ANOVA"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local n_groups_raw = "__N_GROUPS__"
local effect_size_raw = "__EFFECT_SIZE__"
local alpha_raw = "__ALPHA__"
local power_raw = "__POWER__"
local n_groups = real("`n_groups_raw'")
local effect_size = real("`effect_size_raw'")
local alpha = real("`alpha_raw'")
local power = real("`power_raw'")

if missing(`n_groups') | `n_groups' < 2 {
    local n_groups = 3
}
local n_groups = floor(`n_groups')
if missing(`effect_size') | `effect_size' <= 0 {
    local effect_size = 0.25
}
if missing(`alpha') | `alpha' <= 0 | `alpha' >= 1 {
    local alpha = 0.05
}
if missing(`power') | `power' <= 0 | `power' >= 1 {
    local power = 0.8
}

display ""
display ">>> 单因素方差分析样本量参数:"
display "    组数: `n_groups'"
display "    效应量(f): `effect_size'"
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
display "SECTION 1: 单因素方差分析样本量计算"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算 Var(μ) = f² * σ² (假设 σ² = 1)
local var_means = `effect_size'^2

* 使用 power oneway 命令
capture noisily power oneway, ngroups(`n_groups') varerror(1) varmeans(`var_means') alpha(`alpha') power(`power')
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=power oneway|msg=power_failed|severity=fail"
    log close
    exit `rc'
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
gen int n_groups = `n_groups'
gen double effect_size = `effect_size'
gen double alpha = `alpha'
gen double power = `power'
gen double sample_size = `n'
gen double n_per_group = `n_per_group'
gen double actual_power = `actual_power'

export delimited using "table_TT07_power.csv", replace
display "SS_OUTPUT_FILE|file=table_TT07_power.csv|type=table|desc=power_results"

local n_input = 1
local n_output = 1
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT07_power.dta", replace
display "SS_OUTPUT_FILE|file=data_TT07_power.dta|type=data|desc=power_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT07 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  组数:            " %10.0f `n_groups'
display "  效应量(f):       " %10.4f `effect_size'
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

display "SS_TASK_END|id=TT07|status=ok|elapsed_sec=`elapsed'"
log close
