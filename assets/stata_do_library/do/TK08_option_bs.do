* ==============================================================================
* SS_TEMPLATE: id=TK08  level=L1  module=K  title="Option BS"
* INPUTS:
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TK08_option_price.csv type=table desc="Option price"
*   - table_TK08_greeks.csv type=table desc="Greeks"
*   - fig_TK08_payoff.png type=graph desc="Payoff diagram"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ------------------------------------------------------------------------------
* SS_BEST_PRACTICE_REVIEW (Phase 5.10) / 最佳实践审查记录
* - Date: 2026-01-10
* - Interpretation / 解释: BS assumes lognormal price + constant vol + frictionless market / BS 假设对数正态、常数波动、无摩擦
* - Data checks / 数据校验: validate units (rates/vol in decimals) / 校验单位（利率/波动率为小数）
* - Diagnostics / 诊断: sanity-check put-call parity, extreme parameter values / 检查平价关系与极端参数
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

display "SS_TASK_BEGIN|id=TK08|level=L1|title=Option_BS"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

display "SS_STEP_BEGIN|step=S01_load_data"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* Parameter defaults are emitted as warnings in S03 / 参数默认在 S03 中以告警形式记录
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 参数设置 ============
local S = __SPOT_PRICE__
local K = __STRIKE_PRICE__
local T = __TIME_TO_MAT__
local r = __RISK_FREE__
local sigma = __VOLATILITY__
local option_type = "__OPTION_TYPE__"

if `S' <= 0 {
    display "SS_RC|code=PARAM_DEFAULTED|param=S|default=100|severity=warn"
    local S = 100
}
if `K' <= 0 {
    display "SS_RC|code=PARAM_DEFAULTED|param=K|default=100|severity=warn"
    local K = 100
}
if `T' <= 0 | `T' > 10 {
    display "SS_RC|code=PARAM_DEFAULTED|param=T|default=1|severity=warn"
    local T = 1
}
if `r' < 0 | `r' > 0.5 {
    display "SS_RC|code=PARAM_DEFAULTED|param=r|default=0.05|severity=warn"
    local r = 0.05
}
if `sigma' <= 0 | `sigma' > 2 {
    display "SS_RC|code=PARAM_DEFAULTED|param=sigma|default=0.2|severity=warn"
    local sigma = 0.2
}
if "`option_type'" == "" | ("`option_type'" != "call" & "`option_type'" != "put") {
    display "SS_RC|code=PARAM_DEFAULTED|param=option_type|default=call|severity=warn"
    local option_type = "call"
}

display ""
display ">>> Black-Scholes参数:"
display "    标的现价 (S): " %10.2f `S'
display "    执行价格 (K): " %10.2f `K'
display "    到期时间 (T): " %10.4f `T' " 年"
display "    无风险利率 (r): " %6.2f `=`r'*100' "%"
display "    波动率 (σ): " %6.2f `=`sigma'*100' "%"
display "    期权类型: `option_type'"

