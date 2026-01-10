* ==============================================================================
* SS_TEMPLATE: id=TK01  level=L2  module=K  title="CAPM Estimate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK01_capm_result.csv type=table desc="CAPM results"
*   - table_TK01_rolling_beta.csv type=table desc="Rolling beta"
*   - fig_TK01_sml.png type=graph desc="SML plot"
*   - data_TK01_capm.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

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

program define ss_fail_TK01
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
    display "SS_TASK_END|id=TK01|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK01|level=L2|title=CAPM_Estimate"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local market_var = "__MARKET_VAR__"
local rf_var = "__RF_VAR__"
local stock_id = "__STOCK_ID__"
local time_var = "__TIME_VAR__"
local window = __WINDOW__

if `window' <= 12 | `window' > 120 {
    local window = 60
}

display ""
display ">>> CAPM估计参数:"
display "    收益变量: `return_var'"
display "    市场收益: `market_var'"
if "`rf_var'" != "" {
    display "    无风险利率: `rf_var'"
}
display "    股票ID: `stock_id'"
display "    时间变量: `time_var'"
display "    滚动窗口: `window'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK01 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `return_var' `market_var' `stock_id' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TK01 200 confirm_variable var_not_found `var' S02_validate_inputs
    }
}

* 计算超额收益
if "`rf_var'" != "" {
    capture confirm numeric variable `rf_var'
    if !_rc {
        generate double excess_ret = `return_var' - `rf_var'
        generate double excess_mkt = `market_var' - `rf_var'
    }
    else {
        generate double excess_ret = `return_var'
        generate double excess_mkt = `market_var'
    }
}
else {
    generate double excess_ret = `return_var'
    generate double excess_mkt = `market_var'
}

* 设置面板
capture xtset `stock_id' `time_var'
local rc_xtset = _rc
if `rc_xtset' != 0 {
    display "SS_RC|code=`rc_xtset'|cmd=xtset|msg=xtset_failed_trying_fallback|severity=warn"
    sort `stock_id' `time_var'
    bysort `stock_id': gen long ss_time_index = _n
    capture xtset `stock_id' ss_time_index
    local rc_xtset2 = _rc
    if `rc_xtset2' != 0 {
        ss_fail_TK01 459 xtset xtset_failed panel_set S02_validate_inputs
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* 获取股票数量
quietly levelsof `stock_id', local(stocks)
local n_stocks : word count `stocks'
display ">>> 股票数: `n_stocks'"

* ============ CAPM时间序列估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: CAPM时间序列估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建结果存储
tempname capm_results
postfile `capm_results' long stock_id double alpha double alpha_se double beta double beta_se ///
    double r2 long n_obs ///
    using "temp_capm_results.dta", replace

display ""
display "股票ID      Alpha       t(Alpha)    Beta        t(Beta)     R2"
display "─────────────────────────────────────────────────────────────────"

foreach s of local stocks {
    quietly regress excess_ret excess_mkt if `stock_id' == `s', robust
    
    local alpha = _b[_cons]
    local alpha_se = _se[_cons]
    local alpha_t = `alpha' / `alpha_se'
    local beta = _b[excess_mkt]
    local beta_se = _se[excess_mkt]
    local beta_t = `beta' / `beta_se'
    local r2 = e(r2)
    local n = e(N)
    
    post `capm_results' (`s') (`alpha') (`alpha_se') (`beta') (`beta_se') (`r2') (`n')
    
    display %8.0f `s' "  " %10.6f `alpha' "  " %8.2f `alpha_t' "  " %10.4f `beta' "  " %8.2f `beta_t' "  " %6.4f `r2'
}

postclose `capm_results'

* 导出结果
preserve
use "temp_capm_results.dta", clear

quietly summarize beta
local avg_beta = r(mean)
local sd_beta = r(sd)

quietly summarize alpha
local avg_alpha = r(mean)
local n_sig_alpha = 0
forvalues i = 1/`=_N' {
    if abs(alpha[`i'] / alpha_se[`i']) > 1.96 {
        local n_sig_alpha = `n_sig_alpha' + 1
    }
}

display ""
display ">>> CAPM估计汇总:"
display "    平均Beta: " %6.4f `avg_beta' " (SD=" %6.4f `sd_beta' ")"
display "    平均Alpha: " %8.6f `avg_alpha'
display "    显著Alpha数: `n_sig_alpha' / `n_stocks'"

display "SS_METRIC|name=avg_beta|value=`avg_beta'"
display "SS_METRIC|name=avg_alpha|value=`avg_alpha'"

export delimited using "table_TK01_capm_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TK01_capm_result.csv|type=table|desc=capm_results"
restore

* ============ 滚动Beta估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 滚动Beta估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ">>> 计算`window'期滚动Beta..."

* 为每只股票计算滚动Beta
tempname rolling_beta
postfile `rolling_beta' long stock_id long time double rolling_beta ///
    using "temp_rolling_beta.dta", replace

foreach s of local stocks {
    preserve
    keep if `stock_id' == `s'
    sort `time_var'
    
    local T = _N
    if `T' >= `window' {
        forvalues t = `window'/`T' {
            local start = `t' - `window' + 1
            quietly regress excess_ret excess_mkt in `start'/`t'
            local rb = _b[excess_mkt]
            local time_val = `time_var'[`t']
            post `rolling_beta' (`s') (`time_val') (`rb')
        }
    }
    restore
}

postclose `rolling_beta'

preserve
use "temp_rolling_beta.dta", clear
export delimited using "table_TK01_rolling_beta.csv", replace
display "SS_OUTPUT_FILE|file=table_TK01_rolling_beta.csv|type=table|desc=rolling_beta"
restore

* ============ 生成证券市场线图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成证券市场线图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
collapse (mean) avg_ret = excess_ret, by(`stock_id')
tempfile avg_returns
save `avg_returns'
restore

preserve
use "temp_capm_results.dta", clear
rename stock_id `stock_id'
merge 1:1 `stock_id' using `avg_returns', nogenerate

* 绘制SML
twoway (scatter avg_ret beta, mcolor(navy%70) msize(small)) ///
       (lfit avg_ret beta, lcolor(red) lwidth(medium)), ///
       xtitle("Beta") ytitle("平均超额收益") ///
       title("证券市场线 (SML)") ///
       legend(order(1 "股票" 2 "拟合线") position(6))
graph export "fig_TK01_sml.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK01_sml.png|type=graph|desc=sml_plot"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK01_capm.dta", replace
display "SS_OUTPUT_FILE|file=data_TK01_capm.dta|type=data|desc=capm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* 清理
capture erase "temp_capm_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

capture erase "temp_rolling_beta.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  股票数:          " %10.0fc `n_stocks'
display ""
display "  CAPM估计:"
display "    平均Beta:      " %10.4f `avg_beta'
display "    Beta标准差:    " %10.4f `sd_beta'
display "    平均Alpha:     " %10.6f `avg_alpha'
display "    显著Alpha:     `n_sig_alpha' / `n_stocks'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=avg_beta|value=`avg_beta'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK01|status=ok|elapsed_sec=`elapsed'"
log close
