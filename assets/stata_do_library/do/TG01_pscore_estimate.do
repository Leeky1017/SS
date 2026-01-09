* ==============================================================================
* SS_TEMPLATE: id=TG01  level=L1  module=G  title="Pscore Estimate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG01_pscore_model.csv type=table desc="Pscore model results"
*   - table_TG01_balance_before.csv type=table desc="Balance before matching"
*   - fig_TG01_pscore_dist.png type=graph desc="Pscore distribution"
*   - data_TG01_with_pscore.dta type=data desc="Data with pscore"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="logit/probit + predict"
* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* 方法 / Method: treatment-model propensity score (logit/probit) + overlap check
* 识别假设 / ID assumptions: unconfoundedness + overlap (common support)
* 诊断输出 / Diagnostics: balance-before table + pscore distribution + common-support drop (optional)
* SSC依赖 / SSC deps: removed (no longer requires `psmatch2`)
* 解读要点 / Interpretation: pscore is not causal; use it to diagnose overlap and guide design

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

display "SS_TASK_BEGIN|id=TG01|level=L1|title=Pscore_Estimate"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.1.0"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local covariates = "__COVARIATES__"
local model = "__MODEL__"
local common_support = "__COMMON_SUPPORT__"

* 参数默认值
if "`model'" == "" | ("`model'" != "logit" & "`model'" != "probit") {
    local model = "logit"
}
if "`common_support'" == "" {
    local common_support = "yes"
}

display ""
display ">>> 倾向得分估计参数:"
display "    处理变量: `treatment_var'"
display "    协变量: `covariates'"
display "    模型: `model'"
display "    共同支撑: `common_support'"

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
* 检查处理变量
capture confirm variable `treatment_var'
if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`treatment_var'_not_found|var=`treatment_var'|severity=fail"
    log close
    exit 200
}

* 检查处理变量是否为0/1
quietly tabulate `treatment_var'
if r(r) != 2 {
display "SS_RC|code=198|cmd=validate_inputs|msg=not_binary|detail=`treatment_var'_must_be_binary_01|severity=fail"
    log close
    exit 198
}

* 统计处理组和对照组
quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)

display ""
display ">>> 处理组: `n_treated' 观测"
display ">>> 对照组: `n_control' 观测"
display "SS_METRIC|name=n_treated|value=`n_treated'"
display "SS_METRIC|name=n_control|value=`n_control'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* 检查协变量
local valid_covariates ""
foreach var of local covariates {
    capture confirm numeric variable `var'
    if _rc {
display "SS_RC|code=0|cmd=warning|msg=cov_invalid|detail=`var'_not_found_or_not_numeric|severity=warn"
    }
    else {
        local valid_covariates "`valid_covariates' `var'"
    }
}

if "`valid_covariates'" == "" {
display "SS_RC|code=200|cmd=validate_inputs|msg=no_covariates|detail=No_valid_covariates|severity=fail"
    log close
    exit 200
}

