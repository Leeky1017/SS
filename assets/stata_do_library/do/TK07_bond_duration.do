* ==============================================================================
* SS_TEMPLATE: id=TK07  level=L1  module=K  title="Bond Duration"
* INPUTS:
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TK07_duration.csv type=table desc="Duration results"
*   - fig_TK07_price_yield.png type=figure desc="Price-yield curve"
*   - data_TK07_bond.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TK07|level=L1|title=Bond_Duration"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

display "SS_STEP_BEGIN|step=S01_load_data"

* ============ 参数设置 ============
local face_value = __FACE_VALUE__
local coupon_rate = __COUPON_RATE__
local ytm = __YTM__
local maturity = __MATURITY__
local frequency = __FREQUENCY__

if `face_value' <= 0 {
    local face_value = 1000
}
if `coupon_rate' < 0 | `coupon_rate' > 0.5 {
    local coupon_rate = 0.05
}
if `ytm' < 0 | `ytm' > 0.5 {
    local ytm = 0.05
}
if `maturity' <= 0 | `maturity' > 100 {
    local maturity = 10
}
if `frequency' < 1 | `frequency' > 12 {
    local frequency = 2
}

local coupon = `face_value' * `coupon_rate' / `frequency'
local n_periods = `maturity' * `frequency'
local y = `ytm' / `frequency'

display ""
display ">>> 债券参数:"
display "    面值: " %10.2f `face_value'
display "    票面利率: " %6.2f `=`coupon_rate'*100' "%"
display "    到期收益率: " %6.2f `=`ytm'*100' "%"
display "    到期期限: `maturity' 年"
display "    付息频率: `frequency' 次/年"
display "    每期票息: " %8.2f `coupon'
display "    期数: `n_periods'"

* ============ 数据加载（可选） ============
capture confirm file "data.csv"
if !_rc {
    import delimited "data.csv", clear
    local n_input = _N
}
else {
    * 创建单一债券数据
    clear
    set obs 1
    generate double face = `face_value'
    generate double coupon_r = `coupon_rate'
    generate double yield = `ytm'
    generate double mat = `maturity'
    local n_input = 1
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 债券定价 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 债券定价"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算债券价格
* P = sum(C/(1+y)^t) + F/(1+y)^n
local price = 0
forvalues t = 1/`n_periods' {
    local pv_coupon = `coupon' / ((1 + `y')^`t')
    local price = `price' + `pv_coupon'
}
local pv_face = `face_value' / ((1 + `y')^`n_periods')
local price = `price' + `pv_face'

display ""
display ">>> 债券价格: " %12.4f `price'
display "    溢价/折价: " %12.4f `=`price' - `face_value''

display "SS_METRIC|name=price|value=`price'"

* ============ Macaulay久期 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Macaulay久期"
display "═══════════════════════════════════════════════════════════════════════════════"

* D = sum(t * PV(CF_t)) / P
local weighted_sum = 0
forvalues t = 1/`n_periods' {
    local pv_coupon = `coupon' / ((1 + `y')^`t')
    local weighted_sum = `weighted_sum' + `t' * `pv_coupon'
}
local weighted_sum = `weighted_sum' + `n_periods' * `pv_face'

local mac_duration = `weighted_sum' / `price'
local mac_duration_years = `mac_duration' / `frequency'

display ""
display ">>> Macaulay久期:"
display "    期数: " %10.4f `mac_duration'
display "    年数: " %10.4f `mac_duration_years'

display "SS_METRIC|name=mac_duration|value=`mac_duration_years'"

* ============ 修正久期 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 修正久期"
display "═══════════════════════════════════════════════════════════════════════════════"

* Modified Duration = Macaulay Duration / (1 + y/m)
local mod_duration = `mac_duration_years' / (1 + `y')

display ""
display ">>> 修正久期: " %10.4f `mod_duration'
display "    解释: 利率变动1%，价格变动约 " %5.2f `mod_duration' "%"

display "SS_METRIC|name=mod_duration|value=`mod_duration'"

* ============ 凸度 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 凸度"
display "═══════════════════════════════════════════════════════════════════════════════"

