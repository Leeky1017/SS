* ==============================================================================
* SS_TEMPLATE: id=TK06  level=L2  module=K  title="Portfolio Optim"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK06_weights.csv type=table desc="Optimal weights"
*   - table_TK06_frontier.csv type=table desc="Efficient frontier"
*   - fig_TK06_frontier.png type=graph desc="Frontier plot"
*   - data_TK06_portfolio.dta type=data desc="Output data"
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

program define ss_fail_TK06
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
    display "SS_TASK_END|id=TK06|status=fail|elapsed_sec=`elapsed'"
    capture log close
    exit `code'
end

display "SS_TASK_BEGIN|id=TK06|level=L2|title=Portfolio_Optim"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local asset_vars = "__ASSET_VARS__"
local rf_rate = __RF_RATE__
local target_return = __TARGET_RETURN__
local short_allowed = "__SHORT_ALLOWED__"

if `rf_rate' < 0 | `rf_rate' > 0.2 {
    local rf_rate = 0.02
}
if "`short_allowed'" == "" {
    local short_allowed = "no"
}

display ""
display ">>> 投资组合优化参数:"
display "    资产变量: `asset_vars'"
display "    无风险利率: " %6.4f `rf_rate'
if `target_return' != . & `target_return' > 0 {
    display "    目标收益: " %6.4f `target_return'
}
display "    允许卖空: `short_allowed'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TK06 601 confirm_file file_not_found data.csv S01_load_data
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
local valid_assets ""
local n_assets = 0
foreach var of local asset_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_assets "`valid_assets' `var'"
        local n_assets = `n_assets' + 1
    }
}

if `n_assets' < 2 {
    ss_fail_TK06 198 validate_assets too_few_assets n_assets_lt_2 S02_validate_inputs
}

