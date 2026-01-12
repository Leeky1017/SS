* ==============================================================================
* SS_TEMPLATE: id=TP01  level=L2  module=P  title="Panel FE"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TP01_fe_result.csv type=table desc="FE results"
*   - table_TP01_fe_test.csv type=table desc="FE test"
*   - data_TP01_fe.dta type=data desc="Output data"
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

program define ss_fail_TP01
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TP01|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TP01|level=L2|title=Panel_FE"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: FE is preferred when unobserved heterogeneity correlates with regressors; cluster SE at panel level by default. /
*   最佳实践：当不可观测异质性与解释变量相关时优先使用 FE；默认按个体聚类稳健标准误。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/xtset/estimation; warn on singleton groups /
*   错误策略：缺少输入/xtset/估计失败→fail；单成员组→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TP01|ssc=none|output=csv_dta|policy=warn_fail"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local fe_type = "__FE_TYPE__"
local cluster_var = "__CLUSTER_VAR__"

if "`fe_type'" == "" {
    local fe_type = "individual"
}

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    ss_fail_TP01 601 "confirm file data.csv" "input_file_not_found"
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
        ss_fail_TP01 200 "confirm variable `var'" "var_not_found"
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
    ss_fail_TP01 200 "confirm numeric indepvars" "no_valid_indepvars"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* 设置面板
capture xtset `id_var' `time_var'
if _rc {
    ss_fail_TP01 `=_rc' "xtset `id_var' `time_var'" "xtset_failed"
}

quietly xtdescribe
local n_panels = r(n)
local n_times = r(max)
tempvar _ss_n_i
bysort `id_var': gen long `_ss_n_i' = _N
quietly count if `_ss_n_i' == 1
local n_singletons = r(N)
drop `_ss_n_i'
display "SS_METRIC|name=n_singletons|value=`n_singletons'"
if `n_singletons' > 0 {
    display "SS_RC|code=312|cmd=xtset|msg=singleton_groups_present|severity=warn"
}

* Inference default / 推断默认：按个体聚类；如提供 cluster_var 且存在则使用其聚类
local cluster_for_vce "`id_var'"
if "`cluster_var'" != "" {
    capture confirm variable `cluster_var'
    if !_rc {
        local cluster_for_vce "`cluster_var'"
    }
}
local vce_opt "cluster `cluster_for_vce'"

if "`fe_type'" == "individual" {
    display ">>> 个体固定效应模型..."
    capture noisily xtreg `depvar' `valid_indep', fe vce(`vce_opt')
    if _rc {
        ss_fail_TP01 `=_rc' "fe_estimation" "estimation_failed"
    }
}
else if "`fe_type'" == "time" {
    capture noisily regress `depvar' `valid_indep' i.`time_var', vce(cluster `cluster_for_vce')
    if _rc {
        ss_fail_TP01 `=_rc' "fe_estimation" "estimation_failed"
    }
}
else {
    capture noisily xtreg `depvar' `valid_indep' i.`time_var', fe vce(`vce_opt')
    if _rc {
        ss_fail_TP01 `=_rc' "fe_estimation" "estimation_failed"
    }
}

local r2_within = .
local r2_between = .
local r2_overall = .
local sigma_u = .
local sigma_e = .
local rho = .
local n_obs = e(N)
local n_groups = `n_panels'
if "`fe_type'" == "time" {
    local r2_overall = e(r2)
    local sigma_e = e(rmse)
}
else {
    local r2_within = e(r2_w)
    local r2_between = e(r2_b)
    local r2_overall = e(r2_o)
    local sigma_u = e(sigma_u)
    local sigma_e = e(sigma_e)
    local rho = e(rho)
}

display "SS_METRIC|name=r2_within|value=`r2_within'"
display "SS_METRIC|name=rho|value=`rho'"
display "SS_METRIC|name=n_obs|value=`n_obs'"

* 导出结果
tempname fe_results
postfile `fe_results' str32 variable double coef double se double t double p ///
    using "temp_fe_results.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    if !strpos("`vname'", ".`time_var'") & "`vname'" != "_cons" {
        local coef = b[1, `i']
        local se = sqrt(V[`i', `i'])
        local t = `coef' / `se'
        local p = 2 * ttail(e(df_r), abs(`t'))
        post `fe_results' ("`vname'") (`coef') (`se') (`t') (`p')
    }
}

postclose `fe_results'

preserve
use "temp_fe_results.dta", clear
capture export delimited using "table_TP01_fe_result.csv", replace
if _rc {
    ss_fail_TP01 `=_rc' "export delimited table_TP01_fe_result.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP01_fe_result.csv|type=table|desc=fe_results"
restore

* F检验：所有固定效应=0
local f_test = .
local f_p = .
if "`fe_type'" != "time" {
    local f_test = e(F_f)
    local f_p = Ftail(e(df_a), e(df_r), `f_test')
    display "SS_METRIC|name=f_test|value=`f_test'"
}

* 导出检验结果
preserve
clear
set obs 2
generate str30 test = ""
generate double statistic = .
generate double p_value = .
generate str50 conclusion = ""

replace test = "F-test (individual effects)" in 1
replace statistic = `f_test' in 1
replace p_value = `f_p' in 1
replace conclusion = cond(`f_p' < 0.05, "sig_fe", "no_sig_fe") in 1

replace test = "rho (个体效应占比)" in 2
replace statistic = `rho' in 2

capture export delimited using "table_TP01_fe_test.csv", replace
if _rc {
    ss_fail_TP01 `=_rc' "export delimited table_TP01_fe_test.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TP01_fe_test.csv|type=table|desc=fe_test"
restore

capture erase "temp_fe_results.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TP01_fe.dta", replace
if _rc {
    ss_fail_TP01 `=_rc' "save data_TP01_fe.dta" "save_failed"
}
display "SS_OUTPUT_FILE|file=data_TP01_fe.dta|type=data|desc=fe_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=r2_within|value=`r2_within'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TP01|status=ok|elapsed_sec=`elapsed'"
log close
