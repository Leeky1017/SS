* ==============================================================================
* SS_TEMPLATE: id=TK11  level=L2  module=K  title="Market Micro"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK11_spread_stats.csv type=table desc="Spread stats"
*   - table_TK11_liquidity.csv type=table desc="Liquidity metrics"
*   - fig_TK11_spread_intraday.png type=graph desc="Intraday spread"
*   - data_TK11_micro.dta type=data desc="Output data"
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

program define ss_fail_TK11
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
    display "SS_TASK_END|id=TK11|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK11|level=L2|title=Market_Micro"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

local avg_amihud = .

* ============ 参数设置 ============
local bid_var = "__BID_VAR__"
local ask_var = "__ASK_VAR__"
local price_var = "__PRICE_VAR__"
local volume_var = "__VOLUME_VAR__"
local time_var = "__TIME_VAR__"
local stock_id = "__STOCK_ID__"

display ""
display ">>> 市场微观结构参数:"
display "    买入价: `bid_var'"
display "    卖出价: `ask_var'"
display "    成交价: `price_var'"
display "    成交量: `volume_var'"
display "    时间: `time_var'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK11 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `bid_var' `ask_var' `price_var' {
    capture confirm numeric variable `var'
    if _rc {
        ss_fail_TK11 200 confirm_variable var_not_found `var' S02_validate_inputs
    }
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 计算价差指标 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 买卖价差计算"
display "═══════════════════════════════════════════════════════════════════════════════"

* 中间价
generate double midprice = (`bid_var' + `ask_var') / 2
label variable midprice "中间价"

* 绝对买卖价差
generate double abs_spread = `ask_var' - `bid_var'
label variable abs_spread "绝对价差"

* 相对买卖价差（百分比）
generate double rel_spread = abs_spread / midprice * 100
label variable rel_spread "相对价差(%)"

* 有效价差（基于成交价）
generate double eff_spread = 2 * abs(`price_var' - midprice)
generate double eff_spread_pct = eff_spread / midprice * 100
label variable eff_spread "有效价差"
label variable eff_spread_pct "有效价差(%)"

* 实现价差
generate double realized_spread = .
quietly {
    sort `time_var'
    forvalues i = 1/`=_N-5' {
        local p = `price_var'[`i']
        local m = midprice[`i']
        local m5 = midprice[`i'+5]
        local sign = cond(`p' > `m', 1, -1)
        replace realized_spread = 2 * `sign' * (`p' - `m5') in `i'
    }
}
label variable realized_spread "实现价差"

display ""
display ">>> 价差统计:"
quietly summarize abs_spread
display "    绝对价差均值: " %10.4f r(mean)
quietly summarize rel_spread
display "    相对价差均值: " %10.4f r(mean) "%"
local avg_rel_spread = r(mean)
quietly summarize eff_spread_pct
display "    有效价差均值: " %10.4f r(mean) "%"
local avg_eff_spread = r(mean)

display "SS_METRIC|name=avg_rel_spread|value=`avg_rel_spread'"
display "SS_METRIC|name=avg_eff_spread|value=`avg_eff_spread'"

* ============ 流动性指标 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 流动性指标"
display "═══════════════════════════════════════════════════════════════════════════════"

* Amihud非流动性指标
capture confirm numeric variable `volume_var'
if !_rc {
    generate double ret = (`price_var' - `price_var'[_n-1]) / `price_var'[_n-1] if _n > 1
    generate double amihud = abs(ret) / (`volume_var' * `price_var') * 1000000 if `volume_var' > 0
    label variable amihud "Amihud非流动性"
    
    quietly summarize amihud
    local avg_amihud = r(mean)
    display ""
    display ">>> Amihud非流动性指标:"
    display "    均值: " %12.6f `avg_amihud'
    display "SS_METRIC|name=avg_amihud|value=`avg_amihud'"
}

* Roll价差估计
generate double price_change = `price_var' - `price_var'[_n-1] if _n > 1
generate double price_change_lag = price_change[_n-1] if _n > 2
quietly correlate price_change price_change_lag, covariance
local cov = r(cov_12)
if `cov' < 0 {
    local roll_spread = 2 * sqrt(-`cov')
}
else {
    local roll_spread = 0
}

display ""
display ">>> Roll价差估计:"
display "    价格变化协方差: " %12.6f `cov'
display "    Roll价差: " %10.4f `roll_spread'

display "SS_METRIC|name=roll_spread|value=`roll_spread'"

* 成交量加权价差
capture confirm numeric variable `volume_var'
if !_rc {
    quietly summarize rel_spread [aw=`volume_var']
    local vwap_spread = r(mean)
    display ""
    display ">>> 成交量加权相对价差: " %10.4f `vwap_spread' "%"
    display "SS_METRIC|name=vwap_spread|value=`vwap_spread'"
}

* ============ 导出统计结果 ============
quietly summarize abs_spread
local avg_abs_spread = r(mean)

preserve
clear
set obs 6
generate str30 metric = ""
generate double value = .

replace metric = "平均绝对价差" in 1
replace value = `avg_abs_spread' in 1

replace metric = "平均相对价差(%)" in 2
replace value = `avg_rel_spread' in 2

replace metric = "平均有效价差(%)" in 3
replace value = `avg_eff_spread' in 3

replace metric = "Roll价差" in 4
replace value = `roll_spread' in 4

replace metric = "Amihud非流动性" in 5
replace value = `avg_amihud' in 5

replace metric = "观测数" in 6
replace value = `n_input' in 6

export delimited using "table_TK11_spread_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_TK11_spread_stats.csv|type=table|desc=spread_stats"
restore

* ============ 日内模式分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 日内模式分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 提取小时
capture {
    generate hour = hh(`time_var')
    if _rc {
        generate hour = mod(floor(`time_var'/100), 24)
    }
}

* 按小时统计
preserve
collapse (mean) mean_spread = rel_spread (sd) sd_spread = rel_spread ///
    (mean) mean_volume = `volume_var' (count) n = rel_spread, by(hour)

display ""
display ">>> 日内价差模式:"
display "小时    平均价差    标准差      成交量"
display "─────────────────────────────────────────"
list hour mean_spread sd_spread mean_volume, noobs

export delimited using "table_TK11_liquidity.csv", replace
display "SS_OUTPUT_FILE|file=table_TK11_liquidity.csv|type=table|desc=liquidity"

* 生成日内价差图
generate double spread_lower = mean_spread - sd_spread
generate double spread_upper = mean_spread + sd_spread
twoway (line mean_spread hour, lcolor(navy) lwidth(medium)) ///
       (rarea spread_lower spread_upper hour, color(navy%20)), ///
       xtitle("小时") ytitle("相对价差 (%)") ///
       title("日内买卖价差模式") ///
       legend(off) ///
       note("阴影=±1标准差")
graph export "fig_TK11_spread_intraday.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK11_spread_intraday.png|type=graph|desc=intraday_spread"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK11_micro.dta", replace
display "SS_OUTPUT_FILE|file=data_TK11_micro.dta|type=data|desc=micro_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK11 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  价差指标:"
display "    平均相对价差:  " %10.4f `avg_rel_spread' "%"
display "    平均有效价差:  " %10.4f `avg_eff_spread' "%"
display "    Roll价差:      " %10.4f `roll_spread'
display ""
display "  流动性:"
display "    Amihud指标:    " %12.6f `avg_amihud'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=avg_rel_spread|value=`avg_rel_spread'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK11|status=ok|elapsed_sec=`elapsed'"
log close
