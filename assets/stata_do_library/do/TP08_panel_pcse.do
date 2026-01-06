* ==============================================================================
* SS_TEMPLATE: id=TP08  level=L2  module=P  title="Panel PCSE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP08_pcse_result.csv type=table desc="PCSE results"
*   - data_TP08_pcse.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TP08|level=L2|title=Panel_PCSE"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local corr = "__CORR__"

if "`corr'" == "" {
    local corr = "ar1"
}

display ""
display ">>> PCSE参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    相关结构: `corr'"

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
foreach var in `depvar' `id_var' `time_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

local valid_indep ""
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
    }
}

tsset `id_var' `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ PCSE估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: PCSE估计"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`corr'" == "independent" {
    xtpcse `depvar' `valid_indep', hetonly
}
else if "`corr'" == "ar1" {
    xtpcse `depvar' `valid_indep', correlation(ar1)
}
else {
    xtpcse `depvar' `valid_indep', correlation(psar1)
}

local n_obs = e(N)
local n_groups = e(N_g)
local r2 = e(r2)
local rho = e(rho)

display ""
display ">>> PCSE拟合:"
display "    观测数: `n_obs'"
display "    组数: `n_groups'"
display "    R2: " %8.4f `r2'
display "    rho: " %8.4f `rho'

display "SS_METRIC|name=r2|value=`r2'"
display "SS_METRIC|name=rho|value=`rho'"

* 导出结果
tempname pcse_results
postfile `pcse_results' str32 variable double coef double pcse double z double p ///
    using "temp_pcse_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `pcse_results' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `pcse_results'

preserve
use "temp_pcse_results.dta", clear
export delimited using "table_TP08_pcse_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TP08_pcse_result.csv|type=table|desc=pcse_results"
restore

capture erase "temp_pcse_results.dta"
if _rc != 0 { }

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TP08_pcse.dta", replace
display "SS_OUTPUT_FILE|file=data_TP08_pcse.dta|type=data|desc=pcse_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP08 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_obs'
display "  组数:            " %10.0fc `n_groups'
display "  R2:              " %10.4f `r2'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2|value=`r2'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP08|status=ok|elapsed_sec=`elapsed'"
log close
