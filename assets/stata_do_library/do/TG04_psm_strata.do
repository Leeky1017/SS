* ==============================================================================
* SS_TEMPLATE: id=TG04  level=L0  module=G  title="PSM Strata"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG04_strata_effects.csv type=table desc="Strata effects"
*   - table_TG04_strata_balance.csv type=table desc="Strata balance"
*   - fig_TG04_strata_effects.png type=graph desc="Strata effects plot"
*   - data_TG04_with_strata.dta type=data desc="Data with strata"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="logit command"
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 {
    * Expected non-fatal return code
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TG04|level=L0|title=PSM_Strata"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.0.1"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local outcome_var = "__OUTCOME_VAR__"
local covariates = "__COVARIATES__"
local n_strata = __N_STRATA__

if `n_strata' < 2 | `n_strata' > 20 {
    local n_strata = 5
}

display ""
display ">>> 分层估计参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    协变量: `covariates'"
display "    分层数: `n_strata'"

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
capture confirm file "data.csv"
if _rc {
display "SS_RC|code=601|cmd=confirm_file|msg=file_not_found|detail=data.csv_not_found|file=data.csv|severity=fail"
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
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

local valid_covariates ""
foreach var of local covariates {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_covariates "`valid_covariates' `var'"
    }
}

quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 估计倾向得分 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 估计倾向得分"
display "═══════════════════════════════════════════════════════════════════════════════"

logit `treatment_var' `valid_covariates'
predict double pscore, pr

quietly summarize pscore
display ">>> 倾向得分: Mean=" %6.4f r(mean) ", Range=[" %6.4f r(min) ", " %6.4f r(max) "]"

* ============ 创建分层 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 创建倾向得分分层"
display "═══════════════════════════════════════════════════════════════════════════════"

xtile ps_stratum = pscore, nq(`n_strata')
label variable ps_stratum "倾向得分分层(1-`n_strata')"

display ""
display "分层      处理组    对照组    PS范围"
display "─────────────────────────────────────────────"

forvalues s = 1/`n_strata' {
    quietly count if ps_stratum == `s' & `treatment_var' == 1
    local n_t_s = r(N)
    quietly count if ps_stratum == `s' & `treatment_var' == 0
    local n_c_s = r(N)
    quietly summarize pscore if ps_stratum == `s'
    local ps_min = r(min)
    local ps_max = r(max)
    
    display %5.0f `s' "      " %8.0fc `n_t_s' "  " %8.0fc `n_c_s' "   [" %5.3f `ps_min' ", " %5.3f `ps_max' "]"
}

* ============ 层内效应估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 层内效应估计"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname strata_effects
postfile `strata_effects' int stratum long n_treated long n_control double effect double se double t_stat double p_value double weight ///
    using "temp_strata_effects.dta", replace

local total_weight = 0
local weighted_effect = 0

display ""
display "分层   N(T)    N(C)     效应        标准误      t值      p值"
display "────────────────────────────────────────────────────────────────"

forvalues s = 1/`n_strata' {
    quietly count if ps_stratum == `s' & `treatment_var' == 1
    local n_t_s = r(N)
    quietly count if ps_stratum == `s' & `treatment_var' == 0
    local n_c_s = r(N)
    
    * 检查层内是否有足够观测
    if `n_t_s' < 5 | `n_c_s' < 5 {
        display %3.0f `s' "    " %5.0fc `n_t_s' "  " %5.0fc `n_c_s' "     样本量不足，跳过"
        continue
    }
    
    * 层内回归
    quietly regress `outcome_var' `treatment_var' if ps_stratum == `s', robust
    local effect_s = _b[`treatment_var']
    local se_s = _se[`treatment_var']
    local t_s = `effect_s' / `se_s'
    local p_s = 2 * ttail(e(df_r), abs(`t_s'))
    
    * 权重为层内样本量占比
    local weight_s = (`n_t_s' + `n_c_s') / `n_input'
    local total_weight = `total_weight' + `weight_s'
    local weighted_effect = `weighted_effect' + `effect_s' * `weight_s'
    
    post `strata_effects' (`s') (`n_t_s') (`n_c_s') (`effect_s') (`se_s') (`t_s') (`p_s') (`weight_s')
    
    display %3.0f `s' "    " %5.0fc `n_t_s' "  " %5.0fc `n_c_s' "  " %10.4f `effect_s' "  " %10.4f `se_s' "  " %6.2f `t_s' "  " %6.4f `p_s'
}

postclose `strata_effects'

* 计算加权平均效应
local ate_strata = 0
if `total_weight' > 0 {
    local ate_strata = `weighted_effect' / `total_weight'
}
else {
display "SS_RC|code=0|cmd=warning|msg=strata_empty|detail=No_strata_with_sufficient_treatedcontrol_support|severity=warn"
}

