* ==============================================================================
* SS_TEMPLATE: id=TM06  level=L2  module=M  title="Meta Analysis"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TM06_forest.png type=graph desc="Forest plot"
*   - table_TM06_meta.csv type=table desc="Meta results"
*   - data_TM06_meta.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================
* BEST_PRACTICE_REVIEW (EN):
* - Ensure effect sizes are on a compatible scale (e.g., log OR) and SE corresponds to the same effect.
* - Random-effects pooling depends on heterogeneity assumptions; report I^2 and consider sensitivity analyses.
* - Forest plots are for communication; verify study labels and units before reporting.
* 最佳实践审查（ZH）:
* - 请确保效应量在同一量纲/尺度（如 log OR），且标准误与效应量一致。
* - 随机效应汇总依赖异质性假设；建议报告 I^2 并进行敏感性分析。
* - 森林图用于展示；在报告前请核对研究标签与效应量单位。
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TM06|level=L2|title=Meta_Analysis"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

local effect = "__EFFECT__"
local se = "__SE__"
local study = "__STUDY__"

display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm file data.csv|msg=file_not_found:data.csv|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate effect/SE variables exist and SE > 0 for complete cases.
* ZH: 校验效应量/标准误变量存在，且完整观测中标准误应大于 0。
capture confirm variable `effect'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `effect'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `se'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `se'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm variable `study'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm variable `study'|msg=var_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `effect'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `effect'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
capture confirm numeric variable `se'
if _rc {
    local rc = _rc
    display "SS_RC|code=`rc'|cmd=confirm numeric variable `se'|msg=var_not_numeric|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit `rc'
}
count if !missing(`effect', `se') & (`se' > 0)
local k = r(N)
display "SS_METRIC|name=k_studies|value=`k'"
if `k' < 2 {
    display "SS_RC|code=2005|cmd=validate_study_count|msg=too_few_studies|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_TASK_END|id=TM06|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 2005
}
count if !missing(`effect', `se') & (`se' <= 0)
local n_bad_se = r(N)
display "SS_METRIC|name=n_bad_se|value=`n_bad_se'"
if `n_bad_se' > 0 {
    display "SS_RC|code=2006|cmd=validate_se_positive|msg=nonpositive_se_detected|severity=warn"
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Random-effects meta-analysis (DerSimonian-Laird) implemented without SSC dependencies.
* ZH: 使用 DerSimonian-Laird 随机效应汇总（不依赖 SSC）。

tempvar ss_w ss_wx ss_q ss_w_sq ss_w_re ss_wre_x ss_ci_lb ss_ci_ub ss_y ss_pooled_flag

gen double `ss_w' = .
replace `ss_w' = 1 / (`se'^2) if !missing(`effect', `se') & (`se' > 0)
gen double `ss_wx' = `ss_w' * `effect'
quietly summarize `ss_w', meanonly
local sum_w = r(sum)
quietly summarize `ss_wx', meanonly
local sum_wx = r(sum)
local pooled_fe = `sum_wx' / `sum_w'

gen double `ss_q' = `ss_w' * (`effect' - `pooled_fe')^2
quietly summarize `ss_q', meanonly
local Q = r(sum)
local df = `k' - 1

gen double `ss_w_sq' = `ss_w'^2
quietly summarize `ss_w_sq', meanonly
local sum_w_sq = r(sum)
drop `ss_w_sq'

local C = `sum_w' - (`sum_w_sq' / `sum_w')
local tau2 = 0
if (`C' > 0) & (`Q' > `df') {
    local tau2 = (`Q' - `df') / `C'
}
local i2 = 0
if `Q' > 0 {
    if `Q' > `df' {
        local i2 = 100 * (`Q' - `df') / `Q'
    }
}

gen double `ss_w_re' = .
replace `ss_w_re' = 1 / ((`se'^2) + `tau2') if !missing(`effect', `se') & (`se' > 0)
gen double `ss_wre_x' = `ss_w_re' * `effect'
quietly summarize `ss_w_re', meanonly
local sum_wre = r(sum)
quietly summarize `ss_wre_x', meanonly
local sum_wre_x = r(sum)
local pooled_re = `sum_wre_x' / `sum_wre'
local se_pooled_re = sqrt(1 / `sum_wre')

display "SS_METRIC|name=pooled_effect|value=`pooled_re'"
display "SS_METRIC|name=se_pooled|value=`se_pooled_re'"
display "SS_METRIC|name=tau2|value=`tau2'"
display "SS_METRIC|name=i_squared|value=`i2'"

preserve
keep if !missing(`effect', `se') & (`se' > 0)
gen double `ss_ci_lb' = `effect' - 1.96 * `se'
gen double `ss_ci_ub' = `effect' + 1.96 * `se'
gen int `ss_y' = _n
gen byte `ss_pooled_flag' = 0
local y_pooled = _N + 1
set obs `y_pooled'
replace `effect' = `pooled_re' in `y_pooled'
replace `se' = `se_pooled_re' in `y_pooled'
replace `ss_ci_lb' = `pooled_re' - 1.96 * `se_pooled_re' in `y_pooled'
replace `ss_ci_ub' = `pooled_re' + 1.96 * `se_pooled_re' in `y_pooled'
replace `ss_y' = `y_pooled' in `y_pooled'
replace `ss_pooled_flag' = 1 in `y_pooled'

twoway ///
    (rcap `ss_ci_lb' `ss_ci_ub' `ss_y' if `ss_pooled_flag' == 0, horizontal lcolor(gs10)) ///
    (scatter `effect' `ss_y' if `ss_pooled_flag' == 0, msymbol(D) mcolor(navy)) ///
    (rcap `ss_ci_lb' `ss_ci_ub' `ss_y' if `ss_pooled_flag' == 1, horizontal lcolor(maroon) lwidth(medthick)) ///
    (scatter `effect' `ss_y' if `ss_pooled_flag' == 1, msymbol(Dh) mcolor(maroon)), ///
    ytitle("Study (index)") xtitle("Effect") legend(off) title("Forest Plot")
graph export "fig_TM06_forest.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TM06_forest.png|type=graph|desc=forest_plot"
restore

preserve
clear
set obs 1
gen double pooled_es = `pooled_re'
gen double se_es = `se_pooled_re'
gen double i_squared = `i2'
gen double tau2 = `tau2'
export delimited using "table_TM06_meta.csv", replace
display "SS_OUTPUT_FILE|file=table_TM06_meta.csv|type=table|desc=meta_results"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
save "data_TM06_meta.dta", replace
display "SS_OUTPUT_FILE|file=data_TM06_meta.dta|type=data|desc=meta_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=pooled_effect|value=`pooled_re'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TM06|status=ok|elapsed_sec=`elapsed'"
log close
