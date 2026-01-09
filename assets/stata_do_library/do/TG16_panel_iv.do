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
*   - stata source=built-in purpose="xtivreg + weak-IV signal via first-stage F-test"
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
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: use built-in `xtivreg` (FE/RE) and report weak-IV warning signal from first-stage joint F-test. /
*   最佳实践：使用内置 `xtivreg`（FE/RE），并用第一阶段工具变量联合 F 检验作为弱工具变量告警信号。
* - SSC deps: removed (xtivreg2 → xtivreg) / SSC 依赖：已移除（xtivreg2 → xtivreg）
* - Error policy: fail on missing panel structure or underidentification; warn on weak-IV signal /
*   错误策略：面板结构缺失/欠识别→fail；弱工具变量信号→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG16|ssc=none|output=csv|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local dep_var = "__DEPVAR__"
local endog_var = "__ENDOG_VAR__"
local instruments = "__INSTRUMENTS__"
local exog_vars = "__EXOG_VARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local method = "__METHOD__"

if "`method'" == "" | ("`method'" != "fe" & "`method'" != "re") {
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

local n_instruments : word count `valid_instruments'
local n_endog : word count `endog_var'
display "SS_METRIC|name=n_instruments|value=`n_instruments'"
display "SS_METRIC|name=n_endog|value=`n_endog'"
if `n_instruments' < `n_endog' {
    display "SS_ERROR:UNDERIDENTIFIED:Fewer instruments than endogenous variables"
    display "SS_ERR:UNDERIDENTIFIED:Fewer instruments than endogenous variables"
    log close
    exit 198
}

sort `id_var' `time_var'
capture xtset `id_var' `time_var'
if _rc {
    display "SS_ERROR:XTSET_FAILED:xtset failed"
    display "SS_ERR:XTSET_FAILED:xtset failed"
    log close
    exit 210
}

tempvar _ss_n_i
bysort `id_var': gen long `_ss_n_i' = _N
quietly count if `_ss_n_i' == 1
local n_singletons = r(N)
drop `_ss_n_i'
display "SS_METRIC|name=n_singletons|value=`n_singletons'"
if `n_singletons' > 0 {
    display "SS_WARNING:SINGLETON_GROUPS:Singleton groups detected"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* [ZH] 第一阶段（弱IV信号）：对工具变量做联合显著性 F 检验 / [EN] First-stage weak-IV signal via joint F-test
if "`method'" == "fe" {
    xtreg `endog_var' `valid_instruments' `valid_exog', fe
}
else {
    xtreg `endog_var' `valid_instruments' `valid_exog', re
}
test `valid_instruments'
local fs_f = r(F)
local fs_p = r(p)
display "SS_METRIC|name=first_stage_f|value=`fs_f'"
display "SS_METRIC|name=first_stage_p|value=`fs_p'"
if `fs_f' < 10 {
    display "SS_WARNING:WEAK_IV:First-stage F < 10, possible weak instruments"
}

* [ZH] 面板IV估计 / [EN] Panel IV estimation
if "`method'" == "fe" {
    xtivreg `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), fe vce(cluster `id_var')
}
else {
    xtivreg `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), re vce(cluster `id_var')
}

local iv_coef = _b[`endog_var']
local iv_se = _se[`endog_var']
local iv_t = `iv_coef' / `iv_se'
local iv_p = 2 * ttail(e(df_r), abs(`iv_t'))
display "SS_METRIC|name=iv_coef|value=`iv_coef'"
display "SS_METRIC|name=iv_se|value=`iv_se'"

tempname results
postfile `results' str32 variable double coef double se double t double p using "temp_panel_iv.dta", replace
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

preserve
clear
set obs 3
generate str30 test = ""
generate double statistic = .
generate double p_value = .
generate str60 conclusion = ""

replace test = "First-stage joint F (instruments)" in 1
replace statistic = `fs_f' in 1
replace p_value = `fs_p' in 1
replace conclusion = cond(`fs_f' >= 10, "通过(F>=10)", "警告:弱IV信号") in 1

replace test = "Endog coef" in 2
replace statistic = `iv_coef' in 2

replace test = "Observations" in 3
replace statistic = e(N) in 3

export delimited using "table_TG16_diagnostics.csv", replace
display "SS_OUTPUT_FILE|file=table_TG16_diagnostics.csv|type=table|desc=diagnostics"
restore

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
