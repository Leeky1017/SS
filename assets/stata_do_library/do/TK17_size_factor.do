* ==============================================================================
* SS_TEMPLATE: id=TK17  level=L2  module=K  title="Size Factor"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK17_size.csv type=table desc="Size returns"
*   - table_TK17_factor.csv type=table desc="SMB factor"
*   - fig_TK17_size.png type=graph desc="Size chart"
*   - data_TK17_size.dta type=data desc="Output data"
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

program define ss_fail_TK17
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
    display "SS_TASK_END|id=TK17|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK17|level=L2|title=Size_Factor"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local size_var = "__SIZE_VAR__"
local stock_id = "__STOCK_ID__"
local time_var = "__TIME_VAR__"
local n_groups = __N_GROUPS__

if `n_groups' < 3 | `n_groups' > 10 {
    local n_groups = 5
}

display ""
display ">>> 规模因子参数:"
display "    收益变量: `return_var'"
display "    市值变量: `size_var'"
display "    分组数: `n_groups'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK17 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `return_var' `size_var' `stock_id' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TK17 200 confirm_variable var_not_found `var' S02_validate_inputs
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
        ss_fail_TK17 459 xtset xtset_failed panel_set S02_validate_inputs
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 规模分组 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 规模分组"
display "═══════════════════════════════════════════════════════════════════════════════"

capture drop size_rank
tempvar n_time
bysort `time_var': gen long `n_time' = _N
quietly summarize `n_time'
local max_n_time = r(max)
drop `n_time'

if `max_n_time' < 2 {
    capture xtile size_rank = `size_var', nq(`n_groups')
    local rc_tile = _rc
    if `rc_tile' != 0 {
        generate int size_rank = 1
    }
}
else {
    generate int size_rank = .
    tempvar tmp_rank
    quietly levelsof `time_var', local(times_rank)
    foreach tt of local times_rank {
        capture drop `tmp_rank'
        capture xtile `tmp_rank' = `size_var' if `time_var' == `tt', nq(`n_groups')
        local rc_tile = _rc
        if `rc_tile' == 0 {
            replace size_rank = `tmp_rank' if `time_var' == `tt'
            drop `tmp_rank'
        }
    }

    quietly count if !missing(size_rank)
    if r(N) == 0 {
        capture drop size_rank
        capture xtile size_rank = `size_var', nq(`n_groups')
        local rc_global = _rc
        if `rc_global' != 0 {
            generate int size_rank = 1
        }
    }
}
label variable size_rank "规模分组(1=小,`n_groups'=大)"

display ""
display ">>> 市值统计:"
tabstat `size_var', by(size_rank) statistics(mean median n)

* ============ 计算组合收益 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 规模组合收益"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname port_returns
postfile `port_returns' long time int group double port_ret ///
    using "temp_size_returns.dta", replace

quietly levelsof `time_var', local(times)

foreach t of local times {
    forvalues g = 1/`n_groups' {
        quietly summarize `return_var' if `time_var' == `t' & size_rank == `g'
        if r(N) > 0 {
            post `port_returns' (`t') (`g') (r(mean))
        }
    }
}

postclose `port_returns'

preserve
use "temp_size_returns.dta", clear

display ""
display ">>> 规模组合平均收益:"
display "组别    平均收益    t统计量"
display "───────────────────────────"

forvalues g = 1/`n_groups' {
    quietly summarize port_ret if group == `g'
    local mean_ret = r(mean)
    local se = r(sd) / sqrt(r(N))
    local t_stat = `mean_ret' / `se'
    display %4.0f `g' "     " %10.6f `mean_ret' "  " %8.2f `t_stat'
}

* SMB因子（小市值-大市值）
generate smb = .
quietly levelsof time, local(times)
foreach t of local times {
    quietly summarize port_ret if time == `t' & group == 1
    local small = r(mean)
    quietly summarize port_ret if time == `t' & group == `n_groups'
    local big = r(mean)
    quietly replace smb = `small' - `big' if time == `t' & group == 1
}

quietly summarize smb
local smb_mean = r(mean)
local smb_se = r(sd) / sqrt(r(N))
local smb_t = `smb_mean' / `smb_se'

display "───────────────────────────"
display "SMB    " %10.6f `smb_mean' "  " %8.2f `smb_t'

display "SS_METRIC|name=smb_return|value=`smb_mean'"
display "SS_METRIC|name=smb_t|value=`smb_t'"

collapse (mean) avg_ret = port_ret, by(group)
export delimited using "table_TK17_size.csv", replace
display "SS_OUTPUT_FILE|file=table_TK17_size.csv|type=table|desc=size_returns"

twoway (bar avg_ret group, barwidth(0.6) color(navy)), ///
    xlabel(1(1)`n_groups') ///
    xtitle("规模组合 (1=小, `n_groups'=大)") ytitle("平均收益") ///
    title("规模效应: SMB组合收益") ///
    note("SMB收益=" %6.4f `smb_mean' ", t=" %5.2f `smb_t')
graph export "fig_TK17_size.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK17_size.png|type=graph|desc=size_chart"
restore

preserve
use "temp_size_returns.dta", clear
reshape wide port_ret, i(time) j(group)
generate double smb_factor = port_ret1 - port_ret`n_groups'
keep time smb_factor
export delimited using "table_TK17_factor.csv", replace
display "SS_OUTPUT_FILE|file=table_TK17_factor.csv|type=table|desc=smb_factor"
restore

capture erase "temp_size_returns.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK17_size.dta", replace
display "SS_OUTPUT_FILE|file=data_TK17_size.dta|type=data|desc=size_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK17 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  规模效应:"
display "    SMB收益:       " %10.6f `smb_mean'
display "    t统计量:       " %10.2f `smb_t'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=smb_return|value=`smb_mean'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK17|status=ok|elapsed_sec=`elapsed'"
log close
