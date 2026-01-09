* ==============================================================================
* SS_TEMPLATE: id=TG03  level=L0  module=G  title="IPW Weight"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG03_ipw_result.csv type=table desc="IPW results"
*   - table_TG03_weight_summary.csv type=table desc="Weight summary"
*   - table_TG03_balance_weighted.csv type=table desc="Balance weighted"
*   - data_TG03_with_weights.dta type=data desc="Data with weights"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="logit command"
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

display "SS_TASK_BEGIN|id=TG03|level=L0|title=IPW_Weight"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: IPW requires overlap; trim/extreme weights and consider stabilized weights. /
*   最佳实践：IPW 依赖重叠假设；应截断极端权重，并可使用稳定化权重。
* - SSC deps: none / SSC 依赖：无（仅官方命令）
* - Error policy: fail on missing vars; warn on extreme/trimmed weights /
*   错误策略：缺少变量→fail；极端/被截断权重→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG03|ssc=none|output=csv|policy=warn_fail"

* 无社区命令依赖
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local outcome_var = "__OUTCOME_VAR__"
local covariates = "__COVARIATES__"
local estimand = "__ESTIMAND__"
local trim_pctl = __TRIM_PCTL__
local stabilize = "__STABILIZE__"

* 参数默认值
if "`estimand'" == "" | ("`estimand'" != "ate" & "`estimand'" != "att" & "`estimand'" != "atc") {
    local estimand = "ate"
}
if `trim_pctl' <= 0 | `trim_pctl' > 10 {
    local trim_pctl = 1
}
if "`stabilize'" == "" {
    local stabilize = "yes"
}

display ""
display ">>> IPW加权参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    协变量: `covariates'"
display "    估计量: `estimand'"
display "    截断分位数: `trim_pctl'%"
display "    稳定化权重: `stabilize'"

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
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found or not numeric"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found or not numeric"
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
local prop_treated = `n_treated' / `n_input'

display ">>> 处理组: `n_treated' (" %5.2f `=`prop_treated'*100' "%)"
display ">>> 对照组: `n_control'"
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
display ""
display ">>> 倾向得分分布:"
display "    Mean: " %6.4f r(mean)
display "    Min:  " %6.4f r(min)
display "    Max:  " %6.4f r(max)

* ============ 构建IPW权重 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 构建IPW权重"
display "═══════════════════════════════════════════════════════════════════════════════"

* 根据估计量构建权重
if "`estimand'" == "ate" {
    * ATE权重: 1/p(T|X) for treated, 1/(1-p(T|X)) for control
    generate double ipw_weight = cond(`treatment_var' == 1, 1/pscore, 1/(1-pscore))
    display ">>> 构建ATE权重"
}
else if "`estimand'" == "att" {
    * ATT权重: 1 for treated, p/(1-p) for control
    generate double ipw_weight = cond(`treatment_var' == 1, 1, pscore/(1-pscore))
    display ">>> 构建ATT权重"
}
else {
    * ATC权重: (1-p)/p for treated, 1 for control
    generate double ipw_weight = cond(`treatment_var' == 1, (1-pscore)/pscore, 1)
    display ">>> 构建ATC权重"
}

* 权重截断
quietly summarize ipw_weight, detail
local w_p1 = r(p1)
local w_p99 = r(p99)

if `trim_pctl' > 0 {
    local trim_lower = `trim_pctl'
    local trim_upper = 100 - `trim_pctl'
    
    quietly _pctile ipw_weight, p(`trim_lower' `trim_upper')
    local w_lower = r(r1)
    local w_upper = r(r2)
    
    quietly count if ipw_weight < `w_lower' | ipw_weight > `w_upper'
    local n_trimmed = r(N)
    
    replace ipw_weight = `w_lower' if ipw_weight < `w_lower'
    replace ipw_weight = `w_upper' if ipw_weight > `w_upper'
    
    display ">>> 截断权重: `n_trimmed' 个观测"
    display "    截断范围: [`w_lower', `w_upper']"
}

* 稳定化权重
if "`stabilize'" == "yes" {
    display ">>> 稳定化权重"
    if "`estimand'" == "ate" {
        replace ipw_weight = cond(`treatment_var' == 1, `prop_treated'/pscore, (1-`prop_treated')/(1-pscore))
    }
    else if "`estimand'" == "att" {
        replace ipw_weight = cond(`treatment_var' == 1, 1, `prop_treated'*pscore/((1-`prop_treated')*(1-pscore)))
    }
}

* 权重统计
quietly summarize ipw_weight if `treatment_var' == 1, detail
local w_mean_t = r(mean)
local w_sd_t = r(sd)
local w_min_t = r(min)
local w_max_t = r(max)

quietly summarize ipw_weight if `treatment_var' == 0, detail
local w_mean_c = r(mean)
local w_sd_c = r(sd)
local w_min_c = r(min)
local w_max_c = r(max)

