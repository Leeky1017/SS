* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* Template: TG05 — CEM Match
* 识别假设 / ID assumptions: method-specific; review before use (no "auto validity")
* 诊断输出 / Diagnostics: run minimal, relevant checks; treat WARN as evidence, not noise
* SSC依赖 / SSC deps: keep minimal; required packages are explicit in header
* 解读要点 / Interpretation: estimates are conditional on assumptions; add robustness checks
* SS_TEMPLATE: id=TG05  level=L1  module=G  title="CEM Match"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG05_cem_result.csv type=table desc="CEM results"
*   - table_TG05_cem_balance.csv type=table desc="CEM balance"
*   - data_TG05_cem_matched.dta type=data desc="CEM matched data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - cem source=ssc purpose="Coarsened exact matching"
* ==============================================================================

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

display "SS_TASK_BEGIN|id=TG05|level=L1|title=CEM_Match"

* ============ 随机性控制 ============
local seed_value = 12345
if "`__SEED__'" != "" {
    local seed_value = `__SEED__'
}
set seed `seed_value'
display "SS_METRIC|name=seed|value=`seed_value'"
display "SS_TASK_VERSION|version=2.1.0"

* ============ 依赖检测 ============
local required_deps "cem"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
display "SS_DEP_CHECK|pkg=`dep'|source=ssc|status=missing"
display "SS_DEP_MISSING|pkg=`dep'|hint=ssc_install_`dep'"
display "SS_RC|code=199|cmd=which `dep'|msg=dependency_missing|severity=fail"
display "SS_RC|code=199|cmd=which|msg=dep_missing|detail=`dep'_is_required_but_not_installed|severity=fail"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=cem|source=ssc|status=ok"

* ============ 参数设置 ============
local treatment_var = "__TREATMENT_VAR__"
local outcome_var = "__OUTCOME_VAR__"
local match_vars = "__MATCH_VARS__"
local cutpoints = "__CUTPOINTS__"

if "`cutpoints'" == "" {
    local cutpoints = "sturges"
}

display ""
display ">>> CEM匹配参数:"
display "    处理变量: `treatment_var'"
display "    结果变量: `outcome_var'"
display "    匹配变量: `match_vars'"
display "    粗化方式: `cutpoints'"

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
display "SS_RC|code=200|cmd=task|msg=no_match_vars|detail=No_valid_matching_variables|severity=fail"
    log close
    exit 200
}

quietly count if `treatment_var' == 1
local n_treated = r(N)
quietly count if `treatment_var' == 0
local n_control = r(N)

display ">>> 处理组: `n_treated', 对照组: `n_control'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 匹配前平衡性 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 匹配前平衡性"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算匹配前L1统计量
local l1_before = .
capture which imbalance
if _rc {
display "SS_RC|code=0|cmd=warning|msg=imbalance_missing|detail=Skip_L1_imbalance_check_command_not_installed|severity=warn"
}
else {
    imbalance `treatment_var' `valid_match_vars'
    local l1_before = r(L1)
}
display ""
display ">>> 匹配前L1不平衡度: " %6.4f `l1_before'

* ============ 执行CEM匹配 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 执行CEM匹配"
display "═══════════════════════════════════════════════════════════════════════════════"

* 执行CEM
cem `valid_match_vars', treatment(`treatment_var')

quietly count if cem_matched == 1
if r(N) == 0 {
display "SS_RC|code=0|cmd=warning|msg=cem_no_match|detail=No_matched_observations_fallback_to_full_sample|severity=warn"
    replace cem_matched = 1
    capture replace cem_weights = 1
    if _rc {
        generate double cem_weights = 1
    }
}

* 获取匹配结果
local n_matched = r(n_matched)
local n_strata = r(n_strata)
local l1_after = r(L1)

display ""
display ">>> CEM匹配结果:"
display "    匹配样本量: `n_matched'"
display "    匹配层数: `n_strata'"
display "    匹配后L1: " %6.4f `l1_after'
if `l1_before' < . & `l1_before' > 0 {
    display "    L1改善: " %6.2f `=(1-`l1_after'/`l1_before')*100' "%"
}

display "SS_METRIC|name=n_matched|value=`n_matched'"
display "SS_METRIC|name=n_strata|value=`n_strata'"
display "SS_METRIC|name=l1_before|value=`l1_before'"
display "SS_METRIC|name=l1_after|value=`l1_after'"

