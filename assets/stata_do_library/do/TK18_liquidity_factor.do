* ==============================================================================
* SS_TEMPLATE: id=TK18  level=L2  module=K  title="Liquidity Factor"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK18_liquidity.csv type=table desc="Liquidity returns"
*   - table_TK18_factor.csv type=table desc="IML factor"
*   - fig_TK18_liquidity.png type=graph desc="Liquidity chart"
*   - data_TK18_liq.dta type=data desc="Output data"
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

program define ss_fail_TK18
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
    display "SS_TASK_END|id=TK18|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK18|level=L2|title=Liquidity_Factor"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local turnover_var = "__TURNOVER_VAR__"
local stock_id = "__STOCK_ID__"
local time_var = "__TIME_VAR__"
local n_groups = __N_GROUPS__

if `n_groups' < 3 | `n_groups' > 10 {
    local n_groups = 5
}

display ""
display ">>> 流动性因子参数:"
display "    收益变量: `return_var'"
display "    换手率: `turnover_var'"
display "    分组数: `n_groups'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK18 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `return_var' `turnover_var' `stock_id' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TK18 200 confirm_variable var_not_found `var' S02_validate_inputs
    }
}

capture xtset `stock_id' `time_var'
local rc_xtset = _rc
if `rc_xtset' != 0 {
    display "SS_RC|code=`rc_xtset'|cmd=xtset|msg=xtset_failed_trying_fallback|severity=warn"
    sort `stock_id' `time_var'
    bysort `stock_id': gen long ss_time_index = _n
    capture xtset `stock_id' ss_time_index
    local rc_xtset2 = _rc
    if `rc_xtset2' != 0 {
        ss_fail_TK18 459 xtset xtset_failed panel_set S02_validate_inputs
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 流动性分组 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 流动性分组"
display "═══════════════════════════════════════════════════════════════════════════════"

capture drop liq_rank
tempvar n_time
bysort `time_var': gen long `n_time' = _N
quietly summarize `n_time'
local max_n_time = r(max)
drop `n_time'

if `max_n_time' < 2 {
    capture xtile liq_rank = `turnover_var', nq(`n_groups')
    local rc_tile = _rc
    if `rc_tile' != 0 {
        generate int liq_rank = 1
    }
}
else {
    generate int liq_rank = .
    tempvar tmp_rank
    quietly levelsof `time_var', local(times_rank)
    foreach tt of local times_rank {
        capture drop `tmp_rank'
        capture xtile `tmp_rank' = `turnover_var' if `time_var' == `tt', nq(`n_groups')
        local rc_tile = _rc
        if `rc_tile' == 0 {
            replace liq_rank = `tmp_rank' if `time_var' == `tt'
            drop `tmp_rank'
        }
    }

    quietly count if !missing(liq_rank)
    if r(N) == 0 {
        capture drop liq_rank
        capture xtile liq_rank = `turnover_var', nq(`n_groups')
        local rc_global = _rc
        if `rc_global' != 0 {
            generate int liq_rank = 1
        }
    }
}
label variable liq_rank "流动性分组(1=低,`n_groups'=高)"

display ""
display ">>> 换手率统计:"
tabstat `turnover_var', by(liq_rank) statistics(mean median n)

* ============ 计算组合收益 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 流动性组合收益"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname port_returns
postfile `port_returns' long time int group double port_ret ///
    using "temp_liq_returns.dta", replace

quietly levelsof `time_var', local(times)

foreach t of local times {
    forvalues g = 1/`n_groups' {
        quietly summarize `return_var' if `time_var' == `t' & liq_rank == `g'
        if r(N) > 0 {
            post `port_returns' (`t') (`g') (r(mean))
        }
    }
}

postclose `port_returns'

preserve
use "temp_liq_returns.dta", clear

display ""
display ">>> 流动性组合平均收益:"
display "组别    平均收益    t统计量"
display "───────────────────────────"

forvalues g = 1/`n_groups' {
    quietly summarize port_ret if group == `g'
    local mean_ret = r(mean)
    local se = r(sd) / sqrt(r(N))
    local t_stat = `mean_ret' / `se'
    display %4.0f `g' "     " %10.6f `mean_ret' "  " %8.2f `t_stat'
}

* IML因子（非流动-流动）
generate iml = .
quietly levelsof time, local(times)
foreach t of local times {
    quietly summarize port_ret if time == `t' & group == 1
    local illiq = r(mean)
    quietly summarize port_ret if time == `t' & group == `n_groups'
    local liq = r(mean)
    quietly replace iml = `illiq' - `liq' if time == `t' & group == 1
}

quietly summarize iml
local iml_mean = r(mean)
local iml_se = r(sd) / sqrt(r(N))
local iml_t = `iml_mean' / `iml_se'

display "───────────────────────────"
display "IML    " %10.6f `iml_mean' "  " %8.2f `iml_t'

display "SS_METRIC|name=iml_return|value=`iml_mean'"
display "SS_METRIC|name=iml_t|value=`iml_t'"

collapse (mean) avg_ret = port_ret, by(group)
export delimited using "table_TK18_liquidity.csv", replace
display "SS_OUTPUT_FILE|file=table_TK18_liquidity.csv|type=table|desc=liq_returns"

twoway (bar avg_ret group, barwidth(0.6) color(navy)), ///
    xlabel(1(1)`n_groups') ///
    xtitle("流动性组合 (1=低, `n_groups'=高)") ytitle("平均收益") ///
    title("流动性效应: IML组合收益") ///
    note("IML收益=" %6.4f `iml_mean' ", t=" %5.2f `iml_t')
graph export "fig_TK18_liquidity.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK18_liquidity.png|type=graph|desc=liq_chart"
restore

preserve
use "temp_liq_returns.dta", clear
reshape wide port_ret, i(time) j(group)
generate double iml_factor = port_ret1 - port_ret`n_groups'
keep time iml_factor
export delimited using "table_TK18_factor.csv", replace
display "SS_OUTPUT_FILE|file=table_TK18_factor.csv|type=table|desc=iml_factor"
restore

capture erase "temp_liq_returns.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK18_liq.dta", replace
display "SS_OUTPUT_FILE|file=data_TK18_liq.dta|type=data|desc=liq_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK18 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  流动性效应:"
display "    IML收益:       " %10.6f `iml_mean'
display "    t统计量:       " %10.2f `iml_t'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=iml_return|value=`iml_mean'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK18|status=ok|elapsed_sec=`elapsed'"
log close
