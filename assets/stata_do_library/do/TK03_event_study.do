* ==============================================================================
* SS_TEMPLATE: id=TK03  level=L2  module=K  title="Event Study"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
*   - events.csv role=events  required=no
* OUTPUTS:
*   - table_TK03_car_result.csv type=table desc="CAR results"
*   - table_TK03_daily_ar.csv type=table desc="Daily AR"
*   - fig_TK03_car_plot.png type=graph desc="CAR plot"
*   - data_TK03_event.dta type=data desc="Output data"
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

program define ss_fail_TK03
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
    display "SS_TASK_END|id=TK03|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK03|level=L2|title=Event_Study"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local market_var = "__MARKET_VAR__"
local stock_id = "__STOCK_ID__"
local date_var = "__DATE_VAR__"
local event_window = "__EVENT_WINDOW__"
local est_window = __EST_WINDOW__

if `est_window' < 60 | `est_window' > 250 {
    local est_window = 120
}

* 解析事件窗口
local pre_event = -10
local post_event = 10
if "`event_window'" != "" {
    local comma_pos = strpos("`event_window'", ",")
    if `comma_pos' > 0 {
        local pre_event = real(substr("`event_window'", 1, `comma_pos'-1))
        local post_event = real(substr("`event_window'", `comma_pos'+1, .))
    }
}

display ""
display ">>> 事件研究参数:"
display "    收益变量: `return_var'"
display "    市场收益: `market_var'"
display "    股票ID: `stock_id'"
display "    日期变量: `date_var'"
display "    事件窗口: [`pre_event', `post_event']"
display "    估计窗口: `est_window' 天"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK03 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

tempfile returns_data
save `returns_data'

* 加载事件数据
capture confirm file "events.csv"
if _rc {
    display "SS_RC|code=0|cmd=confirm_file|msg=events_not_found_using_sample|detail=events.csv|severity=warn"
    * 创建示例事件：每只股票取样本中位时点（与 `date_var' 同尺度）
    preserve
    use `returns_data', clear
    keep `stock_id' `date_var'
    bysort `stock_id' (`date_var'): keep if _n == ceil(_N/2)
    rename `date_var' event_date
    tempfile events_data
    save `events_data'
    restore
}
else {
    preserve
    import delimited "events.csv", clear
    tempfile events_data
    save `events_data'
    restore
}

* ============ 变量检查 ============
use `returns_data', clear

foreach var in `return_var' `market_var' `stock_id' `date_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TK03 200 confirm_variable var_not_found `var' S02_validate_inputs
    }
}

* 设置面板/时间序列（供 L. 等运算）
capture xtset `stock_id' `date_var'
local rc_xtset = _rc
if `rc_xtset' != 0 {
    display "SS_RC|code=`rc_xtset'|cmd=xtset|msg=xtset_failed_trying_fallback|severity=warn"
    sort `stock_id' `date_var'
    bysort `stock_id': gen long ss_time_index = _n
    capture xtset `stock_id' ss_time_index
    local rc_xtset2 = _rc
    if `rc_xtset2' != 0 {
        ss_fail_TK03 459 xtset xtset_failed panel_set S02_validate_inputs
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 事件研究分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 计算异常收益"
display "═══════════════════════════════════════════════════════════════════════════════"

* 合并事件数据
merge m:1 `stock_id' using `events_data', keep(master match) nogenerate

* 计算相对于事件日期的天数
generate int event_time = `date_var' - event_date
label variable event_time "相对事件日期天数"

* 创建结果存储
tempname ar_results
postfile `ar_results' int event_time double ar double se double t_stat long n_obs ///
    using "temp_daily_ar.dta", replace

tempname car_results
postfile `car_results' str20 window double car double se double t_stat double p_value long n_events ///
    using "temp_car_results.dta", replace

* 对每只股票估计正常收益模型并计算AR
display ">>> 估计正常收益模型（市场模型）..."

generate double ar = .
generate double predicted_ret = .

quietly levelsof `stock_id' if event_date != ., local(event_stocks)
local n_events : word count `event_stocks'

foreach s of local event_stocks {
    * 估计窗口：事件前est_window天到事件前pre_event-1天
    capture quietly regress `return_var' `market_var' if `stock_id' == `s' & ///
        event_time < `pre_event' & event_time >= (`pre_event' - `est_window')
    local rc_reg = _rc

    if `rc_reg' == 0 & e(N) >= 30 {
        * 预测正常收益
        capture predict double temp_pred if `stock_id' == `s', xb
        local rc_pred = _rc
        if `rc_pred' == 0 {
            replace predicted_ret = temp_pred if `stock_id' == `s'
            drop temp_pred
        }

        * 计算异常收益
        replace ar = `return_var' - predicted_ret if `stock_id' == `s'
    }
}

* ============ 计算日均AR ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 日均异常收益"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "事件日    平均AR      标准误      t值        N"
display "─────────────────────────────────────────────────"

