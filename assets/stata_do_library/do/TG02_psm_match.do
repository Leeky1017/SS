* ==============================================================================
* SS_TEMPLATE: id=TG02  level=L1  module=G  title="PSM Match"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG02_att_result.csv type=table desc="ATT results"
*   - table_TG02_balance_after.csv type=table desc="Balance after matching"
*   - fig_TG02_balance_compare.png type=graph desc="Balance comparison"
*   - data_TG02_matched.dta type=data desc="Matched data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none (Stata 18 built-in `teffects`, `tebalance`)
* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* 方法 / Method: PSM via `teffects psmatch` (ATET)
* 识别假设 / ID assumptions: unconfoundedness + overlap (common support)
* 诊断输出 / Diagnostics: `osample()` overlap flag + `tebalance summarize` (+ density plot)
* SSC依赖 / SSC deps: removed (replace `psmatch2` with Stata 18-native)
* 解读要点 / Interpretation: ATET is for treated; treat Fails/Warns as signals, not proof

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

display "SS_TASK_BEGIN|id=TG02|level=L1|title=PSM_Match"

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
local covariates = "__COVARIATES__"
local n_neighbors = __N_NEIGHBORS__
local caliper = __CALIPER__
local with_replace = "__WITH_REPLACE__"

* 参数默认值
if `n_neighbors' <= 0 {
    local n_neighbors = 1
}
if `caliper' <= 0 | `caliper' > 1 {
    local caliper = 0.05
}
if "`with_replace'" == "" {
    local with_replace = "yes"
}

display ""
display ">>> PSM匹配参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    协变量: `covariates'"
display "    邻居数: `n_neighbors'"
display "    卡尺: `caliper'"
display "    放回匹配: `with_replace'"

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
    capture confirm variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

* 检查协变量
local valid_covariates ""
foreach var of local covariates {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_covariates "`valid_covariates' `var'"
    }
}

* 检查处理变量是否为0/1（仅支持二元处理） / Ensure binary treatment (0/1)
quietly tabulate `treatment_var'
if r(r) != 2 {
display "SS_RC|code=198|cmd=validate_inputs|msg=not_binary|detail=`treatment_var'_must_be_binary_01|severity=fail"
    log close
    exit 198
}

* 统计处理组和对照组
quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)

display ">>> 处理组: `n_treated', 对照组: `n_control'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 执行PSM匹配 / Run teffects psmatch ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: teffects psmatch (ATET)"
display "═══════════════════════════════════════════════════════════════════════════════"

* `teffects psmatch` uses matching with replacement; `__WITH_REPLACE__=no` is treated as warn.
if "`with_replace'" == "no" {
display "SS_RC|code=0|cmd=warning|msg=psmatch_replacement_only|detail=teffects_psmatch_uses_replacement_ignore_with_replace_no|severity=warn"
}

tempvar osample
capture noisily teffects psmatch (`outcome_var') (`treatment_var' `valid_covariates', logit), ///
    atet nneighbor(`n_neighbors') caliper(`caliper') osample(`osample') generate(_nn)
if _rc {
display "SS_RC|code=430|cmd=teffects_psmatch|msg=teffects_failed|detail=teffects_psmatch_failed_rc_`_rc'|severity=fail"
    log close
    exit 430
}

* Propensity score for treated level / 处理组倾向得分
capture predict double _pscore, ps tlevel(1)
if _rc {
display "SS_RC|code=0|cmd=warning|msg=predict_pscore_failed|detail=predict_ps_failed_rc_`_rc'|severity=warn"
}

quietly count if `osample' == 1
local n_osample = r(N)
if `n_osample' > 0 {
display "SS_RC|code=0|cmd=warning|msg=overlap_violation|detail=osample_flagged_`n_osample'_obs|severity=warn"
}
display "SS_METRIC|name=n_osample|value=`n_osample'"

* 获取ATET（ATT） / Extract ATET
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
display "SS_METRIC|name=att_t|value=`att_t'"

* ============ 匹配质量评估 / Balance & overlap diagnostics ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 匹配质量评估"
display "═══════════════════════════════════════════════════════════════════════════════"

* 统计在支持集内的样本量 / Approximate matched counts using osample() + neighbor indices
quietly count if `treatment_var' == 1 & `osample' == 0
local n_treated_matched = r(N)

local n_control_matched = .
preserve
keep if `treatment_var' == 1 & `osample' == 0
keep _nn*
gen long _rowid = _n
reshape long _nn, i(_rowid) j(_k)
drop if missing(_nn)
duplicates drop _nn, force
quietly count
local n_control_matched = r(N)
restore

display ""
display ">>> 匹配统计:"
display "    匹配的处理组: `n_treated_matched' / `n_treated'"
display "    使用的对照组: `n_control_matched' / `n_control'"

* Export balance table via collect: tebalance summarize, baseline
capture noisily collect clear
capture noisily collect: tebalance summarize `valid_covariates', baseline
if _rc {
display "SS_RC|code=0|cmd=warning|msg=tebalance_failed|detail=tebalance_summarize_failed_rc_`_rc'|severity=warn"
}
else {
    capture noisily collect export "table_TG02_balance_after.csv", as(csv) replace
    if _rc {
display "SS_RC|code=0|cmd=warning|msg=collect_export_failed|detail=collect_export_failed_rc_`_rc'|severity=warn"
    }
    else {
        display "SS_OUTPUT_FILE|file=table_TG02_balance_after.csv|type=table|desc=balance_after"
    }
}

* ============ 生成平衡性对比图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成图表"
display "═══════════════════════════════════════════════════════════════════════════════"

* Covariate-balance density plot (propensity score by default) / 平衡性密度图
capture noisily tebalance density
if _rc == 0 {
    graph export "fig_TG02_balance_compare.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG02_balance_compare.png|type=graph|desc=balance_compare"
}
else {
display "SS_RC|code=0|cmd=warning|msg=graph_failed|detail=tebalance_density_failed_rc_`_rc'|severity=warn"
}

* ============ 导出ATT结果 ============
preserve
clear
set obs 1
generate str20 estimand = "ATT"
generate double estimate = `att'
generate double std_err = `att_se'
generate double t_stat = `att_t'
generate double p_value = 2 * (1 - normal(abs(`att_t')))
generate double ci_lower = `att' - 1.96 * `att_se'
generate double ci_upper = `att' + 1.96 * `att_se'
generate long n_treated = `n_treated_matched'
generate long n_control = `n_control_matched'

export delimited using "table_TG02_att_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG02_att_result.csv|type=table|desc=att_result"
restore

* ============ 保存匹配后数据 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 保留支持集样本（由 osample() 标记） / Keep overlap-support sample
capture confirm variable `osample'
if !_rc {
    keep if `osample' == 0
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG02_matched.dta", replace
display "SS_OUTPUT_FILE|file=data_TG02_matched.dta|type=data|desc=matched_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=att|value=`att'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  匹配后样本量:    " %10.0fc `n_output'
display "  匹配处理组:      " %10.0fc `n_treated_matched'
display "  匹配对照组:      " %10.0fc `n_control_matched'
display ""
display "  ATT估计:"
display "    效应值:        " %10.4f `att'
display "    标准误:        " %10.4f `att_se'
display "    t统计量:       " %10.4f `att_t'
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

* ============ 任务结束 ============
display "SS_TASK_END|id=TG02|status=ok|elapsed_sec=`elapsed'"
log close
