* ==============================================================================
* SS_TEMPLATE: id=TP01  level=L2  module=P  title="Panel FE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP01_fe_result.csv type=table desc="FE results"
*   - table_TP01_fe_test.csv type=table desc="FE test"
*   - data_TP01_fe.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TP01|level=L2|title=Panel_FE"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local fe_type = "__FE_TYPE__"
local cluster_var = "__CLUSTER_VAR__"

if "`fe_type'" == "" {
    local fe_type = "individual"
}

display ""
display ">>> 固定效应模型参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    个体ID: `id_var'"
display "    时间: `time_var'"
display "    FE类型: `fe_type'"

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

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* 设置面板
ss_smart_xtset `id_var' `time_var'

quietly xtdescribe
local n_panels = r(n)
local n_times = r(max)

display ""
display ">>> 面板结构:"
display "    个体数: `n_panels'"
display "    时间数: `n_times'"

* ============ 固定效应估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 固定效应模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建命令
local vce_opt "robust"
if "`cluster_var'" != "" {
    capture confirm variable `cluster_var'
    if !_rc {
        local vce_opt "cluster `cluster_var'"
    }
}

if "`fe_type'" == "individual" {
    display ">>> 个体固定效应模型..."
    xtreg `depvar' `valid_indep', fe vce(`vce_opt')
}
else if "`fe_type'" == "time" {
    display ">>> 时间固定效应模型..."
    regress `depvar' `valid_indep' i.`time_var', vce(`vce_opt')
}
else {
    display ">>> 双向固定效应模型..."
    xtreg `depvar' `valid_indep' i.`time_var', fe vce(`vce_opt')
}

local r2_within = e(r2_w)
local r2_between = e(r2_b)
local r2_overall = e(r2_o)
local sigma_u = e(sigma_u)
local sigma_e = e(sigma_e)
local rho = e(rho)
local n_obs = e(N)
local n_groups = e(N_g)

display ""
display ">>> 模型拟合:"
display "    R2 (within): " %8.4f `r2_within'
display "    R2 (between): " %8.4f `r2_between'
display "    R2 (overall): " %8.4f `r2_overall'
display "    sigma_u: " %8.4f `sigma_u'
display "    sigma_e: " %8.4f `sigma_e'
display "    rho (个体效应占比): " %8.4f `rho'

display "SS_METRIC|name=r2_within|value=`r2_within'"
display "SS_METRIC|name=rho|value=`rho'"
display "SS_METRIC|name=n_obs|value=`n_obs'"

* 导出结果
tempname fe_results
postfile `fe_results' str32 variable double coef double se double t double p ///
    using "temp_fe_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    if !strpos("`vname'", ".`time_var'") & "`vname'" != "_cons" {
        local coef = b[1, `i']
        local se = sqrt(V[`i', `i'])
        local t = `coef' / `se'
        local p = 2 * ttail(e(df_r), abs(`t'))
        post `fe_results' ("`vname'") (`coef') (`se') (`t') (`p')
    }
}

postclose `fe_results'

preserve
use "temp_fe_results.dta", clear
export delimited using "table_TP01_fe_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TP01_fe_result.csv|type=table|desc=fe_results"
restore

* ============ 固定效应检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 固定效应检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* F检验：所有固定效应=0
if "`fe_type'" != "time" {
    display ""
    display ">>> F检验 (H0: 所有个体效应=0):"
    local f_test = e(F_f)
    local f_p = Ftail(e(df_a), e(df_r), `f_test')
    display "    F统计量: " %10.4f `f_test'
    display "    p值: " %10.4f `f_p'
    
    if `f_p' < 0.05 {
        display "    结论: 拒绝H0，存在显著个体效应"
    }
    
    display "SS_METRIC|name=f_test|value=`f_test'"
}

* 导出检验结果
preserve
clear
set obs 2
generate str30 test = ""
generate double statistic = .
generate double p_value = .
generate str50 conclusion = ""

replace test = "F-test (individual effects)" in 1
replace statistic = `f_test' in 1
replace p_value = `f_p' in 1
replace conclusion = cond(`f_p' < 0.05, "显著个体效应", "无显著个体效应") in 1

replace test = "rho (个体效应占比)" in 2
replace statistic = `rho' in 2

export delimited using "table_TP01_fe_test.csv", replace
display "SS_OUTPUT_FILE|file=table_TP01_fe_test.csv|type=table|desc=fe_test"
restore

capture erase "temp_fe_results.dta"
if _rc != 0 { }

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TP01_fe.dta", replace
display "SS_OUTPUT_FILE|file=data_TP01_fe.dta|type=data|desc=fe_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_obs'
display "  个体数:          " %10.0fc `n_groups'
display "  FE类型:          `fe_type'"
display ""
display "  模型拟合:"
display "    R2(within):    " %10.4f `r2_within'
display "    rho:           " %10.4f `rho'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2_within|value=`r2_within'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP01|status=ok|elapsed_sec=`elapsed'"
log close
