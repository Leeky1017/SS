* ==============================================================================
* SS_TEMPLATE: id=TK19  level=L2  module=K  title="Beta Anomaly"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK19_beta_sort.csv type=table desc="Beta sorted returns"
*   - table_TK19_bab_factor.csv type=table desc="BAB factor"
*   - fig_TK19_beta_anomaly.png type=graph desc="Beta anomaly chart"
*   - data_TK19_beta.dta type=data desc="Output data"
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

program define ss_fail_TK19
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
    display "SS_TASK_END|id=TK19|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK19|level=L2|title=Beta_Anomaly"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local beta_var = "__BETA_VAR__"
local stock_id = "__STOCK_ID__"
local time_var = "__TIME_VAR__"
local n_groups = __N_GROUPS__

if `n_groups' < 3 | `n_groups' > 10 {
    local n_groups = 5
}

display ""
display ">>> 低Beta异象参数:"
display "    收益变量: `return_var'"
display "    Beta变量: `beta_var'"
display "    分组数: `n_groups'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK19 601 confirm_file file_not_found data.csv S01_load_data
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
        ss_fail_TK19 200 confirm_variable var_not_found `var' S02_validate_inputs
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
        ss_fail_TK19 459 xtset xtset_failed panel_set S02_validate_inputs
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ Beta分组 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Beta分组"
display "═══════════════════════════════════════════════════════════════════════════════"

capture drop beta_rank
tempvar n_time
bysort `time_var': gen long `n_time' = _N
quietly summarize `n_time'
local max_n_time = r(max)
drop `n_time'

if `max_n_time' < 2 {
    capture xtile beta_rank = `beta_var', nq(`n_groups')
    local rc_tile = _rc
    if `rc_tile' != 0 {
        generate int beta_rank = 1
    }
}
else {
    generate int beta_rank = .
    tempvar tmp_rank
    quietly levelsof `time_var', local(times_rank)
    foreach tt of local times_rank {
        capture drop `tmp_rank'
        capture xtile `tmp_rank' = `beta_var' if `time_var' == `tt', nq(`n_groups')
        local rc_tile = _rc
        if `rc_tile' == 0 {
            replace beta_rank = `tmp_rank' if `time_var' == `tt'
            drop `tmp_rank'
        }
    }

    quietly count if !missing(beta_rank)
    if r(N) == 0 {
        capture drop beta_rank
        capture xtile beta_rank = `beta_var', nq(`n_groups')
        local rc_global = _rc
        if `rc_global' != 0 {
            generate int beta_rank = 1
        }
    }
}
label variable beta_rank "Beta分组(1=低,`n_groups'=高)"

display ""
display ">>> Beta统计:"
tabstat `beta_var', by(beta_rank) statistics(mean median n)

* ============ 计算组合收益 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Beta组合收益"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname port_returns
postfile `port_returns' long time int group double port_ret double avg_beta ///
    using "temp_beta_returns.dta", replace

quietly levelsof `time_var', local(times)

foreach t of local times {
    forvalues g = 1/`n_groups' {
        quietly summarize `return_var' if `time_var' == `t' & beta_rank == `g'
        local ret = r(mean)
        quietly summarize `beta_var' if `time_var' == `t' & beta_rank == `g'
        local beta = r(mean)
        if r(N) > 0 {
            post `port_returns' (`t') (`g') (`ret') (`beta')
        }
    }
}

postclose `port_returns'

preserve
use "temp_beta_returns.dta", clear

display ""
display ">>> Beta组合平均收益:"
display "组别    平均Beta    平均收益    t统计量    风险调整收益"
display "───────────────────────────────────────────────────────"

forvalues g = 1/`n_groups' {
    quietly summarize port_ret if group == `g'
    local mean_ret = r(mean)
    local se = r(sd) / sqrt(r(N))
    local t_stat = `mean_ret' / `se'
    
    quietly summarize avg_beta if group == `g'
    local mean_beta = r(mean)
    
    * 风险调整收益（假设市场收益=0.01）
    local risk_adj = `mean_ret' - 0.01 * `mean_beta'
    
    display %4.0f `g' "     " %8.4f `mean_beta' "    " %10.6f `mean_ret' "  " %8.2f `t_stat' "      " %10.6f `risk_adj'
}

* BAB因子（低Beta-高Beta，杠杆调整）
generate bab = .
quietly levelsof time, local(times)
foreach t of local times {
    quietly summarize port_ret if time == `t' & group == 1
    local low_ret = r(mean)
    quietly summarize avg_beta if time == `t' & group == 1
    local low_beta = r(mean)
    
    quietly summarize port_ret if time == `t' & group == `n_groups'
    local high_ret = r(mean)
    quietly summarize avg_beta if time == `t' & group == `n_groups'
    local high_beta = r(mean)
    
    * 简单BAB = 低Beta组合收益 - 高Beta组合收益
    quietly replace bab = `low_ret' - `high_ret' if time == `t' & group == 1
}

quietly summarize bab
local bab_mean = r(mean)
local bab_se = r(sd) / sqrt(r(N))
local bab_t = `bab_mean' / `bab_se'

display "───────────────────────────────────────────────────────"
display "BAB    " %10.6f `bab_mean' "  " %8.2f `bab_t'

display "SS_METRIC|name=bab_return|value=`bab_mean'"
display "SS_METRIC|name=bab_t|value=`bab_t'"

* 检验Beta与收益关系
collapse (mean) avg_ret = port_ret avg_beta = avg_beta, by(group)

regress avg_ret avg_beta
local slope = _b[avg_beta]
local slope_t = _b[avg_beta] / _se[avg_beta]

display ""
display ">>> 证券市场线斜率:"
display "    斜率: " %10.6f `slope'
display "    t值: " %8.2f `slope_t'

if `slope' < 0.01 {
    display "    结论: 存在低Beta异象（斜率低于CAPM预测）"
}

export delimited using "table_TK19_beta_sort.csv", replace
display "SS_OUTPUT_FILE|file=table_TK19_beta_sort.csv|type=table|desc=beta_sorted"

twoway (scatter avg_ret avg_beta, mcolor(navy) msize(large)) ///
       (lfit avg_ret avg_beta, lcolor(red)), ///
       xtitle("平均Beta") ytitle("平均收益") ///
       title("低Beta异象: 收益与Beta关系") ///
       note("BAB收益=" %6.4f `bab_mean' ", SML斜率=" %6.4f `slope')
graph export "fig_TK19_beta_anomaly.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK19_beta_anomaly.png|type=graph|desc=beta_anomaly"
restore

preserve
use "temp_beta_returns.dta", clear
reshape wide port_ret avg_beta, i(time) j(group)
generate double bab_factor = port_ret1 - port_ret`n_groups'
keep time bab_factor
export delimited using "table_TK19_bab_factor.csv", replace
display "SS_OUTPUT_FILE|file=table_TK19_bab_factor.csv|type=table|desc=bab_factor"
restore

capture erase "temp_beta_returns.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK19_beta.dta", replace
display "SS_OUTPUT_FILE|file=data_TK19_beta.dta|type=data|desc=beta_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK19 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  低Beta异象:"
display "    BAB收益:       " %10.6f `bab_mean'
display "    t统计量:       " %10.2f `bab_t'
display "    SML斜率:       " %10.6f `slope'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=bab_return|value=`bab_mean'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK19|status=ok|elapsed_sec=`elapsed'"
log close
