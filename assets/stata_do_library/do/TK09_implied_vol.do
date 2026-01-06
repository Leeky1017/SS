* ==============================================================================
* SS_TEMPLATE: id=TK09  level=L2  module=K  title="Implied Vol"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK09_implied_vol.csv type=table desc="IV results"
*   - fig_TK09_vol_smile.png type=figure desc="Vol smile"
*   - data_TK09_iv.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TK09|level=L2|title=Implied_Vol"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local market_price = "__MARKET_PRICE__"
local spot_var = "__SPOT_VAR__"
local strike_var = "__STRIKE_VAR__"
local ttm_var = "__TTM_VAR__"
local rf_rate = __RF_RATE__
local option_type = "__OPTION_TYPE__"

if `rf_rate' < 0 | `rf_rate' > 0.5 {
    local rf_rate = 0.05
}
if "`option_type'" == "" {
    local option_type = "call"
}

display ""
display ">>> 隐含波动率计算参数:"
display "    市场价格: `market_price'"
display "    标的价格: `spot_var'"
display "    执行价格: `strike_var'"
display "    到期时间: `ttm_var'"
display "    无风险利率: " %6.4f `rf_rate'
display "    期权类型: `option_type'"

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
foreach var in `market_price' `spot_var' `strike_var' `ttm_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 定义BS公式函数 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 计算隐含波动率"
display "═══════════════════════════════════════════════════════════════════════════════"

* 生成隐含波动率变量
generate double implied_vol = .
generate int iv_iterations = .
generate byte iv_converged = .

* 使用Newton-Raphson方法计算每个期权的隐含波动率
display ""
display ">>> 使用Newton-Raphson方法计算隐含波动率..."

local n_converged = 0
local n_failed = 0

forvalues i = 1/`n_input' {
    local S = `spot_var'[`i']
    local K = `strike_var'[`i']
    local T = `ttm_var'[`i']
    local P_market = `market_price'[`i']
    local r = `rf_rate'
    
    * 初始猜测值
    local sigma = 0.3
    local tol = 0.0001
    local max_iter = 100
    local iter = 0
    local converged = 0
    
    while `iter' < `max_iter' & `converged' == 0 {
        local iter = `iter' + 1
        
        * 计算d1和d2
        local d1 = (ln(`S'/`K') + (`r' + `sigma'^2/2) * `T') / (`sigma' * sqrt(`T'))
        local d2 = `d1' - `sigma' * sqrt(`T')
        
        * 计算BS价格
        if "`option_type'" == "call" {
            local P_bs = `S' * normal(`d1') - `K' * exp(-`r' * `T') * normal(`d2')
        }
        else {
            local P_bs = `K' * exp(-`r' * `T') * normal(-`d2') - `S' * normal(-`d1')
        }
        
        * 计算Vega
        local vega = `S' * sqrt(`T') * normalden(`d1')
        
        * 检查收敛
        local diff = `P_bs' - `P_market'
        if abs(`diff') < `tol' {
            local converged = 1
        }
        else if `vega' > 0.0001 {
            * Newton-Raphson更新
            local sigma = `sigma' - `diff' / `vega'
            * 确保sigma在合理范围
            if `sigma' < 0.01 {
                local sigma = 0.01
            }
            if `sigma' > 5 {
                local sigma = 5
            }
        }
        else {
            * Vega太小，使用二分法
            local sigma = `sigma' * 1.1
        }
    }
    
    if `converged' {
        quietly replace implied_vol = `sigma' in `i'
        quietly replace iv_converged = 1 in `i'
        local n_converged = `n_converged' + 1
    }
    else {
        quietly replace iv_converged = 0 in `i'
        local n_failed = `n_failed' + 1
    }
    quietly replace iv_iterations = `iter' in `i'
    
    if mod(`i', 100) == 0 {
        display "    处理 `i' / `n_input' 个期权..."
    }
}

display ""
display ">>> 计算完成:"
display "    收敛: `n_converged'"
display "    未收敛: `n_failed'"

display "SS_METRIC|name=n_converged|value=`n_converged'"

* ============ 统计分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 隐含波动率统计"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize implied_vol if iv_converged == 1
local avg_iv = r(mean)
local sd_iv = r(sd)
local min_iv = r(min)
local max_iv = r(max)

display ""
display ">>> 隐含波动率统计:"
display "    均值: " %8.4f `avg_iv' " (" %5.1f `=`avg_iv'*100' "%)"
display "    标准差: " %8.4f `sd_iv'
display "    范围: [" %6.4f `min_iv' ", " %6.4f `max_iv' "]"

display "SS_METRIC|name=avg_iv|value=`avg_iv'"

* 计算moneyness
generate double moneyness = `spot_var' / `strike_var'
label variable moneyness "价值状态 (S/K)"

* ============ 波动率微笑分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 波动率微笑分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 按moneyness分组统计
generate byte moneyness_grp = .
replace moneyness_grp = 1 if moneyness < 0.9
replace moneyness_grp = 2 if moneyness >= 0.9 & moneyness < 0.95
replace moneyness_grp = 3 if moneyness >= 0.95 & moneyness < 1.0
replace moneyness_grp = 4 if moneyness >= 1.0 & moneyness < 1.05
replace moneyness_grp = 5 if moneyness >= 1.05 & moneyness < 1.1
replace moneyness_grp = 6 if moneyness >= 1.1

label define moneyness_lbl 1 "深度虚值(<0.9)" 2 "虚值(0.9-0.95)" 3 "轻度虚值(0.95-1)" ///
    4 "轻度实值(1-1.05)" 5 "实值(1.05-1.1)" 6 "深度实值(>1.1)"
label values moneyness_grp moneyness_lbl

display ""
display ">>> 按价值状态的隐含波动率:"
tabstat implied_vol if iv_converged == 1, by(moneyness_grp) statistics(mean sd n)

* ============ 导出结果 ============
preserve
keep `market_price' `spot_var' `strike_var' `ttm_var' implied_vol moneyness iv_converged
export delimited using "table_TK09_implied_vol.csv", replace
display "SS_OUTPUT_FILE|file=table_TK09_implied_vol.csv|type=table|desc=iv_results"
restore

* ============ 生成波动率微笑图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成波动率微笑图"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway (scatter implied_vol moneyness if iv_converged == 1, mcolor(navy%50) msize(small)) ///
       (lpoly implied_vol moneyness if iv_converged == 1, lcolor(red) lwidth(medium)), ///
       xline(1, lcolor(gray) lpattern(dash)) ///
       legend(order(1 "隐含波动率" 2 "拟合曲线") position(6)) ///
       xtitle("价值状态 (S/K)") ytitle("隐含波动率") ///
       title("波动率微笑曲线") ///
       note("ATM=1.0")
graph export "fig_TK09_vol_smile.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK09_vol_smile.png|type=figure|desc=vol_smile"

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK09_iv.dta", replace
display "SS_OUTPUT_FILE|file=data_TK09_iv.dta|type=data|desc=iv_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK09 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  收敛:            " %10.0fc `n_converged'
display "  未收敛:          " %10.0fc `n_failed'
display ""
display "  隐含波动率统计:"
display "    均值:          " %10.4f `avg_iv' " (" %5.1f `=`avg_iv'*100' "%)"
display "    标准差:        " %10.4f `sd_iv'
display "    范围:          [" %6.4f `min_iv' ", " %6.4f `max_iv' "]"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = `n_failed'
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=avg_iv|value=`avg_iv'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=`n_dropped'"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK09|status=ok|elapsed_sec=`elapsed'"
log close
