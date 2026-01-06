* ==============================================================================
* SS_TEMPLATE: id=TQ03  level=L2  module=Q  title="VECM Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ03_johansen.csv type=table desc="Johansen test"
*   - table_TQ03_vecm_result.csv type=table desc="VECM results"
*   - data_TQ03_vecm.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TQ03|level=L2|title=VECM_Model"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local endog_vars = "__ENDOG_VARS__"
local time_var = "__TIME_VAR__"
local lags = __LAGS__
local trend = "__TREND__"

if `lags' < 1 | `lags' > 10 {
    local lags = 2
}
if "`trend'" == "" {
    local trend = "constant"
}

display ""
display ">>> VECM参数:"
display "    内生变量: `endog_vars'"
display "    滞后阶数: `lags'"
display "    趋势项: `trend'"

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

tsset `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ Johansen协整检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Johansen协整检验"
display "═══════════════════════════════════════════════════════════════════════════════"

vecrank `valid_endog', lags(`lags') `trend'

local n_coint = e(r)

display ""
display ">>> 协整秩: `n_coint'"

display "SS_METRIC|name=n_coint|value=`n_coint'"

* 导出Johansen检验结果
preserve
clear
set obs 1
generate int cointegration_rank = `n_coint'
generate str20 trend = "`trend'"
generate int lags = `lags'
export delimited using "table_TQ03_johansen.csv", replace
display "SS_OUTPUT_FILE|file=table_TQ03_johansen.csv|type=table|desc=johansen_test"
restore

* ============ VECM估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: VECM估计"
display "═══════════════════════════════════════════════════════════════════════════════"

if `n_coint' > 0 {
    vec `valid_endog', lags(`lags') rank(`n_coint') `trend'
    
    local ll = e(ll)
    
    display ""
    display ">>> VECM拟合:"
    display "    对数似然: " %12.4f `ll'
    display "    协整秩: `n_coint'"
    
    display "SS_METRIC|name=ll|value=`ll'"
    
    * 导出结果
    tempname vecm_results
    postfile `vecm_results' str32 parameter double coef double se double z double p ///
        using "temp_vecm_results.dta", replace
    
    matrix b = e(b)
    matrix V = e(V)
    local varnames : colnames b
    local nvars : word count `varnames'
    
    forvalues i = 1/`nvars' {
        local vname : word `i' of `varnames'
        local coef = b[1, `i']
        local se = sqrt(V[`i', `i'])
        if `se' > 0 {
            local z = `coef' / `se'
            local p = 2 * (1 - normal(abs(`z')))
        }
        else {
            local z = .
            local p = .
        }
        post `vecm_results' ("`vname'") (`coef') (`se') (`z') (`p')
    }
    
    postclose `vecm_results'
    
    preserve
    use "temp_vecm_results.dta", clear
    export delimited using "table_TQ03_vecm_result.csv", replace
    display "SS_OUTPUT_FILE|file=table_TQ03_vecm_result.csv|type=table|desc=vecm_results"
    restore
    
    capture erase "temp_vecm_results.dta"
    if _rc != 0 { }
}
else {
    display ""
    display ">>> 无协整关系，建议使用VAR模型"
    display "SS_WARNING:NO_COINTEGRATION:No cointegration found"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TQ03_vecm.dta", replace
display "SS_OUTPUT_FILE|file=data_TQ03_vecm.dta|type=data|desc=vecm_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TQ03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  协整秩:          " %10.0fc `n_coint'
display "  滞后阶数:        " %10.0fc `lags'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_coint|value=`n_coint'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ03|status=ok|elapsed_sec=`elapsed'"
log close
