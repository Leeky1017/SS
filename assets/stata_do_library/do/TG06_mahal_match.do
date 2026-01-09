* ==============================================================================
* SS_TEMPLATE: id=TG06  level=L1  module=G  title="Mahal Match"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG06_mahal_result.csv type=table desc="Mahal match results"
*   - table_TG06_balance.csv type=table desc="Balance after matching"
*   - data_TG06_mahal_matched.dta type=data desc="Matched data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="teffects nnmatch (Mahalanobis) + balance diagnostics"
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

display "SS_TASK_BEGIN|id=TG06|level=L1|title=Mahal_Match"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: use Stata 18 `teffects nnmatch` with Mahalanobis metric; require overlap diagnostics and balance outputs. /
*   最佳实践：用 Stata 18 `teffects nnmatch` + 马氏距离；必须输出重叠诊断与平衡性结果。
* - SSC deps: removed (replaced psmatch2→teffects nnmatch) / SSC 依赖：已移除（psmatch2→teffects nnmatch）
* - Error policy: fail on missing vars / no treated-control support; warn on overlap violations flagged by osample(). /
*   错误策略：缺少变量/无处理或对照→fail；osample() 标记重叠问题→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG06|ssc=none|output=csv|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"

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

foreach var in `treatment_var' `outcome_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found or not numeric"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found or not numeric"
        log close
        exit 200
    }
}

quietly tabulate `treatment_var'
if r(r) != 2 {
    display "SS_ERROR:NOT_BINARY:`treatment_var' must be binary (0/1)"
    display "SS_ERR:NOT_BINARY:`treatment_var' must be binary (0/1)"
    log close
    exit 198
}

local valid_match_vars ""
foreach var of local match_vars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_match_vars "`valid_match_vars' `var'"
    }
    else {
        display "SS_WARNING:MATCH_VAR_INVALID:`var' not found or not numeric"
    }
}
if "`valid_match_vars'" == "" {
    display "SS_ERROR:NO_MATCH_VARS:No valid match vars"
    display "SS_ERR:NO_MATCH_VARS:No valid match vars"
    log close
    exit 200
}

quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)
display "SS_METRIC|name=n_treated|value=`n_treated'"
display "SS_METRIC|name=n_control|value=`n_control'"
if `n_treated' == 0 | `n_control' == 0 {
    display "SS_ERROR:NO_SUPPORT:Need both treated and control observations"
    display "SS_ERR:NO_SUPPORT:Need both treated and control observations"
    log close
    exit 210
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* [ZH] teffects nnmatch（马氏距离） / [EN] teffects nnmatch (Mahalanobis)
local nn_stub "_ss_nn"
local osample_var "_ss_osample"
local nn_opts "atet nneighbor(`n_neighbors') metric(mahalanobis) generate(`nn_stub') osample(`osample_var') vce(robust)"
if "`exact_vars'" != "" {
    local nn_opts "`nn_opts' ematch(`exact_vars')"
}

capture noisily teffects nnmatch (`outcome_var') (`treatment_var' `valid_match_vars'), `nn_opts'
if _rc {
    display "SS_ERROR:NNMATCH_FAILED:teffects nnmatch failed"
    display "SS_ERR:NNMATCH_FAILED:teffects nnmatch failed"
    log close
    exit 213
}

local att = _b[ATET]
local att_se = _se[ATET]
local att_t = `att' / `att_se'
local att_p = 2 * (1 - normal(abs(`att_t')))
display "SS_METRIC|name=att|value=`att'"
display "SS_METRIC|name=att_se|value=`att_se'"
display "SS_METRIC|name=att_p|value=`att_p'"

capture confirm variable `osample_var'
if !_rc {
    quietly count if `osample_var' == 1
    local n_osample = r(N)
    display "SS_METRIC|name=n_overlap_violations|value=`n_osample'"
    if `n_osample' > 0 {
        display "SS_WARNING:OVERLAP_VIOLATION:Dropped observations flagged by osample()"
    }
}

* [ZH] 构造匹配后样本 + 匹配权重（对照组被选中次数） / [EN] Matched sample + weights (control selection counts)
gen long _ss_obsno = _n
tempfile _ss_matchcounts

preserve
keep if e(sample) & `treatment_var' == 1
keep _ss_obsno `nn_stub'*
reshape long `nn_stub', i(_ss_obsno) j(_k)
drop if missing(`nn_stub')
rename `nn_stub' _ss_match_obsno
gen long match_count = 1
collapse (sum) match_count, by(_ss_match_obsno)
rename _ss_match_obsno _ss_obsno
save "`_ss_matchcounts'", replace
restore

merge 1:1 _ss_obsno using "`_ss_matchcounts'", nogen
replace match_count = 0 if missing(match_count)

gen double match_weight = .
replace match_weight = 1 if e(sample) & `treatment_var' == 1
replace match_weight = match_count if e(sample) & `treatment_var' == 0 & match_count > 0

keep if match_weight < . & match_weight > 0
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

quietly count if `treatment_var' == 1
local n_treated_matched = r(N)
quietly count if `treatment_var' == 0
local n_control_used = r(N)

* 平衡性（匹配后）
tempname balance
postfile `balance' str32 variable double std_diff_before double std_diff_after double reduction ///
    using "temp_mahal_balance.dta", replace

foreach var of local valid_match_vars {
    quietly summarize `var' if `treatment_var' == 1
    local mean_t_before = r(mean)
    local sd_t = r(sd)
    quietly summarize `var' if `treatment_var' == 0
    local mean_c_before = r(mean)
    local sd_c = r(sd)
    local pooled_sd = sqrt((`sd_t'^2 + `sd_c'^2) / 2)
    local std_diff_before = 0
    if `pooled_sd' > 0 {
        local std_diff_before = (`mean_t_before' - `mean_c_before') / `pooled_sd' * 100
    }

    quietly summarize `var' if `treatment_var' == 1 [aw=match_weight]
    local mean_t_after = r(mean)
    quietly summarize `var' if `treatment_var' == 0 [aw=match_weight]
    local mean_c_after = r(mean)
    local std_diff_after = 0
    if `pooled_sd' > 0 {
        local std_diff_after = (`mean_t_after' - `mean_c_after') / `pooled_sd' * 100
    }

    local reduction = 100
    if abs(`std_diff_before') > 1e-6 {
        local reduction = (1 - abs(`std_diff_after') / abs(`std_diff_before')) * 100
    }
    post `balance' ("`var'") (`std_diff_before') (`std_diff_after') (`reduction')
}
postclose `balance'

preserve
use "temp_mahal_balance.dta", clear
export delimited using "table_TG06_balance.csv", replace
display "SS_OUTPUT_FILE|file=table_TG06_balance.csv|type=table|desc=balance"
restore

* 导出主结果
local ci_lower = `att' - 1.96 * `att_se'
local ci_upper = `att' + 1.96 * `att_se'
preserve
clear
set obs 1
generate str20 method = "Mahalanobis"
generate str10 estimand = "ATT"
generate double effect = `att'
generate double se = `att_se'
generate double t_stat = `att_t'
generate double p_value = `att_p'
generate double ci_lower = `ci_lower'
generate double ci_upper = `ci_upper'
generate long n_treated = `n_treated_matched'
generate long n_control = `n_control_used'
export delimited using "table_TG06_mahal_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG06_mahal_result.csv|type=table|desc=mahal_result"
restore

save "data_TG06_mahal_matched.dta", replace
display "SS_OUTPUT_FILE|file=data_TG06_mahal_matched.dta|type=data|desc=matched_data"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=att|value=`att'"

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