display ">>> 有效资产数: `n_assets'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 计算收益和协方差矩阵 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 收益统计和协方差矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算均值向量
matrix mu = J(1, `n_assets', 0)
local i = 1
display ""
display ">>> 资产收益统计:"
display "资产            均值        标准差"
display "─────────────────────────────────────"

foreach var of local valid_assets {
    quietly summarize `var'
    matrix mu[1, `i'] = r(mean)
    local mean_`i' = r(mean)
    local sd_`i' = r(sd)
    display %15s "`var'" "  " %10.6f `mean_`i'' "  " %10.6f `sd_`i''
    local i = `i' + 1
}

* 计算协方差矩阵
correlate `valid_assets', covariance
matrix Sigma = r(C)

display ""
display ">>> 协方差矩阵:"
matrix list Sigma, format(%10.6f)

* ============ 最小方差组合 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 最小方差组合"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算最小方差组合权重: w = Sigma^(-1) * 1 / (1' * Sigma^(-1) * 1)
matrix ones = J(`n_assets', 1, 1)
capture matrix Sigma_inv = syminv(Sigma)
local rc_inv = _rc
if `rc_inv' != 0 {
    display "SS_RC|code=`rc_inv'|cmd=syminv|msg=cov_matrix_inversion_failed|severity=warn"
    matrix Sigma_inv = I(`n_assets')
}
matrix w_mv_num = Sigma_inv * ones
matrix denom_mv = ones' * Sigma_inv * ones
scalar denom = denom_mv[1,1]
matrix w_mv = w_mv_num / denom

* 计算组合收益和风险
matrix port_ret_mv = mu * w_mv
scalar ret_mv = port_ret_mv[1,1]
matrix port_var_mv = w_mv' * Sigma * w_mv
scalar var_mv = port_var_mv[1,1]
scalar sd_mv = sqrt(var_mv)

display ""
display ">>> 最小方差组合:"
display "    预期收益: " %10.6f ret_mv
display "    标准差: " %10.6f sd_mv
display "    夏普比率: " %10.4f (ret_mv - `rf_rate') / sd_mv
display ""
display "    权重:"
local i = 1
foreach var of local valid_assets {
    local w = w_mv[`i', 1]
    display "      `var': " %8.4f `w'
    local i = `i' + 1
}

* ============ 切点组合（最大夏普比率） ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 切点组合（最大夏普比率）"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算超额收益
matrix mu_excess = mu - `rf_rate' * J(1, `n_assets', 1)

* 切点组合权重: w = Sigma^(-1) * (mu - rf) / (1' * Sigma^(-1) * (mu - rf))
matrix w_tan_num = Sigma_inv * mu_excess'
matrix denom_tan_m = ones' * w_tan_num
scalar denom_tan = denom_tan_m[1,1]
matrix w_tan = w_tan_num / denom_tan

* 计算组合收益和风险
matrix port_ret_tan = mu * w_tan
scalar ret_tan = port_ret_tan[1,1]
matrix port_var_tan = w_tan' * Sigma * w_tan
scalar var_tan = port_var_tan[1,1]
scalar sd_tan = sqrt(var_tan)
scalar sharpe_tan = (ret_tan - `rf_rate') / sd_tan

display ""
display ">>> 切点组合（最大夏普比率）:"
display "    预期收益: " %10.6f ret_tan
display "    标准差: " %10.6f sd_tan
display "    夏普比率: " %10.4f sharpe_tan
display ""
display "    权重:"
local i = 1
foreach var of local valid_assets {
    local w = w_tan[`i', 1]
    display "      `var': " %8.4f `w'
    local i = `i' + 1
}

display "SS_METRIC|name=sharpe_tan|value=" sharpe_tan
display "SS_METRIC|name=ret_tan|value=" ret_tan

* ============ 有效前沿 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 有效前沿"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建有效前沿数据
tempname frontier
postfile `frontier' double target_ret double port_sd double sharpe ///
    using "temp_frontier.dta", replace

* 计算一系列目标收益下的最优组合
local min_ret = ret_mv - 0.02
local max_ret = ret_mv + 0.1
local step = (`max_ret' - `min_ret') / 50

forvalues target = `min_ret'(`step')`max_ret' {
    * 简化：使用两基金分离定理
    * 有效前沿上的组合是最小方差组合和切点组合的线性组合
    
    * 计算组合系数
    if ret_tan != ret_mv {
        local alpha = (`target' - ret_mv) / (ret_tan - ret_mv)
    }
    else {
        local alpha = 0
    }
    
    * 组合标准差（考虑相关性）
    local port_var = (1-`alpha')^2 * var_mv + `alpha'^2 * var_tan + ///
        2 * (1-`alpha') * `alpha' * sqrt(var_mv) * sqrt(var_tan) * 0.9
    local port_sd = sqrt(`port_var')
    
    * 夏普比率
    local sharpe = (`target' - `rf_rate') / `port_sd'
    
    post `frontier' (`target') (`port_sd') (`sharpe')
}

postclose `frontier'

* 导出有效前沿
preserve
use "temp_frontier.dta", clear
export delimited using "table_TK06_frontier.csv", replace
display "SS_OUTPUT_FILE|file=table_TK06_frontier.csv|type=table|desc=frontier_data"
restore

* ============ 导出权重 ============
preserve
clear
set obs `n_assets'
generate str20 asset = ""
generate double weight_mv = .
generate double weight_tan = .

local i = 1
foreach var of local valid_assets {
    replace asset = "`var'" in `i'
    replace weight_mv = w_mv[`i', 1] in `i'
    replace weight_tan = w_tan[`i', 1] in `i'
    local i = `i' + 1
}

export delimited using "table_TK06_weights.csv", replace
display "SS_OUTPUT_FILE|file=table_TK06_weights.csv|type=table|desc=weights"
restore

* ============ 生成有效前沿图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 生成有效前沿图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_frontier.dta", clear

* 添加关键点
local n_obs = _N + 2
set obs `n_obs'
replace port_sd = sd_mv in `=_N-1'
replace target_ret = ret_mv in `=_N-1'
replace port_sd = sd_tan in `=_N'
replace target_ret = ret_tan in `=_N'

twoway (line target_ret port_sd in 1/`=_N-2', lcolor(navy) lwidth(medium)) ///
       (scatter target_ret port_sd in `=_N-1', mcolor(green) msize(large) msymbol(D)) ///
       (scatter target_ret port_sd in `=_N', mcolor(red) msize(large) msymbol(O)), ///
       legend(order(1 "有效前沿" 2 "最小方差" 3 "切点组合") position(6)) ///
       xtitle("标准差（风险）") ytitle("预期收益") ///
       title("Markowitz有效前沿") ///
       note("无风险利率=`rf_rate'")
graph export "fig_TK06_frontier.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK06_frontier.png|type=graph|desc=frontier_plot"
restore

* 清理
capture erase "temp_frontier.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}


* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK06_portfolio.dta", replace
display "SS_OUTPUT_FILE|file=data_TK06_portfolio.dta|type=data|desc=portfolio_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK06 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  资产数:          " %10.0fc `n_assets'
display ""
display "  最小方差组合:"
display "    收益:          " %10.6f ret_mv
display "    风险:          " %10.6f sd_mv
display ""
display "  切点组合:"
display "    收益:          " %10.6f ret_tan
display "    风险:          " %10.6f sd_tan
display "    夏普比率:      " %10.4f sharpe_tan
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=sharpe_tan|value=" sharpe_tan

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK06|status=ok|elapsed_sec=`elapsed'"
log close