forvalues t = `pre_event'/`post_event' {
    quietly summarize ar if event_time == `t'
    
    if r(N) > 0 {
        local mean_ar = r(mean)
        local sd_ar = r(sd)
        local n = r(N)
        local se_ar = `sd_ar' / sqrt(`n')
        local t_stat = `mean_ar' / `se_ar'
        
        post `ar_results' (`t') (`mean_ar') (`se_ar') (`t_stat') (`n')
        
        local sig = ""
        if abs(`t_stat') > 2.576 local sig = "***"
        else if abs(`t_stat') > 1.96 local sig = "**"
        else if abs(`t_stat') > 1.645 local sig = "*"
        
        display %6.0f `t' "     " %10.6f `mean_ar' "  " %10.6f `se_ar' "  " %6.2f `t_stat' "`sig'  " %6.0f `n'
    }
}

postclose `ar_results'

* 导出每日AR
preserve
use "temp_daily_ar.dta", clear
export delimited using "table_TK03_daily_ar.csv", replace
display "SS_OUTPUT_FILE|file=table_TK03_daily_ar.csv|type=table|desc=daily_ar"
restore

* ============ 计算CAR ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 累计异常收益（CAR）"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算每只股票的CAR
bysort `stock_id' (event_time): generate double car = sum(ar) if event_time >= `pre_event' & event_time <= `post_event'

* 计算不同窗口的CAR
display ""
display "窗口              CAR        标准误      t值      p值"
display "───────────────────────────────────────────────────────"

* CAR[-1,1]
quietly count if event_time == 1 & car < .
if r(N) > 1 {
    quietly summarize car if event_time == 1
    local car_11 = r(mean)
    local se_11 = r(sd) / sqrt(r(N))
    local t_11 = `car_11' / `se_11'
    local p_11 = 2 * (1 - normal(abs(`t_11')))
}
else {
    local car_11 = .
    local se_11 = .
    local t_11 = .
    local p_11 = .
}
post `car_results' ("[-1,1]") (`car_11') (`se_11') (`t_11') (`p_11') (`n_events')
display "CAR[-1,1]      " %10.6f `car_11' "  " %10.6f `se_11' "  " %6.2f `t_11' "  " %6.4f `p_11'

* CAR[-5,5]
quietly count if event_time == 5 & car < .
if r(N) > 1 {
    quietly summarize car if event_time == 5
    local car_55 = r(mean)
    local se_55 = r(sd) / sqrt(r(N))
    local t_55 = `car_55' / `se_55'
    local p_55 = 2 * (1 - normal(abs(`t_55')))
}
else {
    local car_55 = .
    local se_55 = .
    local t_55 = .
    local p_55 = .
}
post `car_results' ("[-5,5]") (`car_55') (`se_55') (`t_55') (`p_55') (`n_events')
display "CAR[-5,5]      " %10.6f `car_55' "  " %10.6f `se_55' "  " %6.2f `t_55' "  " %6.4f `p_55'

* CAR[0,10]
quietly count if event_time == `post_event' & car < .
if r(N) > 1 {
    quietly summarize car if event_time == `post_event'
    local car_full = r(mean)
    local se_full = r(sd) / sqrt(r(N))
    local t_full = `car_full' / `se_full'
    local p_full = 2 * (1 - normal(abs(`t_full')))
}
else {
    local car_full = .
    local se_full = .
    local t_full = .
    local p_full = .
}
post `car_results' ("[`pre_event',`post_event']") (`car_full') (`se_full') (`t_full') (`p_full') (`n_events')
display "CAR[`pre_event',`post_event']     " %10.6f `car_full' "  " %10.6f `se_full' "  " %6.2f `t_full' "  " %6.4f `p_full'

postclose `car_results'

display "SS_METRIC|name=car_11|value=`car_11'"
display "SS_METRIC|name=car_full|value=`car_full'"

* 导出CAR结果
preserve
use "temp_car_results.dta", clear
export delimited using "table_TK03_car_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TK03_car_result.csv|type=table|desc=car_results"
restore

* ============ 生成CAR走势图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成CAR走势图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_daily_ar.dta", clear

* 计算累计AR
sort event_time
generate double cum_ar = sum(ar)
generate double ci_lower = cum_ar - 1.96 * se
generate double ci_upper = cum_ar + 1.96 * se

twoway (rarea ci_lower ci_upper event_time, color(navy%20)) ///
       (line cum_ar event_time, lcolor(navy) lwidth(medium)), ///
       xline(0, lcolor(red) lpattern(dash)) ///
       yline(0, lcolor(gray) lpattern(dot)) ///
       xtitle("相对事件日") ytitle("累计异常收益 (CAR)") ///
       title("事件研究: CAR走势") ///
       legend(off) ///
       note("红色虚线=事件日, 阴影=95%置信区间")
graph export "fig_TK03_car_plot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK03_car_plot.png|type=graph|desc=car_plot"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK03_event.dta", replace
display "SS_OUTPUT_FILE|file=data_TK03_event.dta|type=data|desc=event_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

capture erase "temp_daily_ar.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

capture erase "temp_car_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  事件数:          " %10.0fc `n_events'
display "  事件窗口:        [`pre_event', `post_event']"
display "  估计窗口:        `est_window' 天"
display ""
display "  CAR结果:"
display "    CAR[-1,1]:     " %10.6f `car_11' " (t=" %5.2f `t_11' ")"
display "    CAR[-5,5]:     " %10.6f `car_55' " (t=" %5.2f `t_55' ")"
display "    CAR[全窗口]:   " %10.6f `car_full' " (t=" %5.2f `t_full' ")"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=car_11|value=`car_11'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK03|status=ok|elapsed_sec=`elapsed'"
log close
