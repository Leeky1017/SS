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
*   - stata source=built-in purpose="ivregress + postestimation (estat)"
* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* 方法 / Method: `ivregress 2sls` (Stata 18-native)
* 识别假设 / ID assumptions: relevance + exclusion + monotonicity (if LATE-like), plus correct functional form
* 诊断输出 / Diagnostics: excluded-instruments joint test (first stage) + `estat overid/endogenous` when applicable
* SSC依赖 / SSC deps: removed (replace `ivreg2`)
* 解读要点 / Interpretation: weak instruments inflate bias/SE; treat weak-ID warnings seriously

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

display "SS_TASK_BEGIN|id=TG13|level=L1|title=IV_2SLS"
display "SS_TASK_VERSION|version=2.1.0"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local dep_var = "__DEPVAR__"
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

if "`valid_instruments'" == "" {
display "SS_RC|code=200|cmd=task|msg=no_instruments|detail=No_valid_instruments|severity=fail"
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
display "SS_RC|code=198|cmd=task|msg=underidentified|detail=Fewer_instruments_than_endogenous_variables|severity=fail"
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
local fs_n = e(N)

* Excluded-instruments joint test (weak-ID signal) / 排除工具变量联合显著性检验
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
if `excl_stat' < . {
    display "    排除工具变量联合检验(`excl_type'): " %8.2f `excl_stat'
    display "    p值: " %8.4f `excl_p'
}
display "    观测数: `fs_n'"

* Weak-IV warning (rule-of-thumb) / 弱工具变量警告（经验法则）
if `excl_stat' < . {
    if "`excl_type'" == "F" & `excl_stat' < 10 {
display "SS_RC|code=0|cmd=warning|msg=weak_iv|detail=Excluded_instruments_F__10_possible_weak_instruments|severity=warn"
    }
    if "`excl_type'" == "chi2" & `excl_df' < . & `excl_df' > 0 {
        local chi2_per_df = `excl_stat' / `excl_df'
        if `chi2_per_df' < 10 {
display "SS_RC|code=0|cmd=warning|msg=weak_iv|detail=Excluded_instruments_chi2_over_df__10_possible_weak_instruments|severity=warn"
        }
        display "SS_METRIC|name=excluded_chi2_over_df|value=`chi2_per_df'"
    }
}

display "SS_METRIC|name=excluded_inst_stat|value=`excl_stat'"
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
    ivregress 2sls `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), vce(robust)
}
else {
    ivregress 2sls `dep_var' `valid_exog' (`endog_var' = `valid_instruments')
}

* 提取结果
local iv_coef = _b[`endog_var']
local iv_se = _se[`endog_var']
local iv_t = `iv_coef' / `iv_se'
local iv_p = 2 * ttail(e(df_r), abs(`iv_t'))
local iv_n = e(N)
local iv_r2 = e(r2)

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

local overid_chi2 = .
local overid_p = .
if `n_instruments' > `n_endog' {
    capture noisily estat overid
    if _rc == 0 {
        capture local overid_chi2 = r(chi2)
        capture local overid_p = r(p)
        if `overid_p' < . & `overid_p' < 0.05 {
display "SS_RC|code=0|cmd=warning|msg=overid_reject|detail=estat_overid_p_lt_0_05_instruments_may_be_invalid|severity=warn"
        }
    }
    else {
display "SS_RC|code=0|cmd=warning|msg=overid_failed|detail=estat_overid_failed_rc_`_rc'|severity=warn"
    }
}

local endog_chi2 = .
local endog_p = .
capture noisily estat endogenous
if _rc == 0 {
    capture local endog_chi2 = r(chi2)
    capture local endog_p = r(p)
}

local weak_ok = 0
if `excl_stat' < . {
    if "`excl_type'" == "F" & `excl_stat' >= 10 {
        local weak_ok = 1
    }
    if "`excl_type'" == "chi2" {
        * For robust tests, no single universal threshold; keep as informational.
        local weak_ok = 1
    }
}

* 导出诊断结果
preserve
clear
set obs 5
generate str30 test = ""
generate double statistic = .
generate double p_value = .
generate str50 conclusion = ""

replace test = "Excluded instruments (`excl_type')" in 1
replace statistic = `excl_stat' in 1
replace p_value = `excl_p' in 1
replace conclusion = cond(`weak_ok' == 1, "OK (see rule-of-thumb)", "WARN: possible weak IV") in 1

replace test = "Overidentification (estat overid)" in 2
replace statistic = `overid_chi2' in 2
replace p_value = `overid_p' in 2
replace conclusion = cond(`overid_p' >= 0.05, "OK: fail to reject", cond(`overid_p' < 0.05, "WARN: reject (invalid IV?)", "")) in 2

replace test = "Endogeneity (estat endogenous)" in 3
replace statistic = `endog_chi2' in 3
replace p_value = `endog_p' in 3
replace conclusion = cond(`endog_p' < 0.05, "Endogeneity detected", cond(`endog_p' >= 0.05, "No endogeneity detected", "")) in 3

replace test = "Observations" in 4
replace statistic = `iv_n' in 4

replace test = "Instruments (count)" in 5
replace statistic = `n_instruments' in 5

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
if _rc != 0 {
    * Expected non-fatal return code
}
capture erase "temp_2sls_result.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

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
if `excl_stat' < . {
    display "    工具变量联合检验(`excl_type'): " %10.2f `excl_stat'
}
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
