* ==============================================================================
* SS_TEMPLATE: id=TK14  level=L1  module=K  title="Sharpe Sortino"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK14_metrics.csv type=table desc="Risk metrics"
*   - fig_TK14_drawdown.png type=figure desc="Drawdown chart"
*   - data_TK14_risk.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TK14|level=L1|title=Sharpe_Sortino"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local benchmark_var = "__BENCHMARK_VAR__"
local rf_rate = __RF_RATE__
local frequency = "__FREQUENCY__"

if `rf_rate' < 0 | `rf_rate' > 0.5 {
    local rf_rate = 0.02
}
if "`frequency'" == "" {
    local frequency = "daily"
}

* 年化因子
if "`frequency'" == "daily" {
    local ann_factor = 252
}
else if "`frequency'" == "monthly" {
    local ann_factor = 12
}
else {
    local ann_factor = 1
}

local rf_period = `rf_rate' / `ann_factor'

display ""
display ">>> 风险调整指标参数:"
display "    收益变量: `return_var'"
display "    基准: `benchmark_var'"
display "    无风险利率: " %6.4f `rf_rate' " (年化)"
display "    频率: `frequency' (年化因子=`ann_factor')"

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

generate t = _n
tsset t

* ============ 变量检查 ============
capture confirm numeric variable `return_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`return_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`return_var' not found"
    log close
    exit 200
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 基本统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 收益统计"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize `return_var'
local mean_ret = r(mean)
local sd_ret = r(sd)
local ann_ret = `mean_ret' * `ann_factor'
local ann_vol = `sd_ret' * sqrt(`ann_factor')

display ""
display ">>> 收益统计:"
display "    期间均值: " %12.6f `mean_ret'
display "    期间标准差: " %12.6f `sd_ret'
display "    年化收益: " %12.4f `ann_ret' " (" %6.2f `=`ann_ret'*100' "%)"
display "    年化波动率: " %12.4f `ann_vol' " (" %6.2f `=`ann_vol'*100' "%)"

* ============ Sharpe比率 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Sharpe比率"
display "═══════════════════════════════════════════════════════════════════════════════"

local sharpe = (`ann_ret' - `rf_rate') / `ann_vol'

display ""
display ">>> Sharpe比率: " %10.4f `sharpe'
display "    解释: 每单位风险获得的超额收益"

display "SS_METRIC|name=sharpe|value=`sharpe'"

* ============ Sortino比率 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: Sortino比率"
display "═══════════════════════════════════════════════════════════════════════════════"

* 下行标准差
generate double downside_dev = min(`return_var' - `rf_period', 0)^2
quietly summarize downside_dev
local downside_vol = sqrt(r(mean)) * sqrt(`ann_factor')

local sortino = (`ann_ret' - `rf_rate') / `downside_vol'

display ""
display ">>> Sortino比率: " %10.4f `sortino'
display "    下行波动率: " %10.4f `downside_vol'
display "    解释: 每单位下行风险获得的超额收益"

display "SS_METRIC|name=sortino|value=`sortino'"

* ============ 最大回撤 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 最大回撤"
display "═══════════════════════════════════════════════════════════════════════════════"

* 累计收益
generate double cum_ret = sum(ln(1 + `return_var'))
generate double wealth = exp(cum_ret)

* 历史最高
generate double running_max = wealth[1]
replace running_max = max(running_max[_n-1], wealth) if _n > 1

* 回撤
generate double drawdown = (wealth - running_max) / running_max

quietly summarize drawdown
local max_drawdown = -r(min)

display ""
display ">>> 最大回撤: " %10.4f `max_drawdown' " (" %6.2f `=`max_drawdown'*100' "%)"

display "SS_METRIC|name=max_drawdown|value=`max_drawdown'"

* Calmar比率
local calmar = `ann_ret' / `max_drawdown'
display ">>> Calmar比率: " %10.4f `calmar'

* ============ 信息比率（如有基准） ============
capture confirm numeric variable `benchmark_var'
if !_rc {
    display ""
    display "═══════════════════════════════════════════════════════════════════════════════"
    display "SECTION 5: 信息比率"
    display "═══════════════════════════════════════════════════════════════════════════════"
    
    generate double active_ret = `return_var' - `benchmark_var'
    quietly summarize active_ret
    local tracking_error = r(sd) * sqrt(`ann_factor')
    local active_return = r(mean) * `ann_factor'
    
    local info_ratio = `active_return' / `tracking_error'
    
    display ""
    display ">>> 信息比率: " %10.4f `info_ratio'
    display "    主动收益: " %10.4f `active_return'
    display "    跟踪误差: " %10.4f `tracking_error'
    
    display "SS_METRIC|name=info_ratio|value=`info_ratio'"
}
else {
    local info_ratio = .
}

* ============ 导出指标 ============
preserve
clear
set obs 8
generate str30 metric = ""
generate double value = .

replace metric = "年化收益" in 1
replace value = `ann_ret' in 1
replace metric = "年化波动率" in 2
replace value = `ann_vol' in 2
replace metric = "Sharpe比率" in 3
replace value = `sharpe' in 3
replace metric = "Sortino比率" in 4
replace value = `sortino' in 4
replace metric = "最大回撤" in 5
replace value = `max_drawdown' in 5
replace metric = "Calmar比率" in 6
replace value = `calmar' in 6
replace metric = "信息比率" in 7
replace value = `info_ratio' in 7
replace metric = "观测数" in 8
replace value = `n_input' in 8

export delimited using "table_TK14_metrics.csv", replace
display "SS_OUTPUT_FILE|file=table_TK14_metrics.csv|type=table|desc=risk_metrics"
restore

* ============ 生成回撤图 ============
twoway (area drawdown t, color(red%50)), ///
    xtitle("时间") ytitle("回撤") ///
    title("投资组合回撤") ///
    note("最大回撤=" %5.2f `=`max_drawdown'*100' "%")
graph export "fig_TK14_drawdown.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK14_drawdown.png|type=figure|desc=drawdown_chart"

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK14_risk.dta", replace
display "SS_OUTPUT_FILE|file=data_TK14_risk.dta|type=data|desc=risk_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK14 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  风险调整指标:"
display "    Sharpe:        " %10.4f `sharpe'
display "    Sortino:       " %10.4f `sortino'
display "    Calmar:        " %10.4f `calmar'
display "    最大回撤:      " %10.2f `=`max_drawdown'*100' "%"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=sharpe|value=`sharpe'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK14|status=ok|elapsed_sec=`elapsed'"
log close