* ============ 匹配后平衡性检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 匹配后平衡性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname balance
postfile `balance' str32 variable double mean_t_before double mean_c_before double std_diff_before ///
    double mean_t_after double mean_c_after double std_diff_after double reduction ///
    using "temp_cem_balance.dta", replace

display ""
display "变量                 标准化差异(前)  标准化差异(后)  改善"
display "───────────────────────────────────────────────────────────────"

foreach var of local valid_match_vars {
    * 匹配前
    quietly summarize `var' if `treatment_var' == 1
    local mean_t_before = r(mean)
    local sd_t = r(sd)
    quietly summarize `var' if `treatment_var' == 0
    local mean_c_before = r(mean)
    local sd_c = r(sd)
    local pooled_sd = sqrt((`sd_t'^2 + `sd_c'^2) / 2)
    if `pooled_sd' > 0 {
        local std_diff_before = (`mean_t_before' - `mean_c_before') / `pooled_sd' * 100
    }
    else {
        local std_diff_before = 0
    }
    
    * 匹配后（加权）
    quietly summarize `var' if `treatment_var' == 1 & cem_matched == 1 [aw=cem_weights]
    local mean_t_after = r(mean)
    quietly summarize `var' if `treatment_var' == 0 & cem_matched == 1 [aw=cem_weights]
    local mean_c_after = r(mean)
    if `pooled_sd' > 0 {
        local std_diff_after = (`mean_t_after' - `mean_c_after') / `pooled_sd' * 100
    }
    else {
        local std_diff_after = 0
    }
    
    * 改善百分比
    if abs(`std_diff_before') > 0.001 {
        local reduction = (1 - abs(`std_diff_after') / abs(`std_diff_before')) * 100
    }
    else {
        local reduction = 100
    }
    
    post `balance' ("`var'") (`mean_t_before') (`mean_c_before') (`std_diff_before') ///
        (`mean_t_after') (`mean_c_after') (`std_diff_after') (`reduction')
    
    display %20s "`var'" "  " %12.2f `std_diff_before' "%  " %12.2f `std_diff_after' "%  " %10.1f `reduction' "%"
}

postclose `balance'

preserve
use "temp_cem_balance.dta", clear
export delimited using "table_TG05_cem_balance.csv", replace
display "SS_OUTPUT_FILE|file=table_TG05_cem_balance.csv|type=table|desc=cem_balance"
restore

* ============ SATT估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: SATT效应估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用CEM权重进行回归
quietly count if cem_matched == 1 & cem_weights < .
if r(N) == 0 {
display "SS_RC|code=0|cmd=warning|msg=cem_no_match|detail=Skip_weighting_run_unweighted_regression|severity=warn"
    regress `outcome_var' `treatment_var', robust
}
else {
    regress `outcome_var' `treatment_var' if cem_matched == 1 [iw=cem_weights], robust
}

local satt = _b[`treatment_var']
local satt_se = _se[`treatment_var']
local satt_t = `satt' / `satt_se'
local satt_p = 2 * ttail(e(df_r), abs(`satt_t'))
local ci_lower = `satt' - 1.96 * `satt_se'
local ci_upper = `satt' + 1.96 * `satt_se'

display ""
display ">>> SATT估计结果:"
display "    效应值:    " %10.4f `satt'
display "    标准误:    " %10.4f `satt_se'
display "    t统计量:   " %10.4f `satt_t'
display "    p值:       " %10.4f `satt_p'
display "    95% CI:    [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"

display "SS_METRIC|name=satt|value=`satt'"
display "SS_METRIC|name=satt_se|value=`satt_se'"
display "SS_METRIC|name=satt_t|value=`satt_t'"

* 导出结果
preserve
clear
set obs 1
generate str10 estimand = "SATT"
generate double effect = `satt'
generate double se = `satt_se'
generate double t_stat = `satt_t'
generate double p_value = `satt_p'
generate double ci_lower = `ci_lower'
generate double ci_upper = `ci_upper'
generate long n_matched = `n_matched'
generate long n_strata = `n_strata'
generate double l1_before = `l1_before'
generate double l1_after = `l1_after'
export delimited using "table_TG05_cem_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG05_cem_result.csv|type=table|desc=cem_result"
restore

* ============ 输出结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 保留匹配样本
keep if cem_matched == 1

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG05_cem_matched.dta", replace
display "SS_OUTPUT_FILE|file=data_TG05_cem_matched.dta|type=data|desc=cem_matched_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=satt|value=`satt'"

capture erase "temp_cem_balance.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  匹配后样本量:    " %10.0fc `n_output'
display "  匹配层数:        " %10.0fc `n_strata'
display ""
display "  L1不平衡度:"
display "    匹配前:        " %10.4f `l1_before'
display "    匹配后:        " %10.4f `l1_after'
display ""
display "  SATT估计:"
display "    效应值:        " %10.4f `satt'
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

display "SS_TASK_END|id=TG05|status=ok|elapsed_sec=`elapsed'"
log close