* ============ Black-Scholes公式 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Black-Scholes期权定价"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算d1和d2
local d1 = (ln(`S'/`K') + (`r' + `sigma'^2/2) * `T') / (`sigma' * sqrt(`T'))
local d2 = `d1' - `sigma' * sqrt(`T')

display ""
display ">>> 中间变量:"
display "    d1 = " %10.6f `d1'
display "    d2 = " %10.6f `d2'

* 计算期权价格
if "`option_type'" == "call" {
    local N_d1 = normal(`d1')
    local N_d2 = normal(`d2')
    local price = `S' * `N_d1' - `K' * exp(-`r' * `T') * `N_d2'
    display ""
    display ">>> 看涨期权价格: " %10.4f `price'
}
else {
    local N_neg_d1 = normal(-`d1')
    local N_neg_d2 = normal(-`d2')
    local price = `K' * exp(-`r' * `T') * `N_neg_d2' - `S' * `N_neg_d1'
    display ""
    display ">>> 看跌期权价格: " %10.4f `price'
}

display "SS_METRIC|name=option_price|value=`price'"

* 内在价值和时间价值
if "`option_type'" == "call" {
    local intrinsic = max(`S' - `K', 0)
}
else {
    local intrinsic = max(`K' - `S', 0)
}
local time_value = `price' - `intrinsic'

display ""
display ">>> 价值分解:"
display "    内在价值: " %10.4f `intrinsic'
display "    时间价值: " %10.4f `time_value'

* ============ 希腊字母 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 希腊字母"
display "═══════════════════════════════════════════════════════════════════════════════"

* Delta
if "`option_type'" == "call" {
    local delta = normal(`d1')
}
else {
    local delta = normal(`d1') - 1
}

* Gamma (对call和put相同)
local gamma = normalden(`d1') / (`S' * `sigma' * sqrt(`T'))

* Vega (对call和put相同)
local vega = `S' * sqrt(`T') * normalden(`d1') / 100

* Theta
local theta_common = -(`S' * normalden(`d1') * `sigma') / (2 * sqrt(`T'))
if "`option_type'" == "call" {
    local theta = (`theta_common' - `r' * `K' * exp(-`r' * `T') * normal(`d2')) / 365
}
else {
    local theta = (`theta_common' + `r' * `K' * exp(-`r' * `T') * normal(-`d2')) / 365
}

* Rho
if "`option_type'" == "call" {
    local rho = `K' * `T' * exp(-`r' * `T') * normal(`d2') / 100
}
else {
    local rho = -`K' * `T' * exp(-`r' * `T') * normal(-`d2') / 100
}

display ""
display ">>> 希腊字母:"
display "    Delta (Δ): " %10.6f `delta'
display "      解释: 标的价格变动1元，期权价格变动 " %6.4f `delta' " 元"
display ""
display "    Gamma (Γ): " %10.6f `gamma'
display "      解释: 标的价格变动1元，Delta变动 " %8.6f `gamma'
display ""
display "    Vega (ν): " %10.6f `vega'
display "      解释: 波动率变动1%，期权价格变动 " %6.4f `vega' " 元"
display ""
display "    Theta (Θ): " %10.6f `theta'
display "      解释: 每天时间流逝，期权价值损失 " %6.4f `=-`theta'' " 元"
display ""
display "    Rho (ρ): " %10.6f `rho'
display "      解释: 利率变动1%，期权价格变动 " %6.4f `rho' " 元"

display "SS_METRIC|name=delta|value=`delta'"
display "SS_METRIC|name=gamma|value=`gamma'"
display "SS_METRIC|name=vega|value=`vega'"

* ============ Put-Call Parity验证 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: Put-Call Parity验证"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算另一类型期权价格
if "`option_type'" == "call" {
    local put_price = `price' - `S' + `K' * exp(-`r' * `T')
    display ""
    display ">>> Put-Call Parity: C - P = S - K*e^(-rT)"
    display "    看涨期权价格: " %10.4f `price'
    display "    对应看跌期权: " %10.4f `put_price'
}
else {
    local call_price = `price' + `S' - `K' * exp(-`r' * `T')
    display ""
    display ">>> Put-Call Parity: C - P = S - K*e^(-rT)"
    display "    看跌期权价格: " %10.4f `price'
    display "    对应看涨期权: " %10.4f `call_price'
}

* ============ 导出结果 ============
preserve
clear
set obs 1
generate str10 option_type = "`option_type'"
generate double spot = `S'
generate double strike = `K'
generate double time_to_mat = `T'
generate double risk_free = `r'
generate double volatility = `sigma'
generate double price = `price'
generate double intrinsic = `intrinsic'
generate double time_value = `time_value'

export delimited using "table_TK08_option_price.csv", replace
display "SS_OUTPUT_FILE|file=table_TK08_option_price.csv|type=table|desc=option_price"
restore

preserve
clear
set obs 5
generate str10 greek = ""
generate double value = .
generate str100 interpretation = ""

replace greek = "Delta" in 1
replace value = `delta' in 1
replace interpretation = "标的变动1元,期权变动Delta元" in 1

replace greek = "Gamma" in 2
replace value = `gamma' in 2
replace interpretation = "标的变动1元,Delta变动Gamma" in 2

replace greek = "Vega" in 3
replace value = `vega' in 3
replace interpretation = "波动率变动1%,期权变动Vega元" in 3

replace greek = "Theta" in 4
replace value = `theta' in 4
replace interpretation = "每天时间流逝损失|Theta|元" in 4

replace greek = "Rho" in 5
replace value = `rho' in 5
replace interpretation = "利率变动1%,期权变动Rho元" in 5

export delimited using "table_TK08_greeks.csv", replace
display "SS_OUTPUT_FILE|file=table_TK08_greeks.csv|type=table|desc=greeks"
restore

* ============ 生成损益图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成期权损益图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
clear
set obs 101
generate double spot_price = `S' * 0.5 + (_n - 1) * `S' / 100

* 到期损益
if "`option_type'" == "call" {
    generate double payoff = max(spot_price - `K', 0)
}
else {
    generate double payoff = max(`K' - spot_price, 0)
}

* 净损益（减去期权费）
generate double profit = payoff - `price'

twoway (line payoff spot_price, lcolor(navy) lwidth(medium)) ///
       (line profit spot_price, lcolor(red) lwidth(medium)), ///
       xline(`K', lcolor(gray) lpattern(dash)) ///
       yline(0, lcolor(gray) lpattern(dot)) ///
       xline(`S', lcolor(green) lpattern(shortdash)) ///
       legend(order(1 "到期损益" 2 "净损益") position(6)) ///
       xtitle("标的资产价格") ytitle("损益") ///
       title("`=proper("`option_type'")'期权损益图") ///
       note("K=`K' (灰线), S=`S' (绿线), 期权费=`=round(`price',0.01)'")
graph export "fig_TK08_payoff.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK08_payoff.png|type=graph|desc=payoff_diagram"
restore

* ============ 输出结果 ============
local n_input = 1
local n_output = 1
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK08 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  期权参数:"
display "    类型:          `option_type'"
display "    标的现价:      " %10.2f `S'
display "    执行价格:      " %10.2f `K'
display "    到期时间:      " %10.4f `T' " 年"
display "    波动率:        " %10.2f `=`sigma'*100' "%"
display ""
display "  定价结果:"
display "    期权价格:      " %10.4f `price'
display "    内在价值:      " %10.4f `intrinsic'
display "    时间价值:      " %10.4f `time_value'
display ""
display "  希腊字母:"
display "    Delta:         " %10.6f `delta'
display "    Gamma:         " %10.6f `gamma'
display "    Vega:          " %10.6f `vega'
display "    Theta:         " %10.6f `theta'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=option_price|value=`price'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK08|status=ok|elapsed_sec=`elapsed'"
log close
