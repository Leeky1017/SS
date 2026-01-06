* ==============================================================================
* SS_TEMPLATE: id=TG23  level=L2  module=G  title="DID TWFE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG23_twfe_comparison.csv type=table desc="TWFE comparison"
*   - fig_TG23_comparison.png type=figure desc="Comparison plot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - reghdfe source=ssc purpose="HDFE regression"
*   - did_multiplegt source=ssc purpose="Robust DID"
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

display "SS_TASK_BEGIN|id=TG23|level=L2|title=DID_TWFE"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "reghdfe did_multiplegt"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_MISSING:cmd=`dep':hint=ssc install `dep'"
        display "SS_ERROR:DEP_MISSING:`dep' is required but not installed"
        display "SS_ERR:DEP_MISSING:`dep' is required but not installed"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=reghdfe|source=ssc|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local treat_var = "__TREAT_VAR__"

display ""
display ">>> TWFE诊断参数:"
display "    结果变量: `outcome_var'"
display "    ID变量: `id_var'"
display "    时间变量: `time_var'"
display "    处理变量: `treat_var'"

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `outcome_var' `id_var' `time_var' `treat_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

* 设置面板
ss_smart_xtset `id_var' `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 标准TWFE估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 标准TWFE估计"
display "═══════════════════════════════════════════════════════════════════════════════"

reghdfe `outcome_var' `treat_var', absorb(`id_var' `time_var') vce(cluster `id_var')

