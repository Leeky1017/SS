* ==============================================================================
* SS_TEMPLATE: id=TG08  level=L1  module=G  title="PSM Sensitivity"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG08_sensitivity.csv type=table desc="Sensitivity results"
*   - fig_TG08_gamma_bounds.png type=figure desc="Gamma bounds"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - rbounds source=ssc purpose="Rosenbaum bounds"
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

display "SS_TASK_BEGIN|id=TG08|level=L1|title=PSM_Sensitivity"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "rbounds"
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
display "SS_DEP_CHECK|pkg=rbounds|source=ssc|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local outcome_var = "__OUTCOME_VAR__"
local gamma_max = __GAMMA_MAX__
local gamma_step = __GAMMA_STEP__

if `gamma_max' <= 1 | `gamma_max' > 5 {
    local gamma_max = 2
}
if `gamma_step' <= 0 | `gamma_step' > 0.5 {
    local gamma_step = 0.1
}

display ""
display ">>> Rosenbaum敏感性分析参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    最大Gamma: `gamma_max'"
display "    Gamma步长: `gamma_step'"

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
foreach var in `treatment_var' `outcome_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 计算处理效应差异 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 基准处理效应"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize `outcome_var' if `treatment_var' == 1
local mean_t = r(mean)
quietly summarize `outcome_var' if `treatment_var' == 0
local mean_c = r(mean)
local diff = `mean_t' - `mean_c'

quietly ttest `outcome_var', by(`treatment_var')
local t_stat = r(t)
local p_value = r(p)

display ""
display ">>> 基准处理效应:"
display "    处理组均值: " %10.4f `mean_t'
display "    对照组均值: " %10.4f `mean_c'
display "    差异: " %10.4f `diff'
display "    t统计量: " %10.4f `t_stat'
display "    p值: " %10.4f `p_value'

display "SS_METRIC|name=effect|value=`diff'"
display "SS_METRIC|name=p_value|value=`p_value'"

* ============ Rosenbaum边界分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Rosenbaum边界分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建结果存储
tempname sensitivity
postfile `sensitivity' double gamma double p_upper double p_lower str10 conclusion ///
    using "temp_sensitivity.dta", replace

display ""
display "Gamma     p-upper     p-lower     结论"
display "─────────────────────────────────────────"

* 计算配对差异（简化版本）
generate _outcome_diff = .
generate _pair_id = .

* 为处理组生成配对ID
sort `treatment_var' `outcome_var'
by `treatment_var': generate _rank = _n

* 简单配对：按排名匹配
local n_pairs = min(`n_treated', `n_control')

forvalues i = 1/`n_pairs' {
    quietly replace _pair_id = `i' if `treatment_var' == 1 & _rank == `i'
    quietly replace _pair_id = `i' if `treatment_var' == 0 & _rank == `i'
}

* 计算配对内差异
forvalues i = 1/`n_pairs' {
    quietly summarize `outcome_var' if _pair_id == `i' & `treatment_var' == 1
    local y1 = r(mean)
    quietly summarize `outcome_var' if _pair_id == `i' & `treatment_var' == 0
    local y0 = r(mean)
    quietly replace _outcome_diff = `y1' - `y0' if _pair_id == `i' & `treatment_var' == 1
}

* 进行敏感性分析
local gamma = 1
local critical_gamma = .

while `gamma' <= `gamma_max' {
    * 计算在给定gamma下的p值边界
    * 简化计算：使用Wilcoxon符号秩检验的思路
    
    quietly count if _outcome_diff > 0 & !missing(_outcome_diff)
    local n_pos = r(N)
    quietly count if _outcome_diff < 0 & !missing(_outcome_diff)
    local n_neg = r(N)
    quietly count if !missing(_outcome_diff)
    local n_diff = r(N)
    
    * 上界p值（悲观情况）
    local prob_upper = `gamma' / (1 + `gamma')
    local expected_pos = `n_diff' * `prob_upper'
    local var_pos = `n_diff' * `prob_upper' * (1 - `prob_upper')
    if `var_pos' > 0 {
        local z_upper = (`n_pos' - `expected_pos') / sqrt(`var_pos')
        local p_upper = 1 - normal(`z_upper')
    }
    else {
        local p_upper = 0.5
    }
    
    * 下界p值（乐观情况）
    local prob_lower = 1 / (1 + `gamma')
    local expected_pos_low = `n_diff' * `prob_lower'
    local var_pos_low = `n_diff' * `prob_lower' * (1 - `prob_lower')
    if `var_pos_low' > 0 {
        local z_lower = (`n_pos' - `expected_pos_low') / sqrt(`var_pos_low')
        local p_lower = 1 - normal(`z_lower')
    }
    else {
        local p_lower = 0.5
    }
    
    * 判断结论
    if `p_upper' < 0.05 {
        local conclusion = "显著"
        if `critical_gamma' == . {
            local critical_gamma = `gamma'
        }
    }
    else {
        local conclusion = "不显著"
    }
    
    post `sensitivity' (`gamma') (`p_upper') (`p_lower') ("`conclusion'")
    
    display %5.2f `gamma' "     " %8.4f `p_upper' "    " %8.4f `p_lower' "     `conclusion'"
    
    local gamma = `gamma' + `gamma_step'
}

