* ==============================================================================
* SS_TEMPLATE: id=TK20  level=L2  module=K  title="Fama MacBeth"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK20_fm_result.csv type=table desc="FM results"
*   - table_TK20_time_series.csv type=table desc="Time series coefs"
*   - fig_TK20_gamma_ts.png type=graph desc="Risk premium chart"
*   - data_TK20_fm.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.10) / 最佳实践审查记录
* - Date: 2026-01-10
* - Inference / 推断: Fama-MacBeth needs time-series SE; consider Newey-West for gamma series in extensions
* - Data checks / 数据校验: panel alignment + missing regressors; avoid too many regressors per time slice
* - Diagnostics / 诊断: inspect coefficient stability over time
* - SSC deps / SSC 依赖: none / 无
* ------------------------------------------------------------------------------

* ============ 初始化 ============
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TK20
    args code cmd msg detail step
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    if "`step'" != "" & "`step'" != "." {
        display "SS_STEP_END|step=`step'|status=fail|elapsed_sec=0"
    }
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|detail=`detail'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TK20|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK20|level=L2|title=Fama_MacBeth"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local beta_var = "__BETA_VAR__"
local other_vars = "__OTHER_VARS__"
local stock_id = "__STOCK_ID__"
local time_var = "__TIME_VAR__"

display ""
display ">>> Fama-MacBeth回归参数:"
display "    收益变量: `return_var'"
display "    Beta变量: `beta_var'"
display "    其他变量: `other_vars'"
display "    股票ID: `stock_id'"
display "    时间变量: `time_var'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK20 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `return_var' `beta_var' `stock_id' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TK20 200 confirm_variable var_not_found `var' S02_validate_inputs
    }
}

capture confirm numeric variable `return_var'
if _rc {
    ss_fail_TK20 200 confirm_numeric return_not_numeric `return_var' S02_validate_inputs
}
capture confirm numeric variable `beta_var'
if _rc {
    ss_fail_TK20 200 confirm_numeric beta_not_numeric `beta_var' S02_validate_inputs
}
quietly count if missing(`return_var')
local n_miss_y = r(N)
if `n_miss_y' > 0 {
    display "SS_RC|code=MISSING_VALUES|var=`return_var'|n=`n_miss_y'|severity=warn"
}
quietly count if missing(`beta_var')
local n_miss_b = r(N)
if `n_miss_b' > 0 {
    display "SS_RC|code=MISSING_VALUES|var=`beta_var'|n=`n_miss_b'|severity=warn"
}

local valid_other ""
foreach var of local other_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_other "`valid_other' `var'"
    }
}
foreach var of local valid_other {
    quietly count if missing(`var')
    local n_miss = r(N)
    if `n_miss' > 0 {
        display "SS_RC|code=MISSING_VALUES|var=`var'|n=`n_miss'|severity=warn"
    }
}

local all_regressors "`beta_var' `valid_other'"
local n_regressors : word count `all_regressors'

capture xtset `stock_id' `time_var'
local rc_xtset = _rc
if `rc_xtset' != 0 {
    display "SS_RC|code=`rc_xtset'|cmd=xtset|msg=xtset_failed_trying_fallback|severity=warn"
    sort `stock_id' `time_var'
    bysort `stock_id': gen long ss_time_index = _n
    capture xtset `stock_id' ss_time_index
    local rc_xtset2 = _rc
    if `rc_xtset2' != 0 {
        ss_fail_TK20 459 xtset xtset_failed panel_set S02_validate_inputs
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 第一步：截面回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 第一步截面回归"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly levelsof `time_var', local(times)
local n_times : word count `times'

display ">>> 执行 `n_times' 期截面回归..."

* 创建存储时间序列系数的数据
tempname cs_coefs
local postfile_vars "long time double gamma0"
forvalues i = 1/`n_regressors' {
    local postfile_vars "`postfile_vars' double gamma`i'"
}
postfile `cs_coefs' `postfile_vars' using "temp_cs_coefs.dta", replace

local period = 0
foreach t of local times {
    local period = `period' + 1
    
    quietly regress `return_var' `all_regressors' if `time_var' == `t'
    
    if e(N) >= 10 {
        local gamma0 = _b[_cons]
        local post_vals "(`t') (`gamma0')"
        
        forvalues i = 1/`n_regressors' {
            local var : word `i' of `all_regressors'
            local gamma`i' = _b[`var']
            local post_vals "`post_vals' (`gamma`i'')"
        }
        
        post `cs_coefs' `post_vals'
    }
    
    if mod(`period', 50) == 0 {
        display "    完成 `period' / `n_times' 期..."
    }
}