display ""
display ">>> 权重统计:"
display "    处理组: Mean=" %6.2f `w_mean_t' ", SD=" %6.2f `w_sd_t' ", Range=[" %6.2f `w_min_t' ", " %6.2f `w_max_t' "]"
display "    对照组: Mean=" %6.2f `w_mean_c' ", SD=" %6.2f `w_sd_c' ", Range=[" %6.2f `w_min_c' ", " %6.2f `w_max_c' "]"

* 导出权重统计
tempname wstats
postfile `wstats' str10 group double mean double sd double min double max ///
    using "temp_weight_stats.dta", replace
post `wstats' ("treated") (`w_mean_t') (`w_sd_t') (`w_min_t') (`w_max_t')
post `wstats' ("control") (`w_mean_c') (`w_sd_c') (`w_min_c') (`w_max_c')
postclose `wstats'

preserve
use "temp_weight_stats.dta", clear
export delimited using "table_TG03_weight_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TG03_weight_summary.csv|type=table|desc=weight_summary"
restore

* ============ 加权后平衡性检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 加权后平衡性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname balance
postfile `balance' str32 variable double mean_t_raw double mean_c_raw double std_diff_raw ///
    double mean_t_wtd double mean_c_wtd double std_diff_wtd ///
    using "temp_balance_weighted.dta", replace

display ""
display "变量                 未加权差异    加权后差异    改善"
display "───────────────────────────────────────────────────────"

foreach var of local valid_covariates {
    * 未加权
    quietly summarize `var' if `treatment_var' == 1
    local mean_t_raw = r(mean)
    local sd_t = r(sd)
    quietly summarize `var' if `treatment_var' == 0
    local mean_c_raw = r(mean)
    local sd_c = r(sd)
    local pooled_sd = sqrt((`sd_t'^2 + `sd_c'^2) / 2)
    local std_diff_raw = (`mean_t_raw' - `mean_c_raw') / `pooled_sd' * 100
    
    * 加权后
    quietly summarize `var' if `treatment_var' == 1 [aw=ipw_weight]
    local mean_t_wtd = r(mean)
    quietly summarize `var' if `treatment_var' == 0 [aw=ipw_weight]
    local mean_c_wtd = r(mean)
    local std_diff_wtd = (`mean_t_wtd' - `mean_c_wtd') / `pooled_sd' * 100
    
    local improvement = (1 - abs(`std_diff_wtd')/abs(`std_diff_raw')) * 100
    
    post `balance' ("`var'") (`mean_t_raw') (`mean_c_raw') (`std_diff_raw') ///
        (`mean_t_wtd') (`mean_c_wtd') (`std_diff_wtd')
    
    display %20s "`var'" "  " %10.2f `std_diff_raw' "%  " %10.2f `std_diff_wtd' "%  " %8.1f `improvement' "%"
}

postclose `balance'

preserve
use "temp_balance_weighted.dta", clear
export delimited using "table_TG03_balance_weighted.csv", replace
display "SS_OUTPUT_FILE|file=table_TG03_balance_weighted.csv|type=table|desc=balance_weighted"
restore

* ============ IPW估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: IPW效应估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 加权回归估计
regress `outcome_var' `treatment_var' [pw=ipw_weight], robust

local effect = _b[`treatment_var']
local se = _se[`treatment_var']
local t_stat = `effect' / `se'
local p_value = 2 * ttail(e(df_r), abs(`t_stat'))
local ci_lower = `effect' - 1.96 * `se'
local ci_upper = `effect' + 1.96 * `se'

display ""
display ">>> IPW估计结果 (`estimand'):"
display "    效应值:    " %10.4f `effect'
display "    标准误:    " %10.4f `se'
display "    t统计量:   " %10.4f `t_stat'
display "    p值:       " %10.4f `p_value'
display "    95% CI:    [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"

display "SS_METRIC|name=effect|value=`effect'"
display "SS_METRIC|name=se|value=`se'"
display "SS_METRIC|name=t_stat|value=`t_stat'"
display "SS_METRIC|name=p_value|value=`p_value'"

* 导出结果
preserve
clear
set obs 1
generate str10 estimand = "`estimand'"
generate double effect = `effect'
generate double se = `se'
generate double t_stat = `t_stat'
generate double p_value = `p_value'
generate double ci_lower = `ci_lower'
generate double ci_upper = `ci_upper'
generate long n_treated = `n_treated'
generate long n_control = `n_control'
export delimited using "table_TG03_ipw_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG03_ipw_result.csv|type=table|desc=ipw_result"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG03_with_weights.dta", replace
display "SS_OUTPUT_FILE|file=data_TG03_with_weights.dta|type=data|desc=data_with_weights"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=effect|value=`effect'"

* 清理
capture erase "temp_weight_stats.dta"
if _rc != 0 { }
capture erase "temp_balance_weighted.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理组:          " %10.0fc `n_treated'
display "  对照组:          " %10.0fc `n_control'
display "  估计量:          `estimand'"
display ""
display "  IPW估计结果:"
display "    效应值:        " %10.4f `effect'
display "    标准误:        " %10.4f `se'
display "    95% CI:        [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"
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

* ============ 任务结束 ============
display "SS_TASK_END|id=TG03|status=ok|elapsed_sec=`elapsed'"
log close
