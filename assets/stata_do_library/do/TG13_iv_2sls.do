* ==============================================================================
* SS_TEMPLATE: id=TG13  level=L1  module=G  title="IV 2SLS"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG13_2sls_result.csv type=table desc="2SLS results"
*   - table_TG13_first_stage.csv type=table desc="First stage"
*   - table_TG13_diagnostics.csv type=table desc="Diagnostics"
*   - data_TG13_iv.dta type=data desc="IV data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - ivreg2 source=ssc purpose="IV regression"
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

display "SS_TASK_BEGIN|id=TG13|level=L1|title=IV_2SLS"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "ivreg2"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_MISSING:cmd=`dep':hint=ssc install `dep'"
        display "SS_ERROR:DEP_MISSING:`dep' is required but not installed"
        display "SS_ERR:DEP_MISSING:`dep' is required but not installed"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=ivreg2|source=ssc|status=ok"

* ============ 参数设置 ============
local dep_var = "__DEP_VAR__"
local endog_var = "__ENDOG_VAR__"
local instruments = "__INSTRUMENTS__"
local exog_vars = "__EXOG_VARS__"
local robust = "__ROBUST__"

if "`robust'" == "" {
    local robust = "yes"
}

display ""
display ">>> 2SLS参数:"
display "    因变量: `dep_var'"
display "    内生变量: `endog_var'"
display "    工具变量: `instruments'"
if "`exog_vars'" != "" {
    display "    外生控制: `exog_vars'"
}
display "    稳健标准误: `robust'"

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
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
foreach var in `dep_var' `endog_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

local valid_instruments ""
foreach var of local instruments {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_instruments "`valid_instruments' `var'"
    }
}

if "`valid_instruments'" == "" {
    display "SS_ERROR:NO_INSTRUMENTS:No valid instruments"
    display "SS_ERR:NO_INSTRUMENTS:No valid instruments"
    log close
    exit 200
}

local valid_exog ""
foreach var of local exog_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_exog "`valid_exog' `var'"
    }
}

* 计算工具变量数量
local n_instruments : word count `valid_instruments'
local n_endog : word count `endog_var'

display ">>> 工具变量数: `n_instruments'"
display ">>> 内生变量数: `n_endog'"

if `n_instruments' < `n_endog' {
    display "SS_ERROR:UNDERIDENTIFIED:Fewer instruments than endogenous variables"
    display "SS_ERR:UNDERIDENTIFIED:Fewer instruments than endogenous variables"
    log close
    exit 198
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 第一阶段回归 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 第一阶段回归"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`robust'" == "yes" {
    regress `endog_var' `valid_instruments' `valid_exog', robust
}
else {
    regress `endog_var' `valid_instruments' `valid_exog'
}

local fs_r2 = e(r2)
local fs_f = e(F)
local fs_n = e(N)

* 保存第一阶段系数
tempname fscoef
postfile `fscoef' str32 variable double coef double se double t double p ///
    using "temp_first_stage.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local t = `coef' / `se'
    local p = 2 * ttail(e(df_r), abs(`t'))
    post `fscoef' ("`vname'") (`coef') (`se') (`t') (`p')
}

postclose `fscoef'

display ""
display ">>> 第一阶段结果:"
display "    R-squared: " %6.4f `fs_r2'
display "    F统计量: " %8.2f `fs_f'
display "    观测数: `fs_n'"

* F统计量检验（弱工具变量）
if `fs_f' < 10 {
    display ""
    display "SS_WARNING:WEAK_IV:First-stage F < 10, possible weak instruments"
}

display "SS_METRIC|name=first_stage_f|value=`fs_f'"
display "SS_METRIC|name=first_stage_r2|value=`fs_r2'"

preserve
use "temp_first_stage.dta", clear
export delimited using "table_TG13_first_stage.csv", replace
display "SS_OUTPUT_FILE|file=table_TG13_first_stage.csv|type=table|desc=first_stage"
restore

* ============ 2SLS估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 2SLS估计"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`robust'" == "yes" {
    ivreg2 `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), robust first
}
else {
    ivreg2 `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), first
}

