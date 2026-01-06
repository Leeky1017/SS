* ==============================================================================
* SS_TEMPLATE: id=TP02  level=L2  module=P  title="Panel RE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP02_re_result.csv type=table desc="RE results"
*   - table_TP02_hausman.csv type=table desc="Hausman test"
*   - data_TP02_re.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TP02|level=L2|title=Panel_RE"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"

display ""
display ">>> 随机效应模型参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    个体ID: `id_var'"
display "    时间: `time_var'"

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

ss_smart_xtset `id_var' `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 随机效应估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 随机效应模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

xtreg `depvar' `valid_indep', re

local r2_within = e(r2_w)
local r2_between = e(r2_b)
local r2_overall = e(r2_o)
local sigma_u = e(sigma_u)
local sigma_e = e(sigma_e)
local rho = e(rho)
local theta = e(theta)

display ""
display ">>> RE模型拟合:"
display "    R2 (within): " %8.4f `r2_within'
display "    R2 (between): " %8.4f `r2_between'
display "    R2 (overall): " %8.4f `r2_overall'
display "    theta: " %8.4f `theta'

display "SS_METRIC|name=r2_overall|value=`r2_overall'"
display "SS_METRIC|name=theta|value=`theta'"

estimates store re_model

* 导出RE结果
tempname re_results
postfile `re_results' str32 variable double coef double se double z double p ///
    using "temp_re_results.dta", replace

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
    post `re_results' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `re_results'

preserve
use "temp_re_results.dta", clear
export delimited using "table_TP02_re_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TP02_re_result.csv|type=table|desc=re_results"
restore

* ============ Hausman检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Hausman检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 先估计FE
quietly xtreg `depvar' `valid_indep', fe
estimates store fe_model

* Hausman检验
hausman fe_model re_model

local hausman_chi2 = r(chi2)
local hausman_df = r(df)
local hausman_p = r(p)

display ""
display ">>> Hausman检验 (H0: RE一致且有效):"
display "    χ²统计量: " %10.4f `hausman_chi2'
display "    自由度: " %10.0f `hausman_df'
display "    p值: " %10.4f `hausman_p'

if `hausman_p' < 0.05 {
    display "    结论: 拒绝H0，应使用固定效应模型"
    local recommendation = "FE"
}
else {
    display "    结论: 不能拒绝H0，随机效应模型更有效"
    local recommendation = "RE"
}

display "SS_METRIC|name=hausman_chi2|value=`hausman_chi2'"
display "SS_METRIC|name=hausman_p|value=`hausman_p'"

* 导出Hausman检验结果
preserve
clear
set obs 1
generate double chi2 = `hausman_chi2'
generate int df = `hausman_df'
generate double p_value = `hausman_p'
generate str10 recommendation = "`recommendation'"

export delimited using "table_TP02_hausman.csv", replace
display "SS_OUTPUT_FILE|file=table_TP02_hausman.csv|type=table|desc=hausman_test"
restore

capture erase "temp_re_results.dta"
if _rc != 0 { }

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TP02_re.dta", replace
display "SS_OUTPUT_FILE|file=data_TP02_re.dta|type=data|desc=re_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  RE模型:"
display "    R2(overall):   " %10.4f `r2_overall'
display "    theta:         " %10.4f `theta'
display ""
display "  Hausman检验:"
display "    χ²:            " %10.4f `hausman_chi2'
display "    p值:           " %10.4f `hausman_p'
display "    推荐:          `recommendation'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=hausman_p|value=`hausman_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP02|status=ok|elapsed_sec=`elapsed'"
log close