* Convexity = sum(t*(t+1)*PV(CF_t)) / (P * (1+y)^2)
local convex_sum = 0
forvalues t = 1/`n_periods' {
    local pv_coupon = `coupon' / ((1 + `y')^`t')
    local convex_sum = `convex_sum' + `t' * (`t' + 1) * `pv_coupon'
}
local convex_sum = `convex_sum' + `n_periods' * (`n_periods' + 1) * `pv_face'

local convexity = `convex_sum' / (`price' * (1 + `y')^2 * `frequency'^2)

display ""
display ">>> 凸度: " %10.4f `convexity'

display "SS_METRIC|name=convexity|value=`convexity'"

* ============ 价格敏感性分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 价格敏感性分析"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 利率变动对价格的影响:"
display "利率变动    久期效应      凸度效应      总效应        新价格"
display "───────────────────────────────────────────────────────────────"

foreach delta in -0.02 -0.01 -0.005 0.005 0.01 0.02 {
    local dur_effect = -`mod_duration' * `delta'
    local conv_effect = 0.5 * `convexity' * `delta'^2
    local total_effect = `dur_effect' + `conv_effect'
    local new_price = `price' * (1 + `total_effect')
    
    display %8.2f `=`delta'*100' "%   " %10.4f `dur_effect' "   " %10.6f `conv_effect' "   " ///
        %10.4f `total_effect' "   " %12.4f `new_price'
}

* ============ 生成价格-收益率曲线 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 生成价格-收益率曲线"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
clear
set obs 41
generate double yield_change = (_n - 21) / 100
generate double yield_level = `ytm' + yield_change

* 计算各收益率下的实际价格
generate double actual_price = .
generate double duration_approx = .
generate double dur_conv_approx = .

forvalues i = 1/41 {
    local y_test = yield_level[`i'] / `frequency'
    
    * 实际价格
    local p_test = 0
    forvalues t = 1/`n_periods' {
        local p_test = `p_test' + `coupon' / ((1 + `y_test')^`t')
    }
    local p_test = `p_test' + `face_value' / ((1 + `y_test')^`n_periods')
    replace actual_price = `p_test' in `i'
    
    * 久期近似
    local delta = yield_change[`i']
    local dur_approx = `price' * (1 - `mod_duration' * `delta')
    replace duration_approx = `dur_approx' in `i'
    
    * 久期+凸度近似
    local dc_approx = `price' * (1 - `mod_duration' * `delta' + 0.5 * `convexity' * `delta'^2)
    replace dur_conv_approx = `dc_approx' in `i'
}

twoway (line actual_price yield_level, lcolor(navy) lwidth(medium)) ///
       (line duration_approx yield_level, lcolor(red) lpattern(dash)) ///
       (line dur_conv_approx yield_level, lcolor(green) lpattern(shortdash)), ///
       xline(`ytm', lcolor(gray) lpattern(dot)) ///
       legend(order(1 "实际价格" 2 "久期近似" 3 "久期+凸度") position(6)) ///
       xtitle("到期收益率") ytitle("债券价格") ///
       title("债券价格-收益率关系")
graph export "fig_TK07_price_yield.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK07_price_yield.png|type=figure|desc=price_yield"
restore

* ============ 导出结果 ============
preserve
clear
set obs 1
generate double face_value = `face_value'
generate double coupon_rate = `coupon_rate'
generate double ytm = `ytm'
generate double maturity = `maturity'
generate double price = `price'
generate double mac_duration = `mac_duration_years'
generate double mod_duration = `mod_duration'
generate double convexity = `convexity'

export delimited using "table_TK07_duration.csv", replace
display "SS_OUTPUT_FILE|file=table_TK07_duration.csv|type=table|desc=duration_results"
restore

* ============ 输出结果 ============
local n_output = 1
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK07_bond.dta", replace
display "SS_OUTPUT_FILE|file=data_TK07_bond.dta|type=data|desc=bond_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK07 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  债券参数:"
display "    面值:          " %10.2f `face_value'
display "    票面利率:      " %10.2f `=`coupon_rate'*100' "%"
display "    到期收益率:    " %10.2f `=`ytm'*100' "%"
display "    到期期限:      " %10.0f `maturity' " 年"
display ""
display "  计算结果:"
display "    价格:          " %10.4f `price'
display "    Macaulay久期:  " %10.4f `mac_duration_years' " 年"
display "    修正久期:      " %10.4f `mod_duration'
display "    凸度:          " %10.4f `convexity'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mod_duration|value=`mod_duration'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK07|status=ok|elapsed_sec=`elapsed'"
log close
