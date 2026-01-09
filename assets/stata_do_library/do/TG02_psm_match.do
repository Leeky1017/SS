* ==============================================================================
* SS_TEMPLATE: id=TG02  level=L1  module=G  title="PSM Match"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG02_att_result.csv type=table desc="ATT results"
*   - table_TG02_balance_after.csv type=table desc="Balance after matching"
*   - fig_TG02_balance_compare.png type=figure desc="Balance comparison"
*   - data_TG02_matched.dta type=data desc="Matched data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="teffects psmatch + overlap/balance diagnostics"
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

display "SS_TASK_BEGIN|id=TG02|level=L1|title=PSM_Match"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: prefer Stata 18 `teffects psmatch` for ATT; require overlap/common-support diagnostics + balance outputs. /
*   最佳实践：优先使用 Stata 18 `teffects psmatch` 估计 ATT；必须输出重叠/共同支撑诊断与平衡性结果。
* - SSC deps: removed (replaced psmatch2→teffects) / SSC 依赖：已移除（psmatch2→teffects）
* - Error policy: fail on missing vars / no treated/control / no overlap; warn on weak overlap or ignored options. /
*   错误策略：缺少变量/无处理或对照/无重叠→fail；重叠弱或参数被忽略→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG02|ssc=none|output=csv_png|policy=warn_fail"
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
local covariates = "__COVARIATES__"
local n_neighbors = __N_NEIGHBORS__
local caliper = __CALIPER__
local with_replace = "__WITH_REPLACE__"

if `n_neighbors' <= 0 {
    local n_neighbors = 1
}
if `caliper' <= 0 | `caliper' > 1 {
    local caliper = 0.05
}
if "`with_replace'" == "" {
    local with_replace = "yes"
}
if "`with_replace'" == "no" {
    display "SS_WARNING:OPTION_IGNORED:teffects psmatch does not support no-replacement matching; ignoring __WITH_REPLACE__=no"
    display "SS_RC|code=320|cmd=teffects psmatch|msg=with_replace_not_supported_ignored|severity=warn"
}

display ""
display ">>> PSM匹配参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    协变量: `covariates'"
display "    邻居数: `n_neighbors'"
display "    卡尺: `caliper'"

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

* [ZH] 变量检查 / [EN] Validate required variables
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

local valid_covariates ""
foreach var of local covariates {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_covariates "`valid_covariates' `var'"
    }
    else {
        display "SS_WARNING:COV_INVALID:`var' not found or not numeric"
    }
}
if "`valid_covariates'" == "" {
    display "SS_ERROR:NO_COVARIATES:No valid covariates"
    display "SS_ERR:NO_COVARIATES:No valid covariates"
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

* [ZH] 先做重叠诊断（logit 估计倾向得分区间交集） / [EN] Pre-check overlap via logit pscore range intersection
capture noisily logit `treatment_var' `valid_covariates'
if _rc {
    display "SS_ERROR:PSCORE_MODEL_FAILED:logit failed"
    display "SS_ERR:PSCORE_MODEL_FAILED:logit failed"
    log close
    exit 211
}
predict double pscore, pr
quietly summarize pscore if `treatment_var' == 1
local ps_t_min = r(min)
local ps_t_max = r(max)
quietly summarize pscore if `treatment_var' == 0
local ps_c_min = r(min)
local ps_c_max = r(max)
local ps_overlap_min = max(`ps_t_min', `ps_c_min')
local ps_overlap_max = min(`ps_t_max', `ps_c_max')
display "SS_METRIC|name=ps_overlap_min|value=`ps_overlap_min'"
display "SS_METRIC|name=ps_overlap_max|value=`ps_overlap_max'"
if `ps_overlap_min' >= `ps_overlap_max' {
    display "SS_ERROR:NO_OVERLAP:No overlap in propensity scores between treated and control"
    display "SS_ERR:NO_OVERLAP:No overlap in propensity scores between treated and control"
    log close
    exit 212
}
if (`ps_overlap_max' - `ps_overlap_min') < 0.05 {
    display "SS_WARNING:WEAK_OVERLAP:Overlap range is narrow; matching estimates may be unstable"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* [ZH] 使用 teffects psmatch 估计 ATT / [EN] Estimate ATT via teffects psmatch
local nn_stub "_ss_nn"
local osample_var "_ss_osample"
capture noisily teffects psmatch (`outcome_var') (`treatment_var' `valid_covariates'), ///
    atet nneighbor(`n_neighbors') caliper(`caliper') ///
    generate(`nn_stub') osample(`osample_var') vce(robust)
if _rc {
    display "SS_ERROR:PSMATCH_FAILED:teffects psmatch failed"
    display "SS_ERR:PSMATCH_FAILED:teffects psmatch failed"
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

* [ZH] 构造匹配后样本 + 匹配权重（按邻居出现次数计数） / [EN] Build matched sample + match weights (control frequency as neighbors)
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
display "SS_METRIC|name=n_treated_matched|value=`n_treated_matched'"
display "SS_METRIC|name=n_control_used|value=`n_control_used'"

* [ZH] 匹配后平衡性：标准化差异（匹配后对照组用 match_weight 加权） / [EN] Post-match balance: standardized differences (weighted controls)
tempname balance_after
postfile `balance_after' str32 variable double std_diff_before double std_diff_after double bias_reduction ///
    using "temp_balance_after.dta", replace

foreach var of local valid_covariates {
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

    local bias_reduction = 100
    if abs(`std_diff_before') > 1e-6 {
        local bias_reduction = (1 - abs(`std_diff_after') / abs(`std_diff_before')) * 100
    }
    post `balance_after' ("`var'") (`std_diff_before') (`std_diff_after') (`bias_reduction')
}
postclose `balance_after'

preserve
use "temp_balance_after.dta", clear
export delimited using "table_TG02_balance_after.csv", replace
display "SS_OUTPUT_FILE|file=table_TG02_balance_after.csv|type=table|desc=balance_after"

gen double abs_before = abs(std_diff_before)
gen double abs_after = abs(std_diff_after)
capture noisily graph bar abs_before abs_after, over(variable, sort(1) descending) ///
    bargap(10) legend(order(1 "Before" 2 "After")) ytitle("Abs. std. diff (%)") ///
    title("Covariate balance before vs after matching")
if _rc {
    display "SS_WARNING:GRAPH_FAILED:Could not generate balance graph"
}
else {
    graph export "fig_TG02_balance_compare.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG02_balance_compare.png|type=figure|desc=balance_compare"
}
restore

* [ZH] 导出 ATT 结果 / [EN] Export ATT result
preserve
clear
set obs 1
generate str20 estimand = "ATT"
generate double estimate = `att'
generate double std_err = `att_se'
generate double t_stat = `att_t'
generate double p_value = `att_p'
generate double ci_lower = `att' - 1.96 * `att_se'
generate double ci_upper = `att' + 1.96 * `att_se'
generate long n_treated = `n_treated_matched'
generate long n_control = `n_control_used'
generate int nneighbor = `n_neighbors'
generate double caliper = `caliper'
export delimited using "table_TG02_att_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG02_att_result.csv|type=table|desc=att_result"
restore

save "data_TG02_matched.dta", replace
display "SS_OUTPUT_FILE|file=data_TG02_matched.dta|type=data|desc=matched_data"

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

display "SS_TASK_END|id=TG02|status=ok|elapsed_sec=`elapsed'"
log close
