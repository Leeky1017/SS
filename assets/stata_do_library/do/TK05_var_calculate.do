* ==============================================================================
* SS_TEMPLATE: id=TK05  level=L2  module=K  title="VaR Calculate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK05_var_result.csv type=table desc="VaR results"
*   - table_TK05_backtest.csv type=table desc="Backtest results"
*   - fig_TK05_var_plot.png type=figure desc="VaR plot"
*   - data_TK05_var.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TK05|level=L2|title=VaR_Calculate"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local confidence = __CONFIDENCE__
local horizon = __HORIZON__
local method = "__METHOD__"
local portfolio_value = __PORTFOLIO_VALUE__

if `confidence' <= 0.5 | `confidence' >= 1 {
    local confidence = 0.95
}
if `horizon' < 1 | `horizon' > 252 {
    local horizon = 1
}
if "`method'" == "" {
    local method = "parametric"
}
if `portfolio_value' <= 0 {
    local portfolio_value = 1000000
}

local alpha = 1 - `confidence'

display ""
display ">>> VaR计算参数:"
display "    收益变量: `return_var'"
display "    置信水平: " %5.1f `=`confidence'*100' "%"
display "    持有期: `horizon' 天"
display "    方法: `method'"
display "    组合价值: " %12.0fc `portfolio_value'

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
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
capture confirm numeric variable `return_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`return_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`return_var' not found"
    log close
    exit 200
}

generate t = _n
tsset t
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 收益分布分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 收益分布分析"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize `return_var', detail
local mean_ret = r(mean)
local sd_ret = r(sd)
local skew = r(skewness)
local kurt = r(kurtosis)
local p1 = r(p1)
local p5 = r(p5)

display ""
display ">>> 收益分布统计:"
display "    均值: " %12.6f `mean_ret'
display "    标准差: " %12.6f `sd_ret'
display "    偏度: " %12.4f `skew'
display "    峰度: " %12.4f `kurt'
display "    1%分位数: " %12.6f `p1'
display "    5%分位数: " %12.6f `p5'

* 正态性检验
quietly swilk `return_var'
local sw_p = r(p)
display ""
display ">>> Shapiro-Wilk正态性检验:"
display "    p值: " %10.4f `sw_p'
if `sw_p' < 0.05 {
    display "    结论: 收益分布显著偏离正态"
}

* ============ VaR计算 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: VaR计算"
display "═══════════════════════════════════════════════════════════════════════════════"

* 存储结果
tempname var_results
postfile `var_results' str20 method double var_pct double var_amount double cvar_pct double cvar_amount ///
    using "temp_var_results.dta", replace

