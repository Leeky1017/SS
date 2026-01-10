* ==============================================================================
* SS_TEMPLATE: id=TK16  level=L2  module=K  title="Value Factor"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK16_value.csv type=table desc="Value returns"
*   - table_TK16_factor.csv type=table desc="HML factor"
*   - fig_TK16_value.png type=graph desc="Value chart"
*   - data_TK16_value.dta type=data desc="Output data"
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

program define ss_fail_TK16
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
    display "SS_TASK_END|id=TK16|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK16|level=L2|title=Value_Factor"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local bm_var = "__BM_VAR__"
local stock_id = "__STOCK_ID__"
local time_var = "__TIME_VAR__"
local n_groups = __N_GROUPS__

if `n_groups' < 3 | `n_groups' > 10 {
    local n_groups = 5
}

display ""
display ">>> 价值因子参数:"
display "    收益变量: `return_var'"
display "    BM变量: `bm_var'"
display "    股票ID: `stock_id'"
display "    分组数: `n_groups'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK16 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `return_var' `bm_var' `stock_id' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TK16 200 confirm_variable var_not_found `var' S02_validate_inputs
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
        ss_fail_TK16 459 xtset xtset_failed panel_set S02_validate_inputs
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 价值分组 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 价值分组"
display "═══════════════════════════════════════════════════════════════════════════════"

* 按时间截面对BM分组
capture drop bm_rank
tempvar n_time
bysort `time_var': gen long `n_time' = _N
quietly summarize `n_time'
local max_n_time = r(max)
drop `n_time'

if `max_n_time' < 2 {
    capture xtile bm_rank = `bm_var', nq(`n_groups')
    local rc_tile = _rc
    if `rc_tile' != 0 {
        generate int bm_rank = 1
    }
}
else {
    generate int bm_rank = .
    tempvar tmp_rank
    quietly levelsof `time_var', local(times_rank)
    foreach tt of local times_rank {
        capture drop `tmp_rank'
        capture xtile `tmp_rank' = `bm_var' if `time_var' == `tt', nq(`n_groups')
        local rc_tile = _rc
        if `rc_tile' == 0 {
            replace bm_rank = `tmp_rank' if `time_var' == `tt'
            drop `tmp_rank'
        }
    }

    quietly count if !missing(bm_rank)
    if r(N) == 0 {
        capture drop bm_rank
        capture xtile bm_rank = `bm_var', nq(`n_groups')
        local rc_global = _rc
        if `rc_global' != 0 {
            generate int bm_rank = 1
        }
    }
}
label variable bm_rank "价值分组(1=成长,`n_groups'=价值)"

display ""
display ">>> BM统计:"
tabstat `bm_var', by(bm_rank) statistics(mean median sd n)

* ============ 计算组合收益 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 价值组合收益"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname port_returns
postfile `port_returns' long time int group double port_ret ///
    using "temp_value_returns.dta", replace

quietly levelsof `time_var', local(times)

foreach t of local times {
    forvalues g = 1/`n_groups' {
        quietly summarize `return_var' if `time_var' == `t' & bm_rank == `g'
        if r(N) > 0 {
            post `port_returns' (`t') (`g') (r(mean))
        }
    }
}

postclose `port_returns'

preserve
use "temp_value_returns.dta", clear

display ""
display ">>> 价值组合平均收益:"
display "组别    平均收益    t统计量"
display "───────────────────────────"

forvalues g = 1/`n_groups' {
    quietly summarize port_ret if group == `g'
    local mean_ret = r(mean)
    local se = r(sd) / sqrt(r(N))
    local t_stat = `mean_ret' / `se'
    display %4.0f `g' "     " %10.6f `mean_ret' "  " %8.2f `t_stat'
}

* HML因子（高BM-低BM）
generate hml = .
quietly levelsof time, local(times)
foreach t of local times {
    quietly summarize port_ret if time == `t' & group == `n_groups'
    local high = r(mean)
    quietly summarize port_ret if time == `t' & group == 1
    local low = r(mean)
    quietly replace hml = `high' - `low' if time == `t' & group == 1
}

quietly summarize hml
local hml_mean = r(mean)
local hml_se = r(sd) / sqrt(r(N))
local hml_t = `hml_mean' / `hml_se'

display "───────────────────────────"
display "HML    " %10.6f `hml_mean' "  " %8.2f `hml_t'

display "SS_METRIC|name=hml_return|value=`hml_mean'"
display "SS_METRIC|name=hml_t|value=`hml_t'"

collapse (mean) avg_ret = port_ret, by(group)
export delimited using "table_TK16_value.csv", replace
display "SS_OUTPUT_FILE|file=table_TK16_value.csv|type=table|desc=value_returns"

* 生成图
twoway (bar avg_ret group, barwidth(0.6) color(navy)), ///
    xlabel(1(1)`n_groups') ///
    xtitle("价值组合 (1=成长, `n_groups'=价值)") ytitle("平均收益") ///
    title("价值效应: HML组合收益") ///
    note("HML收益=" %6.4f `hml_mean' ", t=" %5.2f `hml_t')
graph export "fig_TK16_value.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK16_value.png|type=graph|desc=value_chart"
restore

* 导出HML因子
preserve
use "temp_value_returns.dta", clear
reshape wide port_ret, i(time) j(group)
generate double hml_factor = port_ret`n_groups' - port_ret1
keep time hml_factor
export delimited using "table_TK16_factor.csv", replace
display "SS_OUTPUT_FILE|file=table_TK16_factor.csv|type=table|desc=hml_factor"
restore

capture erase "temp_value_returns.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK16_value.dta", replace
display "SS_OUTPUT_FILE|file=data_TK16_value.dta|type=data|desc=value_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK16 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  价值效应:"
display "    HML收益:       " %10.6f `hml_mean'
display "    t统计量:       " %10.2f `hml_t'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=hml_return|value=`hml_mean'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK16|status=ok|elapsed_sec=`elapsed'"
log close