local twfe_coef = _b[`treat_var']
local twfe_se = _se[`treat_var']
local twfe_t = `twfe_coef' / `twfe_se'
local twfe_p = 2 * ttail(e(df_r), abs(`twfe_t'))

display ""
display ">>> 标准TWFE估计:"
display "    系数: " %10.4f `twfe_coef'
display "    标准误: " %10.4f `twfe_se'
display "    t统计量: " %10.4f `twfe_t'
display "    p值: " %10.4f `twfe_p'

display "SS_METRIC|name=twfe_coef|value=`twfe_coef'"

* ============ de Chaisemartin-D'Haultfoeuille估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: de Chaisemartin-D'Haultfoeuille估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ">>> 执行did_multiplegt..."

did_multiplegt `outcome_var' `id_var' `time_var' `treat_var', robust_dynamic

* 提取结果
local dcdh_coef = e(effect_0)
local dcdh_se = e(se_effect_0)
if `dcdh_se' > 0 {
    local dcdh_t = `dcdh_coef' / `dcdh_se'
    local dcdh_p = 2 * (1 - normal(abs(`dcdh_t')))
}
else {
    local dcdh_t = .
    local dcdh_p = .
}

display ""
display ">>> de Chaisemartin-D'Haultfoeuille估计:"
display "    系数: " %10.4f `dcdh_coef'
display "    标准误: " %10.4f `dcdh_se'

display "SS_METRIC|name=dcdh_coef|value=`dcdh_coef'"

* ============ 负权重诊断 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: TWFE负权重诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

* 分析处理时间异质性
display ">>> 检查处理时间异质性..."

* 找出首次处理时间
bysort `id_var' (`time_var'): generate byte _ever_treated = max(`treat_var')
bysort `id_var' (`time_var'): generate _first_treat = `time_var' if `treat_var' == 1 & `treat_var'[_n-1] == 0
bysort `id_var': egen first_treat_time = min(_first_treat)

quietly levelsof first_treat_time if !missing(first_treat_time), local(treat_times)
local n_cohorts : word count `treat_times'

display ""
display ">>> 处理时间分布:"
display "    处理队列数: `n_cohorts'"

if `n_cohorts' > 1 {
    display "    存在交错处理，TWFE可能存在负权重问题"
    display "SS_WARNING:STAGGERED_TREATMENT:Multiple treatment cohorts detected"
}

* 计算简单的权重诊断
quietly count if `treat_var' == 1
local n_treated_obs = r(N)
quietly count if `treat_var' == 0
local n_control_obs = r(N)

display ""
display ">>> 处理状态分布:"
display "    处理观测: `n_treated_obs'"
display "    对照观测: `n_control_obs'"

* ============ 比较结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 估计量比较"
display "═══════════════════════════════════════════════════════════════════════════════"

local diff = `twfe_coef' - `dcdh_coef'
local pct_diff = `diff' / `dcdh_coef' * 100

display ""
display "估计量比较:"
display "─────────────────────────────────────────────────"
display "方法                    系数        标准误"
display "─────────────────────────────────────────────────"
display "标准TWFE            " %10.4f `twfe_coef' "  " %10.4f `twfe_se'
display "de Chaisemartin     " %10.4f `dcdh_coef' "  " %10.4f `dcdh_se'
display "─────────────────────────────────────────────────"
display "差异                " %10.4f `diff' " (" %5.1f `pct_diff' "%)"

if abs(`pct_diff') > 20 {
    display ""
    display "SS_WARNING:LARGE_DIFF:TWFE differs from robust estimator by >`=20'%"
    display ">>> 警告: TWFE与稳健估计量差异较大，建议使用稳健方法"
}

* 导出比较结果
preserve
clear
set obs 2
generate str30 estimator = ""
generate double coefficient = .
generate double std_error = .
generate double t_stat = .
generate double p_value = .

replace estimator = "TWFE" in 1
replace coefficient = `twfe_coef' in 1
replace std_error = `twfe_se' in 1
replace t_stat = `twfe_t' in 1
replace p_value = `twfe_p' in 1

replace estimator = "de Chaisemartin" in 2
replace coefficient = `dcdh_coef' in 2
replace std_error = `dcdh_se' in 2
replace t_stat = `dcdh_t' in 2
replace p_value = `dcdh_p' in 2

export delimited using "table_TG23_twfe_comparison.csv", replace
display "SS_OUTPUT_FILE|file=table_TG23_twfe_comparison.csv|type=table|desc=twfe_comparison"
restore

* ============ 生成对比图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 生成对比图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
clear
set obs 2
generate str30 estimator = ""
generate double coef = .
generate double ci_lower = .
generate double ci_upper = .
generate int order = .

replace estimator = "TWFE" in 1
replace coef = `twfe_coef' in 1
replace ci_lower = `twfe_coef' - 1.96 * `twfe_se' in 1
replace ci_upper = `twfe_coef' + 1.96 * `twfe_se' in 1
replace order = 1 in 1

replace estimator = "de Chaisemartin" in 2
replace coef = `dcdh_coef' in 2
replace ci_lower = `dcdh_coef' - 1.96 * `dcdh_se' in 2
replace ci_upper = `dcdh_coef' + 1.96 * `dcdh_se' in 2
replace order = 2 in 2

twoway (bar coef order, barwidth(0.6) color(navy)) ///
       (rcap ci_lower ci_upper order, lcolor(black)), ///
       xlabel(1 "TWFE" 2 "de Chaisemartin") ///
       xtitle("估计方法") ytitle("系数估计") ///
       title("TWFE vs 稳健估计量比较") ///
       yline(0, lcolor(gray) lpattern(dot)) ///
       legend(off)
graph export "fig_TG23_comparison.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG23_comparison.png|type=figure|desc=comparison"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=twfe_coef|value=`twfe_coef'"
display "SS_SUMMARY|key=dcdh_coef|value=`dcdh_coef'"

* 清理临时变量
capture drop _ever_treated _first_treat first_treat_time
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG23 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理队列数:      " %10.0fc `n_cohorts'
display ""
display "  估计结果:"
display "    TWFE:          " %10.4f `twfe_coef' " (SE=" %6.4f `twfe_se' ")"
display "    de Chaisemartin: " %10.4f `dcdh_coef' " (SE=" %6.4f `dcdh_se' ")"
display "    差异:          " %10.4f `diff' " (" %5.1f `pct_diff' "%)"
display ""
if abs(`pct_diff') > 20 {
    display "  建议: TWFE可能存在偏误，使用稳健估计量"
}
else {
    display "  结论: TWFE与稳健估计量结果接近"
}
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
local n_dropped = 0
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG23|status=ok|elapsed_sec=`elapsed'"
log close
