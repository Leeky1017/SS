* ==============================================================================
* SS_TEMPLATE: id=TG14  level=L1  module=G  title="IV Weak Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG14_weak_iv_tests.csv type=table desc="Weak IV tests"
*   - table_TG14_critical_values.csv type=table desc="Critical values"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="ivregress + first-stage joint test"
* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* 方法 / Method: Stata-native weak-ID signals around `ivregress 2sls`
* 识别假设 / ID assumptions: instrument relevance is testable; exclusion is not (needs design)
* 诊断输出 / Diagnostics: excluded-instruments joint test + rule-of-thumb threshold (F>=10)
* SSC依赖 / SSC deps: removed (no `ivreg2`/`ranktest`; KP/Stock-Yogo need SSC tools)
* 解读要点 / Interpretation: F<10 is a warning flag; consider stronger instruments/robust checks

* ============ 初始化 ============
capture log close _all
if _rc != 0 {
    * Expected non-fatal return code
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TG14|level=L1|title=IV_Weak_Test"
display "SS_TASK_VERSION|version=2.1.0"

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
* ============ 数据加载 ============
capture confirm file "data.csv"
if _rc {
display "SS_RC|code=601|cmd=confirm_file|msg=file_not_found|detail=data.csv_not_found|file=data.csv|severity=fail"
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
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
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

local n_instruments : word count `valid_instruments'
local n_endog : word count `endog_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 弱工具变量检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 弱工具变量检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* First-stage regression + excluded-instruments joint test (weak-ID signal)
regress `endog_var' `valid_instruments' `valid_exog', robust
local excl_type = "F"
local excl_stat = .
local excl_p = .
local excl_df = .
capture noisily test `valid_instruments'
if _rc == 0 {
    capture local excl_stat = r(F)
    capture local excl_p = r(p)
    capture local excl_df = r(df)
    if `excl_stat' >= . {
        capture local excl_stat = r(chi2)
        capture local excl_p = r(p)
        capture local excl_df = r(df)
        local excl_type = "chi2"
    }
}

* 2SLS estimation (context) / 2SLS估计（用于上下文）
capture noisily ivregress 2sls `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), vce(robust)
if _rc {
display "SS_RC|code=430|cmd=ivregress_2sls|msg=ivregress_failed|detail=ivregress_failed_rc_`_rc'|severity=fail"
    log close
    exit 430
}

* Optional: built-in first-stage table in log
capture noisily estat firststage

display ""
display ">>> 弱工具变量检验结果 (Stata-native):"
display ""
display "1. 排除工具变量联合检验(`excl_type'): " %10.2f `excl_stat'
display "   p值: " %10.4f `excl_p'
display ""
display "2. 经验阈值: F >= 10 (rule-of-thumb; Staiger-Stock)"

display "SS_METRIC|name=excluded_inst_stat|value=`excl_stat'"

* ============ Stock-Yogo临界值 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 经验阈值比较 / Rule-of-thumb"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 经验阈值 (rule-of-thumb): 排除工具变量联合检验 F >= 10"
local weak_iv_conclusion = "信息:robust_wald_test"
if "`excl_type'" == "F" & `excl_stat' < . {
    if `excl_stat' >= 10 {
        local weak_iv_conclusion = "通过:F>=10"
    }
    else {
        local weak_iv_conclusion = "警告:F<10"
display "SS_RC|code=0|cmd=warning|msg=weak_iv|detail=Excluded_instruments_F__10|severity=warn"
    }
}

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出检验结果
preserve
clear
set obs 5
generate str40 test = ""
generate double statistic = .
generate double p_value = .
generate str50 conclusion = ""

replace test = "Excluded instruments (`excl_type')" in 1
replace statistic = `excl_stat' in 1
replace p_value = `excl_p' in 1
replace conclusion = "`weak_iv_conclusion'" in 1

replace test = "Observations" in 2
replace statistic = e(N) in 2

replace test = "Instruments (count)" in 3
replace statistic = `n_instruments' in 3

replace test = "Endogenous vars (count)" in 4
replace statistic = `n_endog' in 4

replace test = "Rule-of-thumb threshold" in 5
replace statistic = 10 in 5
replace conclusion = "F>=10 suggests not-too-weak (heuristic)" in 5

export delimited using "table_TG14_weak_iv_tests.csv", replace
display "SS_OUTPUT_FILE|file=table_TG14_weak_iv_tests.csv|type=table|desc=weak_iv_tests"
restore

* 导出临界值表
preserve
clear
set obs 2
generate str40 rule = ""
generate double threshold = .
generate str80 note = ""

replace rule = "Rule-of-thumb (Staiger-Stock)" in 1
replace threshold = 10 in 1
replace note = "Excluded-instruments F >= 10 suggests instruments not too weak (heuristic)" in 1

replace rule = "Design reminder" in 2
replace threshold = . in 2
replace note = "Exclusion restriction is not testable; rely on design + robustness checks" in 2

export delimited using "table_TG14_critical_values.csv", replace
display "SS_OUTPUT_FILE|file=table_TG14_critical_values.csv|type=table|desc=critical_values"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=excluded_inst_stat|value=`excl_stat'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG14 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:              " %10.0fc `n_input'
display "  工具变量数:          " %10.0fc `n_instruments'
display ""
display "  弱工具变量检验:"
display "    排除工具变量检验(`excl_type'): " %10.2f `excl_stat'
display "    结论:              `weak_iv_conclusion'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
local n_dropped = 0
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG14|status=ok|elapsed_sec=`elapsed'"
log close