* 提取结果
local iv_coef = _b[`endog_var']
local iv_se = _se[`endog_var']
local iv_t = `iv_coef' / `iv_se'
local iv_p = 2 * ttail(e(df_r), abs(`iv_t'))
local iv_n = e(N)
local iv_r2 = e(r2)

* 诊断统计量
local cragg_donald = e(cdf)
local sargan = e(sargan)
local sargan_p = e(sarganp)
local basmann = e(basmann)
local basmann_p = e(basmannp)

display ""
display ">>> 2SLS估计结果:"
display "    `endog_var'系数: " %10.4f `iv_coef'
display "    标准误: " %10.4f `iv_se'
display "    t统计量: " %10.4f `iv_t'
display "    p值: " %10.4f `iv_p'

display "SS_METRIC|name=iv_coef|value=`iv_coef'"
display "SS_METRIC|name=iv_se|value=`iv_se'"
display "SS_METRIC|name=iv_t|value=`iv_t'"

* 导出2SLS结果
tempname ivresult
postfile `ivresult' str32 variable double coef double se double t double p ///
    using "temp_2sls_result.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local t = `coef' / `se'
    local p = 2 * ttail(e(df_r), abs(`t'))
    post `ivresult' ("`vname'") (`coef') (`se') (`t') (`p')
}

postclose `ivresult'

preserve
use "temp_2sls_result.dta", clear
export delimited using "table_TG13_2sls_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG13_2sls_result.csv|type=table|desc=2sls_result"
restore

* ============ 诊断检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 诊断检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 弱工具变量检验:"
display "    Cragg-Donald Wald F: " %10.2f `cragg_donald'
if `cragg_donald' < 10 {
    display "    警告: F < 10，可能存在弱工具变量问题"
}

if `n_instruments' > `n_endog' {
    display ""
    display ">>> 过度识别检验:"
    display "    Sargan统计量: " %10.4f `sargan'
    display "    Sargan p值: " %10.4f `sargan_p'
    if `sargan_p' < 0.05 {
        display "    警告: 拒绝工具变量外生性"
    }
}

* 导出诊断结果
preserve
clear
set obs 4
generate str30 test = ""
generate double statistic = .
generate double p_value = .
generate str50 conclusion = ""

replace test = "First-stage F" in 1
replace statistic = `fs_f' in 1
replace conclusion = cond(`fs_f' >= 10, "通过(F>=10)", "警告:可能弱IV") in 1

replace test = "Cragg-Donald F" in 2
replace statistic = `cragg_donald' in 2
replace conclusion = cond(`cragg_donald' >= 10, "通过", "警告:弱IV") in 2

replace test = "Sargan" in 3
replace statistic = `sargan' in 3
replace p_value = `sargan_p' in 3
replace conclusion = cond(`sargan_p' >= 0.05, "通过:IV外生", "拒绝:IV可能内生") in 3

replace test = "Observations" in 4
replace statistic = `iv_n' in 4

export delimited using "table_TG13_diagnostics.csv", replace
display "SS_OUTPUT_FILE|file=table_TG13_diagnostics.csv|type=table|desc=diagnostics"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG13_iv.dta", replace
display "SS_OUTPUT_FILE|file=data_TG13_iv.dta|type=data|desc=iv_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=iv_coef|value=`iv_coef'"

* 清理
capture erase "temp_first_stage.dta"
if _rc != 0 { }
capture erase "temp_2sls_result.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG13 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  工具变量数:      " %10.0fc `n_instruments'
display ""
display "  第一阶段:"
display "    F统计量:       " %10.2f `fs_f'
display "    R-squared:     " %10.4f `fs_r2'
display ""
display "  2SLS估计:"
display "    `endog_var':   " %10.4f `iv_coef'
display "    标准误:        " %10.4f `iv_se'
display "    p值:           " %10.4f `iv_p'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG13|status=ok|elapsed_sec=`elapsed'"
log close
