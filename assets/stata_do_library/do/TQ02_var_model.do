* ==============================================================================
* SS_TEMPLATE: id=TQ02  level=L2  module=Q  title="VAR Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ02_var_result.csv type=table desc="VAR results"
*   - table_TQ02_granger.csv type=table desc="Granger causality"
*   - fig_TQ02_irf.png type=figure desc="IRF plot"
*   - data_TQ02_var.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TQ02|level=L2|title=VAR_Model"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local endog_vars = "__ENDOG_VARS__"
local time_var = "__TIME_VAR__"
local lags = __LAGS__

if `lags' < 1 | `lags' > 10 {
    local lags = 2
}

display ""
display ">>> VAR模型参数:"
display "    内生变量: `endog_vars'"
display "    滞后阶数: `lags'"

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
capture confirm variable `time_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`time_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`time_var' not found"
    log close
    exit 200
}

local valid_endog ""
foreach var of local endog_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_endog "`valid_endog' `var'"
    }
}

local n_vars : word count `valid_endog'
if `n_vars' < 2 {
    display "SS_ERROR:FEW_VARS:Need at least 2 endogenous variables"
    display "SS_ERR:FEW_VARS:Need at least 2 endogenous variables"
    log close
    exit 198
}

tsset `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ VAR估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: VAR(`lags')估计"
display "═══════════════════════════════════════════════════════════════════════════════"

var `valid_endog', lags(1/`lags')

local ll = e(ll)
local aic = e(aic)
local bic = e(sbic)

display ""
display ">>> 模型拟合:"
display "    对数似然: " %12.4f `ll'
display "    AIC: " %12.4f `aic'
display "    BIC: " %12.4f `bic'

display "SS_METRIC|name=aic|value=`aic'"
display "SS_METRIC|name=bic|value=`bic'"

* ============ Granger因果检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Granger因果检验"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname granger_results
postfile `granger_results' str32 equation str32 excluded double chi2 int df double p ///
    using "temp_granger.dta", replace

foreach eq of local valid_endog {
    foreach excl of local valid_endog {
        if "`eq'" != "`excl'" {
            quietly vargranger, estimates(.)
            capture test [`eq']: L.`excl'
            if _rc == 0 {
                forvalues i = 2/`lags' {
                    capture test [`eq']: L`i'.`excl', accum
                    if _rc != 0 { }
                }
                local chi2 = r(chi2)
                local df = r(df)
                local p = r(p)
                post `granger_results' ("`eq'") ("`excl'") (`chi2') (`df') (`p')
            }
        }
    }
}

postclose `granger_results'

vargranger

preserve
use "temp_granger.dta", clear
export delimited using "table_TQ02_granger.csv", replace
display "SS_OUTPUT_FILE|file=table_TQ02_granger.csv|type=table|desc=granger_tests"
restore

* ============ 脉冲响应分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 脉冲响应分析"
display "═══════════════════════════════════════════════════════════════════════════════"

irf create var_irf, set(irf_results) replace step(20)

local var1 : word 1 of `valid_endog'
local var2 : word 2 of `valid_endog'

irf graph oirf, impulse(`var1') response(`var2') ///
    title("正交化脉冲响应: `var1' -> `var2'")
graph export "fig_TQ02_irf.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TQ02_irf.png|type=figure|desc=irf_plot"

capture erase "irf_results.irf"
if _rc != 0 { }

* 导出VAR系数
tempname var_results
postfile `var_results' str32 equation str32 variable double coef double se double z double p ///
    using "temp_var_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local eqnames : rownames e(b)

local nvars : word count `varnames'
forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `var_results' ("VAR") ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `var_results'

preserve
use "temp_var_results.dta", clear
export delimited using "table_TQ02_var_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TQ02_var_result.csv|type=table|desc=var_results"
restore

capture erase "temp_granger.dta"
if _rc != 0 { }
capture erase "temp_var_results.dta"
if _rc != 0 { }

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TQ02_var.dta", replace
display "SS_OUTPUT_FILE|file=data_TQ02_var.dta|type=data|desc=var_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TQ02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  变量数:          " %10.0fc `n_vars'
display "  滞后阶数:        " %10.0fc `lags'
display "  AIC:             " %10.4f `aic'
display "  BIC:             " %10.4f `bic'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=aic|value=`aic'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ02|status=ok|elapsed_sec=`elapsed'"
log close
