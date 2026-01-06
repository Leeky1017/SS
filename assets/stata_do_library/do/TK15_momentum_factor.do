* ==============================================================================
* SS_TEMPLATE: id=TK15  level=L2  module=K  title="Momentum Factor"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK15_momentum.csv type=table desc="Momentum returns"
*   - table_TK15_factor.csv type=table desc="Momentum factor"
*   - fig_TK15_momentum.png type=figure desc="Momentum chart"
*   - data_TK15_mom.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TK15|level=L2|title=Momentum_Factor"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local stock_id = "__STOCK_ID__"
local time_var = "__TIME_VAR__"
local lookback = __LOOKBACK__
local skip = __SKIP__
local n_groups = __N_GROUPS__

if `lookback' < 1 | `lookback' > 36 {
    local lookback = 12
}
if `skip' < 0 | `skip' > 3 {
    local skip = 1
}
if `n_groups' < 3 | `n_groups' > 10 {
    local n_groups = 5
}

display ""
display ">>> 动量因子参数:"
display "    收益变量: `return_var'"
display "    股票ID: `stock_id'"
display "    时间变量: `time_var'"
display "    回溯期: `lookback' 期"
display "    跳过期: `skip' 期"
display "    分组数: `n_groups'"

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
foreach var in `return_var' `stock_id' `time_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

ss_smart_xtset `stock_id' `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 计算动量信号 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 计算动量信号"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算过去收益（跳过最近skip期）
local start_lag = `skip' + 1
local end_lag = `skip' + `lookback'

display ">>> 计算从t-`end_lag'到t-`start_lag'的累计收益..."

* 生成累计收益
bysort `stock_id' (`time_var'): generate double cum_ret = 1
forvalues i = `start_lag'/`end_lag' {
    bysort `stock_id' (`time_var'): replace cum_ret = cum_ret * (1 + L`i'.`return_var') if L`i'.`return_var' != .
}
generate double momentum = cum_ret - 1
label variable momentum "动量信号(过去`lookback'期收益)"

quietly summarize momentum
display ""
display ">>> 动量信号统计:"
display "    均值: " %10.4f r(mean)
display "    标准差: " %10.4f r(sd)
display "    范围: [" %8.4f r(min) ", " %8.4f r(max) "]"

* ============ 动量分组 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 动量分组"
display "═══════════════════════════════════════════════════════════════════════════════"

* 按时间截面分组
bysort `time_var': egen mom_rank = xtile(momentum), n(`n_groups')
label variable mom_rank "动量分组(1=输家,`n_groups'=赢家)"

* 每期各组统计
display ""
display ">>> 各组平均动量信号:"
tabstat momentum, by(mom_rank) statistics(mean sd n)

* ============ 计算组合收益 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 动量组合收益"
display "═══════════════════════════════════════════════════════════════════════════════"

* 各组等权收益
tempname port_returns
postfile `port_returns' long time int group double port_ret ///
    using "temp_port_returns.dta", replace

quietly levelsof `time_var', local(times)

foreach t of local times {
    forvalues g = 1/`n_groups' {
        quietly summarize `return_var' if `time_var' == `t' & mom_rank == `g'
        if r(N) > 0 {
            post `port_returns' (`t') (`g') (r(mean))
        }
    }
}

postclose `port_returns'

* 计算各组平均收益
preserve
use "temp_port_returns.dta", clear

display ""
display ">>> 动量组合平均收益:"
display "组别    平均收益    t统计量    显著性"
display "─────────────────────────────────────"

forvalues g = 1/`n_groups' {
    quietly summarize port_ret if group == `g'
    local mean_ret = r(mean)
    local se = r(sd) / sqrt(r(N))
    local t_stat = `mean_ret' / `se'
    
    local sig = ""
    if abs(`t_stat') > 2.576 local sig = "***"
    else if abs(`t_stat') > 1.96 local sig = "**"
    else if abs(`t_stat') > 1.645 local sig = "*"
    
    display %4.0f `g' "     " %10.6f `mean_ret' "  " %8.2f `t_stat' "   `sig'"
}

* WML组合（赢家-输家）
generate wml = .
quietly levelsof time, local(times)
foreach t of local times {
    quietly summarize port_ret if time == `t' & group == `n_groups'
    local winner = r(mean)
    quietly summarize port_ret if time == `t' & group == 1
    local loser = r(mean)
    quietly replace wml = `winner' - `loser' if time == `t' & group == 1
}

quietly summarize wml
local wml_mean = r(mean)
local wml_se = r(sd) / sqrt(r(N))
local wml_t = `wml_mean' / `wml_se'

display "─────────────────────────────────────"
display "WML    " %10.6f `wml_mean' "  " %8.2f `wml_t' cond(abs(`wml_t')>1.96, "  **", "")

display "SS_METRIC|name=wml_return|value=`wml_mean'"
display "SS_METRIC|name=wml_t|value=`wml_t'"

* 导出结果
collapse (mean) avg_ret = port_ret (sd) sd_ret = port_ret (count) n = port_ret, by(group)
export delimited using "table_TK15_momentum.csv", replace
display "SS_OUTPUT_FILE|file=table_TK15_momentum.csv|type=table|desc=momentum_returns"
restore

* ============ 导出动量因子 ============
preserve
use "temp_port_returns.dta", clear
reshape wide port_ret, i(time) j(group)
generate double mom_factor = port_ret`n_groups' - port_ret1
keep time mom_factor
export delimited using "table_TK15_factor.csv", replace
display "SS_OUTPUT_FILE|file=table_TK15_factor.csv|type=table|desc=factor"
restore

* ============ 生成动量效应图 ============
preserve
use "temp_port_returns.dta", clear
collapse (mean) avg_ret = port_ret, by(group)

twoway (bar avg_ret group, barwidth(0.6) color(navy)), ///
    xlabel(1(1)`n_groups') ///
    xtitle("动量组合 (1=输家, `n_groups'=赢家)") ytitle("平均收益") ///
    title("动量效应: 组合收益") ///
    note("WML收益=" %6.4f `wml_mean' ", t=" %5.2f `wml_t')
graph export "fig_TK15_momentum.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK15_momentum.png|type=figure|desc=momentum_chart"
restore

capture erase "temp_port_returns.dta"
if _rc != 0 { }

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK15_mom.dta", replace
display "SS_OUTPUT_FILE|file=data_TK15_mom.dta|type=data|desc=mom_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK15 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  回溯期:          `lookback' 期"
display "  分组数:          `n_groups'"
display ""
display "  动量效应:"
display "    WML收益:       " %10.6f `wml_mean'
display "    t统计量:       " %10.2f `wml_t'
if abs(`wml_t') > 1.96 {
    display "    结论:          动量效应显著"
}
else {
    display "    结论:          动量效应不显著"
}
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=wml_return|value=`wml_mean'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK15|status=ok|elapsed_sec=`elapsed'"
log close
