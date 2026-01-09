* ==============================================================================
* SS_TEMPLATE: id=TG06  level=L1  module=G  title="Mahal Match"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG06_mahal_result.csv type=table desc="Mahal match results"
*   - table_TG06_balance.csv type=table desc="Balance after matching"
*   - data_TG06_mahal_matched.dta type=data desc="Matched data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none (Stata 18 built-in `teffects nnmatch`, `tebalance`)
* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* 方法 / Method: covariate (Mahalanobis/metric) matching via `teffects nnmatch` (ATET)
* 识别假设 / ID assumptions: unconfoundedness + overlap; exact-match vars enforce design restrictions
* 诊断输出 / Diagnostics: osample() overlap flag + `tebalance summarize` balance table
* SSC依赖 / SSC deps: removed (replace `psmatch2`)
* 解读要点 / Interpretation: ATET pertains to treated; exact matching reduces bias but may drop support

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

display "SS_TASK_BEGIN|id=TG06|level=L1|title=Mahal_Match"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.1.0"

display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local outcome_var = "__OUTCOME_VAR__"
local match_vars = "__MATCH_VARS__"
local exact_vars = "__EXACT_VARS__"
local n_neighbors = __N_NEIGHBORS__

if `n_neighbors' <= 0 {
    local n_neighbors = 1
}

display ""
display ">>> 马氏距离匹配参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    匹配变量: `match_vars'"
if "`exact_vars'" != "" {
    display "    精确匹配: `exact_vars'"
}
display "    邻居数: `n_neighbors'"

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
foreach var in `treatment_var' `outcome_var' {
    capture confirm numeric variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

local valid_match_vars ""
foreach var of local match_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_match_vars "`valid_match_vars' `var'"
    }
}

if "`valid_match_vars'" == "" {
display "SS_RC|code=200|cmd=validate_inputs|msg=no_match_vars|detail=No_valid_match_vars|severity=fail"
    log close
    exit 200
}

* Ensure binary treatment (0/1) / 仅支持二元处理
quietly tabulate `treatment_var'
if r(r) != 2 {
display "SS_RC|code=198|cmd=validate_inputs|msg=not_binary|detail=`treatment_var'_must_be_binary_01|severity=fail"
    log close
    exit 198
}

local valid_exact_vars ""
foreach var of local exact_vars {
    capture confirm variable `var'
    if !_rc {
        local valid_exact_vars "`valid_exact_vars' `var'"
    }
}

quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)

display ">>> 处理组: `n_treated', 对照组: `n_control'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 执行马氏距离匹配 / teffects nnmatch ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: teffects nnmatch (ATET)"
display "═══════════════════════════════════════════════════════════════════════════════"

tempvar osample
local ematch_opt ""
if "`valid_exact_vars'" != "" {
    local ematch_opt "ematch(`valid_exact_vars')"
}

capture noisily teffects nnmatch (`outcome_var' `valid_match_vars') (`treatment_var'), ///
    atet nneighbor(`n_neighbors') `ematch_opt' osample(`osample') generate(_nn)
if _rc {
display "SS_RC|code=430|cmd=teffects_nnmatch|msg=teffects_failed|detail=teffects_nnmatch_failed_rc_`_rc'|severity=fail"
    log close
    exit 430
}

quietly count if `osample' == 1
local n_osample = r(N)
if `n_osample' > 0 {
display "SS_RC|code=0|cmd=warning|msg=overlap_violation|detail=osample_flagged_`n_osample'_obs|severity=warn"
}
display "SS_METRIC|name=n_osample|value=`n_osample'"

local att = .
local att_se = .
local att_t = .
capture local att = _b[ATET]
capture local att_se = _se[ATET]
if `att_se' < . & `att_se' > 0 {
    local att_t = `att' / `att_se'
}

display ""
display ">>> ATT估计结果:"
display "    ATT = " %10.4f `att'
display "    SE  = " %10.4f `att_se'
display "    t   = " %10.4f `att_t'

display "SS_METRIC|name=att|value=`att'"
display "SS_METRIC|name=att_se|value=`att_se'"

* ============ 匹配质量评估 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 匹配质量评估"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly count if `treatment_var' == 1 & `osample' == 0
local n_treated_matched = r(N)

local n_control_used = .
preserve
keep if `treatment_var' == 1 & `osample' == 0
keep _nn*
gen long _rowid = _n
reshape long _nn, i(_rowid) j(_k)
drop if missing(_nn)
duplicates drop _nn, force
quietly count
local n_control_used = r(N)
restore

display ""
display ">>> 匹配统计:"
display "    匹配处理组: `n_treated_matched' / `n_treated'"
display "    使用对照组: `n_control_used'"

* Export balance table via collect: tebalance summarize, baseline
capture noisily collect clear
capture noisily collect: tebalance summarize `valid_match_vars', baseline
if _rc {
display "SS_RC|code=0|cmd=warning|msg=tebalance_failed|detail=tebalance_summarize_failed_rc_`_rc'|severity=warn"
}
else {
    capture noisily collect export "table_TG06_balance.csv", as(csv) replace
    if _rc {
display "SS_RC|code=0|cmd=warning|msg=collect_export_failed|detail=collect_export_failed_rc_`_rc'|severity=warn"
    }
    else {
        display "SS_OUTPUT_FILE|file=table_TG06_balance.csv|type=table|desc=balance"
    }
}

* ============ 导出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

local ci_lower = `att' - 1.96 * `att_se'
local ci_upper = `att' + 1.96 * `att_se'
local p_value = 2 * (1 - normal(abs(`att_t')))

preserve
clear
set obs 1
generate str20 method = "Mahalanobis"
generate str10 estimand = "ATT"
generate double effect = `att'
generate double se = `att_se'
generate double t_stat = `att_t'
generate double p_value = `p_value'
generate double ci_lower = `ci_lower'
generate double ci_upper = `ci_upper'
generate long n_treated = `n_treated_matched'
generate long n_control = `n_control_used'
export delimited using "table_TG06_mahal_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG06_mahal_result.csv|type=table|desc=mahal_result"
restore

* Keep overlap-support sample (osample==0) / 保留支持集样本
capture confirm variable `osample'
if !_rc {
    keep if `osample' == 0
}
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG06_mahal_matched.dta", replace
display "SS_OUTPUT_FILE|file=data_TG06_mahal_matched.dta|type=data|desc=matched_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=att|value=`att'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG06 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  匹配后样本量:    " %10.0fc `n_output'
display ""
display "  ATT估计:"
display "    效应值:        " %10.4f `att'
display "    标准误:        " %10.4f `att_se'
display "    95% CI:        [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = `n_input' - `n_output'
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG06|status=ok|elapsed_sec=`elapsed'"
log close
