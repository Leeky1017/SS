* ==============================================================================
* SS_TEMPLATE: id=TG14  level=L1  module=G  title="IV Weak Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG14_weak_iv_tests.csv type=table desc="Weak IV tests"
*   - table_TG14_critical_values.csv type=table desc="Critical values"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="first-stage diagnostics + ivregress (optional)"
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

display "SS_TASK_BEGIN|id=TG14|level=L1|title=IV_Weak_Test"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: report first-stage joint F-statistic on instruments; warn if F<10 (rule-of-thumb). /
*   最佳实践：报告第一阶段工具变量联合显著性的 F 统计量；若 F<10 则提示弱工具变量风险。
* - SSC deps: removed (ivreg2/ranktest → built-in diagnostics) / SSC 依赖：已移除（ivreg2/ranktest → 内置诊断）
* - Error policy: fail on underidentification (no valid instruments); warn on weak-IV signals /
*   错误策略：无有效工具变量→fail；弱工具变量信号→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG14|ssc=none|output=csv|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local dep_var = "__DEPVAR__"
local endog_var = "__ENDOG_VAR__"
local instruments = "__INSTRUMENTS__"
local exog_vars = "__EXOG_VARS__"

display ""
display ">>> 弱工具变量检验参数:"
display "    因变量: `dep_var'"
display "    内生变量: `endog_var'"
display "    工具变量: `instruments'"

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
foreach var in `dep_var' `endog_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found or not numeric"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found or not numeric"
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
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* [ZH] 第一阶段：内生变量对工具变量(及外生控制)的回归，并对工具变量联合显著性做 F 检验 /
* [EN] First stage: regress endog on instruments (+ exog) and test joint significance of instruments
regress `endog_var' `valid_instruments' `valid_exog', robust
test `valid_instruments'
local fs_f = r(F)
local fs_df1 = r(df)
local fs_df2 = r(df_r)
local fs_p = r(p)

display "SS_METRIC|name=first_stage_f|value=`fs_f'"
display "SS_METRIC|name=first_stage_p|value=`fs_p'"

if `fs_f' < 10 {
    display "SS_WARNING:WEAK_IV:First-stage F < 10, possible weak instruments"
}

* [ZH] Stock-Yogo 临界值（简化展示；严格临界值依赖内生变量数与工具变量数） /
* [EN] Stock-Yogo critical values (simplified display; exact values depend on design)
local cv_10 = .
if `n_instruments' == 1 {
    local cv_10 = 16.38
}
else if `n_instruments' == 2 {
    local cv_10 = 19.93
}
else if `n_instruments' == 3 {
    local cv_10 = 22.30
}
else {
    local cv_10 = 16 + `n_instruments'
}

local weak_iv_conclusion = ""
if `fs_f' >= `cv_10' {
    local weak_iv_conclusion = "通过:>=Stock-Yogo(10%)"
}
else if `fs_f' >= 10 {
    local weak_iv_conclusion = "可接受:F>=10"
}
else {
    local weak_iv_conclusion = "警告:F<10(弱IV风险)"
}

preserve
clear
set obs 2
generate str40 test = ""
generate double statistic = .
generate double p_value = .
generate str60 conclusion = ""

replace test = "First-stage joint F (instruments)" in 1
replace statistic = `fs_f' in 1
replace p_value = `fs_p' in 1
replace conclusion = "`weak_iv_conclusion'" in 1

replace test = "Stock-Yogo (10% max bias) critical value (approx)" in 2
replace statistic = `cv_10' in 2
replace conclusion = "Reference only" in 2

export delimited using "table_TG14_weak_iv_tests.csv", replace
display "SS_OUTPUT_FILE|file=table_TG14_weak_iv_tests.csv|type=table|desc=weak_iv_tests"
restore

preserve
clear
set obs 4
generate str20 max_bias = ""
generate double n_iv_1 = .
generate double n_iv_2 = .
generate double n_iv_3 = .

replace max_bias = "10%" in 1
replace n_iv_1 = 16.38 in 1
replace n_iv_2 = 19.93 in 1
replace n_iv_3 = 22.30 in 1

replace max_bias = "15%" in 2
replace n_iv_1 = 8.96 in 2
replace n_iv_2 = 11.59 in 2
replace n_iv_3 = 12.83 in 2

replace max_bias = "20%" in 3
replace n_iv_1 = 6.66 in 3
replace n_iv_2 = 8.75 in 3
replace n_iv_3 = 9.54 in 3

replace max_bias = "25%" in 4
replace n_iv_1 = 5.53 in 4
replace n_iv_2 = 7.25 in 4
replace n_iv_3 = 7.80 in 4

export delimited using "table_TG14_critical_values.csv", replace
display "SS_OUTPUT_FILE|file=table_TG14_critical_values.csv|type=table|desc=critical_values"
restore

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=first_stage_f|value=`fs_f'"
display "SS_SUMMARY|key=weak_iv|value=`weak_iv_conclusion'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_input'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG14|status=ok|elapsed_sec=`elapsed'"
log close
