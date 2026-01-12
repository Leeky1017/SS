* ==============================================================================
* SS_TEMPLATE: id=TP02  level=L2  module=P  title="Panel RE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP02_re_result.csv type=table desc="RE results"
*   - table_TP02_hausman.csv type=table desc="Hausman test"
*   - data_TP02_re.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

program define ss_fail_TP02
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP02|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP02|level=L2|title=Panel_RE"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: RE requires exogeneity of unobserved effects; report Hausman test and prefer FE if rejected. /
*   最佳实践：RE 依赖个体效应外生性；报告 Hausman 检验，若拒绝则优先 FE。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/xtset/estimation; warn on singleton groups /
*   错误策略：缺少输入/xtset/估计失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP02|ssc=none|output=csv_dta|policy=warn_fail"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"

display ""
display ">>> 随机效应模型参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    个体ID: `id_var'"
display "    时间: `time_var'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP02 601 "confirm file data.csv" "input_file_not_found"
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `depvar' `id_var' `time_var' {
    capture confirm variable `var'
    if _rc {
        ss_fail_TP02 200 "confirm variable `var'" "var_not_found"
    }
}

local valid_indep ""
foreach var of local indepvars {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_indep "`valid_indep' `var'"
    }
}
if "`valid_indep'" == "" {
    ss_fail_TP02 200 "confirm numeric indepvars" "no_valid_indepvars"
}

capture xtset `id_var' `time_var'
if _rc {
    ss_fail_TP02 `=_rc' "xtset `id_var' `time_var'" "xtset_failed"
}
tempvar _ss_n_i
bysort `id_var': gen long `_ss_n_i' = _N
quietly count if `_ss_n_i' == 1
local n_singletons = r(N)
drop `_ss_n_i'
display "SS_METRIC|name=n_singletons|value=`n_singletons'"
if `n_singletons' > 0 {
    display "SS_RC|code=312|cmd=xtset|msg=singleton_groups_present|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 随机效应估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 随机效应模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

capture noisily xtreg `depvar' `valid_indep', re
if _rc {
    ss_fail_TP02 `=_rc' "xtreg re" "estimation_failed"
}

local r2_within = e(r2_w)
local r2_between = e(r2_b)
local r2_overall = e(r2_o)
local sigma_u = e(sigma_u)
local sigma_e = e(sigma_e)
local rho = e(rho)
local theta = e(theta)

display ""
display ">>> RE模型拟合:"
display "    R2 (within): " %8.4f `r2_within'
display "    R2 (between): " %8.4f `r2_between'
display "    R2 (overall): " %8.4f `r2_overall'
display "    theta: " %8.4f `theta'

display "SS_METRIC|name=r2_overall|value=`r2_overall'"
display "SS_METRIC|name=theta|value=`theta'"

estimates store re_model

* 导出RE结果
tempname re_results
postfile `re_results' str32 variable double coef double se double z double p ///
    using "temp_re_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `re_results' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `re_results'

preserve
use "temp_re_results.dta", clear
capture export delimited using "table_TP02_re_result.csv", replace
if _rc {
    ss_fail_TP02 `=_rc' "export delimited table_TP02_re_result.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP02_re_result.csv|type=table|desc=re_results"
restore

* ============ Hausman检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Hausman检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 先估计FE
capture quietly xtreg `depvar' `valid_indep', fe
if _rc {
    ss_fail_TP02 `=_rc' "xtreg fe" "fe_estimation_failed"
}
estimates store fe_model

* Hausman检验
local hausman_chi2 = .
local hausman_df = .
local hausman_p = .
local recommendation = "NA"
capture noisily hausman fe_model re_model
if _rc {
    display "SS_RC|code=`=_rc'|cmd=hausman|msg=hausman_failed|severity=warn"
}
else {
    local hausman_chi2 = r(chi2)
    local hausman_df = r(df)
    local hausman_p = r(p)

    if `hausman_p' < 0.05 {
        local recommendation = "FE"
    }
    else {
        local recommendation = "RE"
    }
}

display "SS_METRIC|name=hausman_chi2|value=`hausman_chi2'"
display "SS_METRIC|name=hausman_p|value=`hausman_p'"

* 导出Hausman检验结果
preserve
clear
set obs 1
generate double chi2 = `hausman_chi2'
generate int df = `hausman_df'
generate double p_value = `hausman_p'
generate str10 recommendation = "`recommendation'"

capture export delimited using "table_TP02_hausman.csv", replace
if _rc {
    ss_fail_TP02 `=_rc' "export delimited table_TP02_hausman.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP02_hausman.csv|type=table|desc=hausman_test"
restore

capture erase "temp_re_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TP02_re.dta", replace
if _rc {
    ss_fail_TP02 `=_rc' "save data_TP02_re.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TP02_re.dta|type=data|desc=re_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TP02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  RE模型:"
display "    R2(overall):   " %10.4f `r2_overall'
display "    theta:         " %10.4f `theta'
display ""
display "  Hausman检验:"
display "    χ²:            " %10.4f `hausman_chi2'
display "    p值:           " %10.4f `hausman_p'
display "    推荐:          `recommendation'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=hausman_p|value=`hausman_p'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP02|status=ok|elapsed_sec=`elapsed'"
log close
