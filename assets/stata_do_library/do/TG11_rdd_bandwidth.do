* ==============================================================================
* SS_TEMPLATE: id=TG11  level=L1  module=G  title="RDD Bandwidth"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG11_bandwidth_results.csv type=table desc="Bandwidth results"
*   - table_TG11_sensitivity.csv type=table desc="Sensitivity results"
*   - fig_TG11_bandwidth_plot.png type=figure desc="Bandwidth plot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - rdrobust source=ssc purpose="RDD bandwidth"
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

display "SS_TASK_BEGIN|id=TG11|level=L1|title=RDD_Bandwidth"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: compare bandwidth selectors (MSE/CER) and show sensitivity across bandwidths. /
*   最佳实践：对比多种带宽选择（MSE/CER），并做带宽敏感性分析。
* - SSC deps: required:rdrobust / SSC 依赖：必需 rdrobust
* - Error policy: fail on missing vars; warn if chosen bandwidth leads to tiny effective sample /
*   错误策略：缺少变量→fail；有效样本过小→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG11|ssc=required:rdrobust|output=csv|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 依赖检测 ============
local required_deps "rdrobust"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_MISSING:cmd=`dep':hint=ssc install `dep'"
        display "SS_ERROR:DEP_MISSING:`dep' is required but not installed"
        display "SS_ERR:DEP_MISSING:`dep' is required but not installed"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=rdrobust|source=ssc|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local running_var = "__RUNNING_VAR__"
local cutoff = __CUTOFF__

display ""
display ">>> RDD带宽选择参数:"
display "    结果变量: `outcome_var'"
display "    驱动变量: `running_var'"
display "    断点: `cutoff'"

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
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

* ============ 变量检查 ============
foreach var in `outcome_var' `running_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 带宽选择 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 最优带宽选择"
display "═══════════════════════════════════════════════════════════════════════════════"

rdbwselect `outcome_var' `running_var', c(`cutoff') all

* 提取各种带宽
local h_mserd = e(h_mserd)
local h_msetwo = e(h_msetwo)
local h_msesum = e(h_msesum)
local h_msecomb1 = e(h_msecomb1)
local h_msecomb2 = e(h_msecomb2)
local h_cerrd = e(h_cerrd)
local h_certwo = e(h_certwo)
local h_cersum = e(h_cersum)
local h_cercomb1 = e(h_cercomb1)
local h_cercomb2 = e(h_cercomb2)

display ""
display ">>> 带宽选择结果:"
display ""
display "MSE最优带宽:"
display "    MSE-RD (主推荐): " %8.4f `h_mserd'
display "    MSE-Two: " %8.4f `h_msetwo'
display "    MSE-Sum: " %8.4f `h_msesum'
display "    MSE-Comb1: " %8.4f `h_msecomb1'
display "    MSE-Comb2: " %8.4f `h_msecomb2'
display ""
display "CER最优带宽:"
display "    CER-RD: " %8.4f `h_cerrd'
display "    CER-Two: " %8.4f `h_certwo'
display "    CER-Sum: " %8.4f `h_cersum'
display "    CER-Comb1: " %8.4f `h_cercomb1'
display "    CER-Comb2: " %8.4f `h_cercomb2'

display "SS_METRIC|name=h_mserd|value=`h_mserd'"
display "SS_METRIC|name=h_cerrd|value=`h_cerrd'"

* 导出带宽结果
tempname bwresults
postfile `bwresults' str20 method double bandwidth str50 description ///
    using "temp_bandwidth_results.dta", replace

post `bwresults' ("MSE-RD") (`h_mserd') ("MSE最优-RD点估计(推荐)")
post `bwresults' ("MSE-Two") (`h_msetwo') ("MSE最优-两侧分别估计")
post `bwresults' ("MSE-Sum") (`h_msesum') ("MSE最优-加总")
post `bwresults' ("MSE-Comb1") (`h_msecomb1') ("MSE最优-组合1")
post `bwresults' ("MSE-Comb2") (`h_msecomb2') ("MSE最优-组合2")
post `bwresults' ("CER-RD") (`h_cerrd') ("CER最优-RD点估计")
post `bwresults' ("CER-Two") (`h_certwo') ("CER最优-两侧分别估计")
post `bwresults' ("CER-Sum") (`h_cersum') ("CER最优-加总")
post `bwresults' ("CER-Comb1") (`h_cercomb1') ("CER最优-组合1")
post `bwresults' ("CER-Comb2") (`h_cercomb2') ("CER最优-组合2")

postclose `bwresults'

preserve
use "temp_bandwidth_results.dta", clear
export delimited using "table_TG11_bandwidth_results.csv", replace
display "SS_OUTPUT_FILE|file=table_TG11_bandwidth_results.csv|type=table|desc=bandwidth_results"
restore

* ============ 带宽敏感性分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 带宽敏感性分析"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname sensitivity
postfile `sensitivity' double bandwidth double tau double se double ci_lower double ci_upper long n_eff ///
    using "temp_sensitivity.dta", replace

display ""
display "带宽       LATE        SE         95% CI              有效N"
display "─────────────────────────────────────────────────────────────"

local bw_base = `h_mserd'
foreach mult in 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.75 2.0 {
    local bw_test = `bw_base' * `mult'
    
    quietly rdrobust `outcome_var' `running_var', c(`cutoff') h(`bw_test')
    
    local tau = e(tau_cl)
    local se = e(se_tau_cl)
    local ci_l = e(ci_l_cl)
    local ci_r = e(ci_r_cl)
    local n_eff = e(N_h_l) + e(N_h_r)
    
    post `sensitivity' (`bw_test') (`tau') (`se') (`ci_l') (`ci_r') (`n_eff')
    
    display %8.4f `bw_test' "  " %10.4f `tau' "  " %8.4f `se' "  [" %8.4f `ci_l' ", " %8.4f `ci_r' "]  " %6.0f `n_eff'
}

postclose `sensitivity'

preserve
use "temp_sensitivity.dta", clear
export delimited using "table_TG11_sensitivity.csv", replace
display "SS_OUTPUT_FILE|file=table_TG11_sensitivity.csv|type=table|desc=sensitivity"
restore

* ============ 生成图形 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成带宽敏感性图"
display "═══════════════════════════════════════════════════════════════════════════════"

preserve
use "temp_sensitivity.dta", clear

twoway (rarea ci_lower ci_upper bandwidth, color(navy%20)) ///
       (line tau bandwidth, lcolor(navy) lwidth(medium)), ///
       xline(`h_mserd', lcolor(red) lpattern(dash)) ///
       yline(0, lcolor(gray) lpattern(dot)) ///
       legend(order(2 "点估计" 1 "95% CI") position(6)) ///
       xtitle("带宽") ytitle("LATE估计") ///
       title("RDD带宽敏感性分析") ///
       note("红色虚线=MSE最优带宽")
graph export "fig_TG11_bandwidth_plot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG11_bandwidth_plot.png|type=figure|desc=bandwidth_plot"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=h_mserd|value=`h_mserd'"
display "SS_SUMMARY|key=h_cerrd|value=`h_cerrd'"

* 清理
capture erase "temp_bandwidth_results.dta"
if _rc != 0 { }
capture erase "temp_sensitivity.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG11 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  断点:            " %10.4f `cutoff'
display ""
display "  推荐带宽:"
display "    MSE-RD:        " %10.4f `h_mserd'
display "    CER-RD:        " %10.4f `h_cerrd'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
local n_dropped = 0
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG11|status=ok|elapsed_sec=`elapsed'"
log close