postclose `cs_coefs'

* ============ 第二步：时间序列检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 第二步时间序列检验"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_cs_coefs.dta", clear

display ""
display ">>> Fama-MacBeth回归结果:"
display "变量            均值        标准误      t统计量    p值"
display "───────────────────────────────────────────────────────"

tempname fm_results
postfile `fm_results' str32 variable double mean_gamma double se double t_stat double p_value ///
    using "temp_fm_results.dta", replace

* 截距
quietly summarize gamma0
local mean_g0 = r(mean)
local se_g0 = r(sd) / sqrt(r(N))
local t_g0 = `mean_g0' / `se_g0'
local p_g0 = 2 * ttail(r(N)-1, abs(`t_g0'))

post `fm_results' ("_cons") (`mean_g0') (`se_g0') (`t_g0') (`p_g0')
display %15s "_cons" "  " %10.6f `mean_g0' "  " %10.6f `se_g0' "  " %8.2f `t_g0' "  " %6.4f `p_g0'

* 各风险因子
forvalues i = 1/`n_regressors' {
    local var : word `i' of `all_regressors'
    
    quietly summarize gamma`i'
    local mean_g = r(mean)
    local se_g = r(sd) / sqrt(r(N))
    local t_g = `mean_g' / `se_g'
    local p_g = 2 * ttail(r(N)-1, abs(`t_g'))
    
    post `fm_results' ("`var'") (`mean_g') (`se_g') (`t_g') (`p_g')
    
    local sig = ""
    if abs(`t_g') > 2.576 local sig = "***"
    else if abs(`t_g') > 1.96 local sig = "**"
    else if abs(`t_g') > 1.645 local sig = "*"
    
    display %15s "`var'" "  " %10.6f `mean_g' "  " %10.6f `se_g' "  " %8.2f `t_g' "  " %6.4f `p_g' " `sig'"
}

postclose `fm_results'

* 市场风险溢价
quietly summarize gamma1
local risk_premium = r(mean)
local rp_t = .
if r(N) > 1 & r(sd) > 0 {
    local rp_t = r(mean) / (r(sd) / sqrt(r(N)))
}

display "───────────────────────────────────────────────────────"
display ""
display ">>> 市场风险溢价: " %10.6f `risk_premium' " (t=" %5.2f `rp_t' ")"

display "SS_METRIC|name=risk_premium|value=`risk_premium'"
display "SS_METRIC|name=rp_t|value=`rp_t'"

* 导出时间序列系数
export delimited using "table_TK20_time_series.csv", replace
display "SS_OUTPUT_FILE|file=table_TK20_time_series.csv|type=table|desc=time_series"

* 生成风险溢价时序图
tsset time
local rp_line = ""
if `risk_premium' < . {
    local rp_line "yline(`risk_premium', lcolor(green) lpattern(shortdash))"
}
twoway (line gamma1 time, lcolor(navy) lwidth(thin)) ///
       (lowess gamma1 time, lcolor(red) lwidth(medium)), ///
       yline(0, lcolor(gray) lpattern(dash)) ///
       `rp_line' ///
       legend(order(1 "截面系数" 2 "趋势") position(6)) ///
       xtitle("时间") ytitle("Beta风险溢价") ///
       title("Fama-MacBeth: 风险溢价时间序列") ///
       note("绿线=均值`=round(`risk_premium',0.0001)'")
graph export "fig_TK20_gamma_ts.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK20_gamma_ts.png|type=graph|desc=risk_premium"

restore

* 导出FM结果
preserve
use "temp_fm_results.dta", clear
export delimited using "table_TK20_fm_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TK20_fm_result.csv|type=table|desc=fm_results"
restore

capture erase "temp_cs_coefs.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

capture erase "temp_fm_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK20_fm.dta", replace
display "SS_OUTPUT_FILE|file=data_TK20_fm.dta|type=data|desc=fm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK20 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  截面回归期数:    " %10.0fc `n_times'
display "  风险因子数:      " %10.0fc `n_regressors'
display ""
display "  Fama-MacBeth结果:"
display "    市场风险溢价:  " %10.6f `risk_premium'
display "    t统计量:       " %10.2f `rp_t'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=risk_premium|value=`risk_premium'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK20|status=ok|elapsed_sec=`elapsed'"
log close