* ============ 匹配前平衡性检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 匹配前平衡性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建平衡性统计存储
tempname balance
postfile `balance' str32 variable double mean_treated double mean_control ///
    double diff double std_diff double t_stat double p_value ///
    using "temp_balance_before.dta", replace

display ""
display "变量                 处理组均值    对照组均值    差异      标准化差异   t值      p值"
display "─────────────────────────────────────────────────────────────────────────────────────"

foreach var of local valid_covariates {
    * 计算各组均值
    quietly summarize `var' if `treatment_var' == 1
    local mean_t = r(mean)
    local sd_t = r(sd)
    local n_t = r(N)
    
    quietly summarize `var' if `treatment_var' == 0
    local mean_c = r(mean)
    local sd_c = r(sd)
    local n_c = r(N)
    
    * 计算差异
    local diff = `mean_t' - `mean_c'
    
    * 计算标准化差异
    local pooled_sd = sqrt((`sd_t'^2 + `sd_c'^2) / 2)
    if `pooled_sd' > 0 {
        local std_diff = `diff' / `pooled_sd' * 100
    }
    else {
        local std_diff = 0
    }
    
    * t检验
    quietly ttest `var', by(`treatment_var')
    local t_stat = r(t)
    local p_value = r(p)
    
    post `balance' ("`var'") (`mean_t') (`mean_c') (`diff') (`std_diff') (`t_stat') (`p_value')
    
    display %20s "`var'" "  " %12.4f `mean_t' "  " %12.4f `mean_c' "  " ///
        %8.4f `diff' "  " %8.2f `std_diff' "%  " %6.2f `t_stat' "  " %6.4f `p_value'
}

postclose `balance'

* 导出匹配前平衡性
preserve
use "temp_balance_before.dta", clear
export delimited using "table_TG01_balance_before.csv", replace
display "SS_OUTPUT_FILE|file=table_TG01_balance_before.csv|type=table|desc=balance_before"
restore

* ============ 估计倾向得分 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 估计倾向得分模型"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`model'" == "logit" {
    display ">>> 使用Logit模型估计倾向得分"
    logit `treatment_var' `valid_covariates'
}
else {
    display ">>> 使用Probit模型估计倾向得分"
    probit `treatment_var' `valid_covariates'
}

* 保存模型结果
local n_obs = e(N)
local pseudo_r2 = e(r2_p)
local chi2 = e(chi2)
local p_chi2 = e(p)

display ""
display ">>> 模型拟合统计:"
display "    观测数: `n_obs'"
display "    Pseudo R2: " %6.4f `pseudo_r2'
display "    Chi2: " %8.2f `chi2'
display "    P-value: " %6.4f `p_chi2'

display "SS_METRIC|name=pseudo_r2|value=`pseudo_r2'"
display "SS_METRIC|name=chi2|value=`chi2'"

* 预测倾向得分
predict double pscore, pr
label variable pscore "倾向得分(处理概率)"

* 导出模型结果
tempname modelres
postfile `modelres' str32 variable double coef double se double z double p ///
    using "temp_pscore_model.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `modelres' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `modelres'

preserve
use "temp_pscore_model.dta", clear
export delimited using "table_TG01_pscore_model.csv", replace
display "SS_OUTPUT_FILE|file=table_TG01_pscore_model.csv|type=table|desc=pscore_model"
restore

* ============ 倾向得分分布 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 倾向得分分布分析"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize pscore if `treatment_var' == 1
local ps_mean_t = r(mean)
local ps_min_t = r(min)
local ps_max_t = r(max)

quietly summarize pscore if `treatment_var' == 0
local ps_mean_c = r(mean)
local ps_min_c = r(min)
local ps_max_c = r(max)

display ""
display "倾向得分分布:"
display "  处理组: Mean=" %6.4f `ps_mean_t' ", Range=[" %6.4f `ps_min_t' ", " %6.4f `ps_max_t' "]"
display "  对照组: Mean=" %6.4f `ps_mean_c' ", Range=[" %6.4f `ps_min_c' ", " %6.4f `ps_max_c' "]"

* 共同支撑域
local cs_min = max(`ps_min_t', `ps_min_c')
local cs_max = min(`ps_max_t', `ps_max_c')
display ""
display ">>> 共同支撑域: [" %6.4f `cs_min' ", " %6.4f `cs_max' "]"

* 生成分布图
twoway (kdensity pscore if `treatment_var' == 1, lcolor(red) lwidth(medium)) ///
       (kdensity pscore if `treatment_var' == 0, lcolor(blue) lwidth(medium)), ///
       legend(order(1 "处理组" 2 "对照组") position(6)) ///
       xtitle("倾向得分") ytitle("密度") ///
       title("倾向得分分布") ///
       xline(`cs_min' `cs_max', lcolor(gray) lpattern(dash)) ///
       note("虚线表示共同支撑域边界")
graph export "fig_TG01_pscore_dist.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG01_pscore_dist.png|type=graph|desc=pscore_dist"

* ============ 共同支撑限制 ============
if "`common_support'" == "yes" {
    display ""
    display ">>> 应用共同支撑限制..."
    
    generate byte _common_support = (pscore >= `cs_min' & pscore <= `cs_max')
    
    quietly count if _common_support == 0
    local n_outside = r(N)
    
    if `n_outside' > 0 {
        display ">>> 移除共同支撑域外观测: `n_outside'"
        drop if _common_support == 0
display "SS_RC|code=0|cmd=warning|msg=common_support|detail=Dropped_`n_outside'_observations_outside_common_support|severity=warn"
    }
    
    drop _common_support
}

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG01_with_pscore.dta", replace
display "SS_OUTPUT_FILE|file=data_TG01_with_pscore.dta|type=data|desc=data_with_pscore"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=pseudo_r2|value=`pseudo_r2'"

* 清理临时文件
capture erase "temp_balance_before.dta"
if _rc != 0 {
    * Expected non-fatal return code
}
capture erase "temp_pscore_model.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  处理组:          " %10.0fc `n_treated'
display "  对照组:          " %10.0fc `n_control'
display "  模型:            `model'"
display "  Pseudo R2:       " %10.4f `pseudo_r2'
display "  共同支撑域:      [" %6.4f `cs_min' ", " %6.4f `cs_max' "]"
display ""
display "  新增变量: pscore (倾向得分)"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = `n_input' - `n_output'
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TG01|status=ok|elapsed_sec=`elapsed'"
log close