postclose `sensitivity'

display "─────────────────────────────────────────"

* 找到临界Gamma
preserve
use "temp_sensitivity.dta", clear
quietly summarize gamma if p_upper >= 0.05
if r(N) > 0 {
    local critical_gamma = r(min) - `gamma_step'
    if `critical_gamma' < 1 {
        local critical_gamma = 1
    }
}
else {
    local critical_gamma = `gamma_max'
}
restore

display ""
display ">>> 临界Gamma值: " %5.2f `critical_gamma'
display "    解释: 当隐藏偏差使处理分配概率比达到 " %5.2f `critical_gamma' " 时，"
display "          结论将变得不显著"

display "SS_METRIC|name=critical_gamma|value=`critical_gamma'"

* 导出结果
preserve
use "temp_sensitivity.dta", clear
export delimited using "table_TG08_sensitivity.csv", replace
display "SS_OUTPUT_FILE|file=table_TG08_sensitivity.csv|type=table|desc=sensitivity"
restore

* ============ 生成图形 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成Gamma边界图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_sensitivity.dta", clear

twoway (line p_upper gamma, lcolor(red) lwidth(medium)) ///
       (line p_lower gamma, lcolor(blue) lwidth(medium)), ///
       yline(0.05, lcolor(gray) lpattern(dash)) ///
       xline(`critical_gamma', lcolor(orange) lpattern(dash)) ///
       legend(order(1 "p-upper (悲观)" 2 "p-lower (乐观)") position(6)) ///
       xtitle("Gamma (隐藏偏差)") ytitle("p值") ///
       title("Rosenbaum敏感性分析") ///
       note("水平虚线=0.05显著性水平; 垂直虚线=临界Gamma")
graph export "fig_TG08_gamma_bounds.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG08_gamma_bounds.png|type=figure|desc=gamma_bounds"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=effect|value=`diff'"
display "SS_SUMMARY|key=critical_gamma|value=`critical_gamma'"

* 清理
drop _outcome_diff _pair_id _rank
capture erase "temp_sensitivity.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG08 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  配对数:          " %10.0fc `n_pairs'
display ""
display "  基准效应:"
display "    差异:          " %10.4f `diff'
display "    p值:           " %10.4f `p_value'
display ""
display "  敏感性分析:"
display "    临界Gamma:     " %10.2f `critical_gamma'
display ""
display "  结论解读:"
if `critical_gamma' >= 2 {
    display "    结果对隐藏偏差较为稳健"
}
else if `critical_gamma' >= 1.5 {
    display "    结果对隐藏偏差中等稳健"
}
else {
    display "    结果对隐藏偏差较为敏感"
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

display "SS_TASK_END|id=TG08|status=ok|elapsed_sec=`elapsed'"
log close
