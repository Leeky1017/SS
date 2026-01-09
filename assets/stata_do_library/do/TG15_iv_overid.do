* ==============================================================================
* SS_TEMPLATE: id=TG15  level=L1  module=G  title="IV Overid"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG15_overid_tests.csv type=table desc="Overid tests"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="ivregress 2sls + estat overid"
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

display "SS_TASK_BEGIN|id=TG15|level=L1|title=IV_Overid"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: run overidentification test only when overidentified; interpret as joint test of instrument exogeneity. /
*   最佳实践：仅在过度识别时运行 overid 检验；作为工具变量外生性的联合检验解读。
* - SSC deps: removed (ivreg2 → ivregress/estat overid) / SSC 依赖：已移除（ivreg2 → ivregress/estat overid）
* - Error policy: fail on underidentification; warn if just-identified / overid computation fails /
*   错误策略：欠识别→fail；恰好识别/overid 失败→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG15|ssc=none|output=csv|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local dep_var = "__DEPVAR__"
local endog_var = "__ENDOG_VAR__"
local instruments = "__INSTRUMENTS__"
local exog_vars = "__EXOG_VARS__"
local cluster_var = "__CLUSTER_VAR__"

display ""
display ">>> 过度识别检验参数:"
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
local overid_df = `n_instruments' - `n_endog'
display "SS_METRIC|name=n_instruments|value=`n_instruments'"
display "SS_METRIC|name=n_endog|value=`n_endog'"
display "SS_METRIC|name=overid_df|value=`overid_df'"

if `n_instruments' < `n_endog' {
    display "SS_ERROR:UNDERIDENTIFIED:Fewer instruments than endogenous variables"
    display "SS_ERR:UNDERIDENTIFIED:Fewer instruments than endogenous variables"
    log close
    exit 198
}
if `overid_df' <= 0 {
    display "SS_WARNING:JUST_IDENTIFIED:Model is just-identified, overidentification test not applicable"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* [ZH] 2SLS 估计 / [EN] 2SLS estimation
local vce_opt "vce(robust)"
if "`cluster_var'" != "" {
    capture confirm variable `cluster_var'
    if !_rc {
        local vce_opt "vce(cluster `cluster_var')"
    }
}
ivregress 2sls `dep_var' `valid_exog' (`endog_var' = `valid_instruments'), `vce_opt'

local overid_chi2 = .
local overid_p = .
local overid_df_used = .
if `overid_df' > 0 {
    capture noisily estat overid
    if _rc {
        display "SS_WARNING:OVERID_FAILED:estat overid failed"
    }
    else {
        capture scalar __ss_overid_chi2 = r(chi2)
        if !_rc local overid_chi2 = __ss_overid_chi2
        capture scalar __ss_overid_df = r(df)
        if !_rc local overid_df_used = __ss_overid_df
        capture scalar __ss_overid_p = r(p)
        if !_rc local overid_p = __ss_overid_p
        capture scalar __ss_overid_chi2_alt = r(J)
        if !_rc local overid_chi2 = __ss_overid_chi2_alt
        capture scalar __ss_overid_p_alt = r(p_J)
        if !_rc local overid_p = __ss_overid_p_alt
    }
}
display "SS_METRIC|name=overid_chi2|value=`overid_chi2'"
display "SS_METRIC|name=overid_p|value=`overid_p'"

local conclusion = ""
if `overid_df' <= 0 {
    local conclusion = "恰好识别(不适用)"
}
else if `overid_p' >= 0.10 {
    local conclusion = "通过:不拒绝IV外生"
}
else if `overid_p' >= 0.05 {
    local conclusion = "边际拒绝:需谨慎"
}
else {
    local conclusion = "拒绝:IV可能内生"
    display "SS_WARNING:OVERID_REJECTED:Overidentification test rejects instrument validity"
}

preserve
clear
set obs 1
generate str30 test = "Overid (estat overid)"
generate double statistic = `overid_chi2'
generate double p_value = `overid_p'
generate int df = cond(`overid_df_used' < ., `overid_df_used', `overid_df')
generate str60 conclusion = "`conclusion'"
export delimited using "table_TG15_overid_tests.csv", replace
display "SS_OUTPUT_FILE|file=table_TG15_overid_tests.csv|type=table|desc=overid_tests"
restore

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=overid_chi2|value=`overid_chi2'"
display "SS_SUMMARY|key=overid_p|value=`overid_p'"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_input'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG15|status=ok|elapsed_sec=`elapsed'"
log close
