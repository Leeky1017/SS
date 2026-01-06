* ==============================================================================
* SS_TEMPLATE: id=TG16  level=L1  module=G  title="Panel IV"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG16_panel_iv.csv type=table desc="Panel IV results"
*   - table_TG16_diagnostics.csv type=table desc="Diagnostics"
*   - data_TG16_panel_iv.dta type=data desc="Panel IV data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - xtivreg2 source=ssc purpose="Panel IV"
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

display "SS_TASK_BEGIN|id=TG16|level=L1|title=Panel_IV"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "xtivreg2"
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
display "SS_DEP_CHECK|pkg=xtivreg2|source=ssc|status=ok"

* ============ 参数设置 ============
local dep_var = "__DEP_VAR__"
local endog_var = "__ENDOG_VAR__"
local instruments = "__INSTRUMENTS__"
local exog_vars = "__EXOG_VARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local method = "__METHOD__"

if "`method'" == "" | ("`method'" != "fe" & "`method'" != "re" & "`method'" != "ht") {
    local method = "fe"
}

display ""
display ">>> 面板IV参数:"
display "    因变量: `dep_var'"
display "    内生变量: `endog_var'"
display "    工具变量: `instruments'"
display "    ID变量: `id_var'"
display "    时间变量: `time_var'"
display "    估计方法: `method'"

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
foreach var in `dep_var' `endog_var' `id_var' `time_var' {
    capture confirm variable `var'
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

local valid_exog ""
foreach var of local exog_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_exog "`valid_exog' `var'"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 设置面板 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 设置面板结构"
display "═══════════════════════════════════════════════════════════════════════════════"

sort `id_var' `time_var'
ss_smart_xtset `id_var' `time_var'

quietly xtdescribe
local n_groups = r(n)
local n_periods = r(max)

display ""
display ">>> 面板结构:"
display "    个体数: `n_groups'"
display "    最大期数: `n_periods'"

display "SS_METRIC|name=n_groups|value=`n_groups'"

* ============ 面板IV估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 面板IV估计 (`method')"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`method'" == "fe" {
    display ">>> 使用固定效应IV (FE-2SLS)"
    xtivreg2 `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), fe robust first
}
else if "`method'" == "re" {
    display ">>> 使用随机效应IV (RE-2SLS)"
    xtivreg2 `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), re robust first
}
else {
    display ">>> 使用Hausman-Taylor估计"
    * HT需要区分时变/时不变、内生/外生
    capture xthtaylor `dep_var' `valid_exog' `endog_var', endog(`endog_var')
    if _rc {
        display "SS_WARNING:HT_FAILED:Hausman-Taylor failed, using FE-IV instead"
        xtivreg2 `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), fe robust first
    }
}

* 提取结果
local iv_coef = _b[`endog_var']
local iv_se = _se[`endog_var']
local iv_t = `iv_coef' / `iv_se'
local iv_p = 2 * ttail(e(df_r), abs(`iv_t'))
local iv_n = e(N)

* 诊断统计量
local cdf = e(cdf)
local widstat = e(widstat)
local hansen_j = e(j)
local hansen_p = e(jp)

display ""
display ">>> 面板IV估计结果:"
display "    `endog_var'系数: " %10.4f `iv_coef'
display "    标准误: " %10.4f `iv_se'
display "    t统计量: " %10.4f `iv_t'
display "    p值: " %10.4f `iv_p'

display "SS_METRIC|name=iv_coef|value=`iv_coef'"
display "SS_METRIC|name=iv_se|value=`iv_se'"

* ============ 诊断检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 诊断检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 弱工具变量检验:"
display "    Cragg-Donald F: " %10.2f `cdf'
display "    Kleibergen-Paap F: " %10.2f `widstat'

if `cdf' < 10 {
    display "    警告: F < 10，可能存在弱工具变量"
    display "SS_WARNING:WEAK_IV:F-statistic < 10"
}

display ""
display ">>> 过度识别检验:"
display "    Hansen J: " %10.4f `hansen_j'
display "    p值: " %10.4f `hansen_p'

* 导出结果
tempname results
postfile `results' str32 variable double coef double se double t double p ///
    using "temp_panel_iv.dta", replace

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
    post `results' ("`vname'") (`coef') (`se') (`t') (`p')
}

postclose `results'

preserve
use "temp_panel_iv.dta", clear
export delimited using "table_TG16_panel_iv.csv", replace
display "SS_OUTPUT_FILE|file=table_TG16_panel_iv.csv|type=table|desc=panel_iv"
restore

* 导出诊断
preserve
clear
set obs 4
generate str30 test = ""
generate double statistic = .
generate double p_value = .

replace test = "Cragg-Donald F" in 1
replace statistic = `cdf' in 1

replace test = "Kleibergen-Paap F" in 2
replace statistic = `widstat' in 2

replace test = "Hansen J" in 3
replace statistic = `hansen_j' in 3
replace p_value = `hansen_p' in 3

replace test = "N observations" in 4
replace statistic = `iv_n' in 4

export delimited using "table_TG16_diagnostics.csv", replace
display "SS_OUTPUT_FILE|file=table_TG16_diagnostics.csv|type=table|desc=diagnostics"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG16_panel_iv.dta", replace
display "SS_OUTPUT_FILE|file=data_TG16_panel_iv.dta|type=data|desc=panel_iv_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=iv_coef|value=`iv_coef'"

capture erase "temp_panel_iv.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG16 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  个体数:          " %10.0fc `n_groups'
display "  估计方法:        `method'"
display ""
display "  面板IV估计:"
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

display "SS_TASK_END|id=TG16|status=ok|elapsed_sec=`elapsed'"
log close