* 1. 参数法VaR（假设正态分布）
local z_alpha = invnormal(`alpha')
local var_param = -(`mean_ret' + `z_alpha' * `sd_ret') * sqrt(`horizon')
local var_param_amt = `var_param' * `portfolio_value'

* 参数法CVaR
local cvar_param = -`mean_ret' * sqrt(`horizon') + `sd_ret' * sqrt(`horizon') * normalden(`z_alpha') / `alpha'
local cvar_param_amt = `cvar_param' * `portfolio_value'

post `var_results' ("Parametric") (`var_param') (`var_param_amt') (`cvar_param') (`cvar_param_amt')

display ""
display ">>> 参数法 (正态分布):"
display "    VaR(" %4.1f `=`confidence'*100' "%): " %10.6f `var_param' " (" %12.0fc `var_param_amt' ")"
display "    CVaR: " %10.6f `cvar_param' " (" %12.0fc `cvar_param_amt' ")"

* 2. 历史模拟法VaR
quietly _pctile `return_var', p(`=`alpha'*100')
local var_hist = -r(r1) * sqrt(`horizon')
local var_hist_amt = `var_hist' * `portfolio_value'

* 历史模拟法CVaR
quietly summarize `return_var' if `return_var' <= r(r1)
local cvar_hist = -r(mean) * sqrt(`horizon')
local cvar_hist_amt = `cvar_hist' * `portfolio_value'

post `var_results' ("Historical") (`var_hist') (`var_hist_amt') (`cvar_hist') (`cvar_hist_amt')

display ""
display ">>> 历史模拟法:"
display "    VaR(" %4.1f `=`confidence'*100' "%): " %10.6f `var_hist' " (" %12.0fc `var_hist_amt' ")"
display "    CVaR: " %10.6f `cvar_hist' " (" %12.0fc `cvar_hist_amt' ")"

* 3. 蒙特卡洛模拟法
if "`method'" == "mc" | "`method'" == "all" {
    display ""
    display ">>> 蒙特卡洛模拟..."
    
    set seed 12345
    local n_sim = 10000
    
    preserve
    clear
    set obs `n_sim'
    generate double sim_ret = rnormal(`mean_ret', `sd_ret') * sqrt(`horizon')
    
    quietly _pctile sim_ret, p(`=`alpha'*100')
    local var_mc = -r(r1)
    local var_mc_amt = `var_mc' * `portfolio_value'
    
    quietly summarize sim_ret if sim_ret <= r(r1)
    local cvar_mc = -r(mean)
    local cvar_mc_amt = `cvar_mc' * `portfolio_value'
    restore
    
    post `var_results' ("Monte Carlo") (`var_mc') (`var_mc_amt') (`cvar_mc') (`cvar_mc_amt')
    
    display ">>> 蒙特卡洛模拟法 (`n_sim'次):"
    display "    VaR(" %4.1f `=`confidence'*100' "%): " %10.6f `var_mc' " (" %12.0fc `var_mc_amt' ")"
    display "    CVaR: " %10.6f `cvar_mc' " (" %12.0fc `cvar_mc_amt' ")"
}

postclose `var_results'

display "SS_METRIC|name=var_param|value=`var_param'"
display "SS_METRIC|name=var_hist|value=`var_hist'"
display "SS_METRIC|name=cvar_param|value=`cvar_param'"

* 导出VaR结果
preserve
use "temp_var_results.dta", clear
export delimited using "table_TK05_var_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TK05_var_result.csv|type=table|desc=var_results"
restore

* ============ VaR回测 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: VaR回测"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用滚动窗口计算VaR并回测
local window = 250
local n_test = _N - `window'

if `n_test' > 50 {
    display ">>> 执行滚动VaR回测 (窗口=`window')..."
    
    generate double rolling_var = .
    generate byte var_breach = .
    
    forvalues i = `=`window'+1'/`=_N' {
        local start = `i' - `window'
        local end = `i' - 1
        
        quietly summarize `return_var' in `start'/`end'
        local roll_mean = r(mean)
        local roll_sd = r(sd)
        
        local roll_var = -(`roll_mean' + `z_alpha' * `roll_sd')
        quietly replace rolling_var = `roll_var' in `i'
        
        local actual_ret = `return_var'[`i']
        quietly replace var_breach = (`actual_ret' < -`roll_var') in `i'
    }
    
    * 计算违约率
    quietly count if var_breach == 1
    local n_breaches = r(N)
    quietly count if !missing(var_breach)
    local n_obs_test = r(N)
    local breach_rate = `n_breaches' / `n_obs_test'
    local expected_rate = `alpha'
    
    display ""
    display ">>> VaR回测结果:"
    display "    测试期数: `n_obs_test'"
    display "    违约次数: `n_breaches'"
    display "    实际违约率: " %6.2f `=`breach_rate'*100' "%"
    display "    预期违约率: " %6.2f `=`expected_rate'*100' "%"
    
    * Kupiec检验
    local lr = -2 * (ln((1-`expected_rate')^(`n_obs_test'-`n_breaches') * `expected_rate'^`n_breaches') - ///
                     ln((1-`breach_rate')^(`n_obs_test'-`n_breaches') * `breach_rate'^`n_breaches'))
    local kupiec_p = chi2tail(1, `lr')
    
    display ""
    display ">>> Kupiec检验:"
    display "    LR统计量: " %10.4f `lr'
    display "    p值: " %10.4f `kupiec_p'
    
    if `kupiec_p' >= 0.05 {
        display "    结论: VaR模型通过回测"
        local backtest_conclusion = "通过"
    }
    else {
        display "    结论: VaR模型未通过回测"
        display "SS_WARNING:VAR_BACKTEST_FAIL:VaR model failed backtest"
        local backtest_conclusion = "未通过"
    }
    
    display "SS_METRIC|name=breach_rate|value=`breach_rate'"
    display "SS_METRIC|name=kupiec_p|value=`kupiec_p'"
    
    * 导出回测结果
    preserve
    clear
    set obs 1
    generate str20 test = "Kupiec"
    generate double lr_stat = `lr'
    generate double p_value = `kupiec_p'
    generate double actual_breach = `breach_rate'
    generate double expected_breach = `expected_rate'
    generate str20 conclusion = "`backtest_conclusion'"
    export delimited using "table_TK05_backtest.csv", replace
    display "SS_OUTPUT_FILE|file=table_TK05_backtest.csv|type=table|desc=backtest_results"
    restore
}

* ============ 生成VaR图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成VaR图"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway (line `return_var' t, lcolor(navy%50) lwidth(thin)) ///
       (line rolling_var t, lcolor(red) lwidth(medium)), ///
       legend(order(1 "实际收益" 2 "VaR阈值") position(6)) ///
       xtitle("时间") ytitle("收益率") ///
       title("VaR回测: 实际收益 vs VaR阈值") ///
       note("置信水平=`=`confidence'*100'%")
graph export "fig_TK05_var_plot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK05_var_plot.png|type=figure|desc=var_plot"

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK05_var.dta", replace
display "SS_OUTPUT_FILE|file=data_TK05_var.dta|type=data|desc=var_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

capture erase "temp_var_results.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  置信水平:        " %10.1f `=`confidence'*100' "%"
display "  持有期:          " %10.0fc `horizon' " 天"
display ""
display "  VaR估计:"
display "    参数法VaR:     " %10.6f `var_param' " (" %12.0fc `var_param_amt' ")"
display "    历史法VaR:     " %10.6f `var_hist' " (" %12.0fc `var_hist_amt' ")"
display ""
display "  CVaR估计:"
display "    参数法CVaR:    " %10.6f `cvar_param'
display "    历史法CVaR:    " %10.6f `cvar_hist'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=var_param|value=`var_param'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK05|status=ok|elapsed_sec=`elapsed'"
log close