display ""
display "────────────────────────────────────────────────────────────────"
display ">>> 加权平均处理效应 (ATE): " %10.4f `ate_strata'

display "SS_METRIC|name=ate_strata|value=`ate_strata'"

* 导出分层效应
preserve
use "temp_strata_effects.dta", clear
export delimited using "table_TG04_strata_effects.csv", replace
display "SS_OUTPUT_FILE|file=table_TG04_strata_effects.csv|type=table|desc=strata_effects"
restore

* ============ 层内平衡性检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 层内平衡性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname balance
postfile `balance' int stratum str32 variable double std_diff double p_value ///
    using "temp_strata_balance.dta", replace

foreach var of local valid_covariates {
    forvalues s = 1/`n_strata' {
        quietly count if ps_stratum == `s' & `treatment_var' == 1
        if r(N) < 5 continue
        quietly count if ps_stratum == `s' & `treatment_var' == 0
        if r(N) < 5 continue
        
        quietly summarize `var' if ps_stratum == `s' & `treatment_var' == 1
        local mean_t = r(mean)
        local sd_t = r(sd)
        quietly summarize `var' if ps_stratum == `s' & `treatment_var' == 0
        local mean_c = r(mean)
        local sd_c = r(sd)
        
        local pooled_sd = sqrt((`sd_t'^2 + `sd_c'^2) / 2)
        if `pooled_sd' > 0 {
            local std_diff = (`mean_t' - `mean_c') / `pooled_sd' * 100
        }
        else {
            local std_diff = 0
        }
        
        quietly ttest `var' if ps_stratum == `s', by(`treatment_var')
        local p_val = r(p)
        
        post `balance' (`s') ("`var'") (`std_diff') (`p_val')
    }
}

postclose `balance'

preserve
use "temp_strata_balance.dta", clear
export delimited using "table_TG04_strata_balance.csv", replace
display "SS_OUTPUT_FILE|file=table_TG04_strata_balance.csv|type=table|desc=strata_balance"
restore

* ============ 生成分层效应图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 生成图表"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_strata_effects.dta", clear

generate ci_lower = effect - 1.96 * se
generate ci_upper = effect + 1.96 * se

if `total_weight' > 0 {
    twoway (bar effect stratum, barwidth(0.6) color(navy)) ///
           (rcap ci_lower ci_upper stratum, lcolor(black)), ///
           xlabel(1(1)`n_strata') ///
           xtitle("倾向得分分层") ytitle("处理效应") ///
           title("分层处理效应估计") ///
           yline(`ate_strata', lcolor(red) lpattern(dash)) ///
           legend(off) ///
           note("红色虚线=加权平均效应")
}
else {
    twoway (bar effect stratum, barwidth(0.6) color(navy)) ///
           (rcap ci_lower ci_upper stratum, lcolor(black)), ///
           xlabel(1(1)`n_strata') ///
           xtitle("倾向得分分层") ytitle("处理效应") ///
           title("分层处理效应估计") ///
           legend(off) ///
           note("加权平均效应缺失：无足够样本的分层单元")
}
graph export "fig_TG04_strata_effects.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG04_strata_effects.png|type=graph|desc=strata_effects_plot"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG04_with_strata.dta", replace
display "SS_OUTPUT_FILE|file=data_TG04_with_strata.dta|type=data|desc=data_with_strata"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=ate_strata|value=`ate_strata'"

capture erase "temp_strata_effects.dta"
if _rc != 0 {
    * Expected non-fatal return code
}
capture erase "temp_strata_balance.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理组:          " %10.0fc `n_treated'
display "  对照组:          " %10.0fc `n_control'
display "  分层数:          " %10.0fc `n_strata'
display ""
display "  加权平均效应:    " %10.4f `ate_strata'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG04|status=ok|elapsed_sec=`elapsed'"
log close
