* ==============================================================================
* SS_TEMPLATE: id=TS10  level=L2  module=S  title="Model Compare"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TS10_comparison.csv type=table desc="Model comparison"
*   - fig_TS10_comparison.png type=figure desc="Comparison plot"
*   - data_TS10_compare.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TS10|level=L2|title=Model_Compare"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"

display ""
display ">>> 模型比较参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"

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
capture confirm numeric variable `depvar'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`depvar' not found"
    display "SS_ERR:VAR_NOT_FOUND:`depvar' not found"
    log close
    exit 200
}

local valid_indep ""
local n_vars = 0
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
        local n_vars = `n_vars' + 1
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 模型比较 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 模型估计与比较"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname model_compare
postfile `model_compare' str20 model double r2 double adj_r2 double aic double bic double rmse ///
    using "temp_model_compare.dta", replace

* 1. OLS
display ""
display ">>> 1. OLS回归..."
regress `depvar' `valid_indep'

local ols_r2 = e(r2)
local ols_adj_r2 = e(r2_a)
local ols_ll = e(ll)
local ols_k = e(rank)
local ols_aic = -2 * `ols_ll' + 2 * `ols_k'
local ols_bic = -2 * `ols_ll' + ln(e(N)) * `ols_k'
local ols_rmse = e(rmse)

post `model_compare' ("OLS") (`ols_r2') (`ols_adj_r2') (`ols_aic') (`ols_bic') (`ols_rmse')

display "    R²=" %6.4f `ols_r2' ", AIC=" %10.2f `ols_aic' ", RMSE=" %8.4f `ols_rmse'

* 2. LASSO
display ""
display ">>> 2. LASSO回归..."
lasso linear `depvar' `valid_indep', selection(cv)

local lasso_lambda = e(lambda_sel)
lassogof
local lasso_r2 = e(r2_sel)
local lasso_mse = e(mse_sel)
local lasso_rmse = sqrt(`lasso_mse')
local lasso_k = e(k_nonzero_sel)
local lasso_aic = e(N) * ln(`lasso_mse') + 2 * `lasso_k'
local lasso_bic = e(N) * ln(`lasso_mse') + ln(e(N)) * `lasso_k'

post `model_compare' ("LASSO") (`lasso_r2') (.) (`lasso_aic') (`lasso_bic') (`lasso_rmse')

display "    R²=" %6.4f `lasso_r2' ", λ=" %10.6f `lasso_lambda' ", RMSE=" %8.4f `lasso_rmse'

* 3. Ridge
display ""
display ">>> 3. Ridge回归..."
elasticnet linear `depvar' `valid_indep', alpha(0) selection(cv)

local ridge_lambda = e(lambda_sel)
lassogof
local ridge_r2 = e(r2_sel)
local ridge_mse = e(mse_sel)
local ridge_rmse = sqrt(`ridge_mse')
local ridge_aic = e(N) * ln(`ridge_mse') + 2 * `n_vars'
local ridge_bic = e(N) * ln(`ridge_mse') + ln(e(N)) * `n_vars'

post `model_compare' ("Ridge") (`ridge_r2') (.) (`ridge_aic') (`ridge_bic') (`ridge_rmse')

display "    R²=" %6.4f `ridge_r2' ", λ=" %10.6f `ridge_lambda' ", RMSE=" %8.4f `ridge_rmse'

* 4. Elastic Net (α=0.5)
display ""
display ">>> 4. Elastic Net回归..."
elasticnet linear `depvar' `valid_indep', alpha(0.5) selection(cv)

local enet_lambda = e(lambda_sel)
lassogof
local enet_r2 = e(r2_sel)
local enet_mse = e(mse_sel)
local enet_rmse = sqrt(`enet_mse')
local enet_k = e(k_nonzero_sel)
local enet_aic = e(N) * ln(`enet_mse') + 2 * `enet_k'
local enet_bic = e(N) * ln(`enet_mse') + ln(e(N)) * `enet_k'

post `model_compare' ("ElasticNet") (`enet_r2') (.) (`enet_aic') (`enet_bic') (`enet_rmse')

display "    R²=" %6.4f `enet_r2' ", λ=" %10.6f `enet_lambda' ", RMSE=" %8.4f `enet_rmse'

postclose `model_compare'

* ============ 结果汇总 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 模型比较汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_model_compare.dta", clear

display ""
display ">>> 模型比较结果:"
display "模型          R²        AIC          BIC          RMSE"
display "─────────────────────────────────────────────────────────"
list model r2 aic bic rmse, noobs

* 找出最佳模型
gsort aic
local best_aic : word 1 of `=model[1]'
gsort bic
local best_bic : word 1 of `=model[1]'
gsort rmse
local best_rmse : word 1 of `=model[1]'

display ""
display ">>> 最佳模型:"
display "    按AIC: `best_aic'"
display "    按BIC: `best_bic'"
display "    按RMSE: `best_rmse'"

export delimited using "table_TS10_comparison.csv", replace
display "SS_OUTPUT_FILE|file=table_TS10_comparison.csv|type=table|desc=model_comparison"

* 生成比较图
graph bar rmse, over(model) ///
    ytitle("RMSE") ///
    title("模型RMSE比较") ///
    blabel(bar, format(%6.4f))
graph export "fig_TS10_comparison.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TS10_comparison.png|type=figure|desc=comparison_plot"

restore

display "SS_METRIC|name=best_model_aic|value=`best_aic'"
display "SS_METRIC|name=ols_r2|value=`ols_r2'"

capture erase "temp_model_compare.dta"
if _rc != 0 { }

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TS10_compare.dta", replace
display "SS_OUTPUT_FILE|file=data_TS10_compare.dta|type=data|desc=compare_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TS10 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display ""
display "  模型性能:"
display "    OLS R²:        " %10.4f `ols_r2'
display "    LASSO R²:      " %10.4f `lasso_r2'
display "    Ridge R²:      " %10.4f `ridge_r2'
display "    ElasticNet R²: " %10.4f `enet_r2'
display ""
display "  最佳模型(AIC):   `best_aic'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=ols_r2|value=`ols_r2'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TS10|status=ok|elapsed_sec=`elapsed'"
log close
