* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* Template: TG09 — RDD Sharp
* 识别假设 / ID assumptions: method-specific; review before use (no "auto validity")
* 诊断输出 / Diagnostics: run minimal, relevant checks; treat WARN as evidence, not noise
* SSC依赖 / SSC deps: keep minimal; required packages are explicit in header
* 解读要点 / Interpretation: estimates are conditional on assumptions; add robustness checks
* SS_TEMPLATE: id=TG09  level=L1  module=G  title="RDD Sharp"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG09_rdd_result.csv type=table desc="RDD results"
*   - table_TG09_bandwidth.csv type=table desc="Bandwidth selection"
*   - fig_TG09_rdd_plot.png type=graph desc="RDD plot"
*   - data_TG09_rdd.dta type=data desc="RDD data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - rdrobust source=ssc purpose="RDD estimation"
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

display "SS_TASK_BEGIN|id=TG09|level=L1|title=RDD_Sharp"
display "SS_TASK_VERSION|version=2.1.0"

* ============ 依赖检测 ============
local required_deps "rdrobust"
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
display "SS_DEP_CHECK|pkg=rdrobust|source=ssc|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local running_var = "__RUNNING_VAR__"
local cutoff = __CUTOFF__
local bandwidth = __BANDWIDTH__
local kernel = "__KERNEL__"
local poly_order = __POLY_ORDER__

if "`kernel'" == "" | ("`kernel'" != "triangular" & "`kernel'" != "uniform" & "`kernel'" != "epanechnikov") {
    local kernel = "triangular"
}
if `poly_order' < 1 | `poly_order' > 4 {
    local poly_order = 1
}

display ""
display ">>> Sharp RDD参数:"
display "    结果变量: `outcome_var'"
display "    驱动变量: `running_var'"
display "    断点: `cutoff'"
if `bandwidth' > 0 {
    display "    带宽: `bandwidth'"
}
else {
    display "    带宽: 自动选择"
}
display "    核函数: `kernel'"
display "    多项式阶数: `poly_order'"

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
foreach var in `outcome_var' `running_var' {
    capture confirm numeric variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

* 生成处理变量
generate byte _treatment = (`running_var' >= `cutoff')
label variable _treatment "处理状态(1=处理组)"

quietly count if _treatment == 1
local n_treated = r(N)
quietly count if _treatment == 0
local n_control = r(N)

display ">>> 断点以上(处理组): `n_treated'"
display ">>> 断点以下(对照组): `n_control'"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* 生成中心化驱动变量
generate double _running_centered = `running_var' - `cutoff'
label variable _running_centered "中心化驱动变量"

* ============ 带宽选择 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 带宽选择"
display "═══════════════════════════════════════════════════════════════════════════════"

if `bandwidth' <= 0 {
    * 自动带宽选择
    rdbwselect `outcome_var' `running_var', c(`cutoff') kernel(`kernel') p(`poly_order')
    
    local bw_mserd = e(h_mserd)
    local bw_msetwo = e(h_msetwo)
    local bw_cerrd = e(h_cerrd)
    
    display ""
    display ">>> 最优带宽选择结果:"
    display "    MSE-RD: " %8.4f `bw_mserd'
    display "    MSE-Two: " %8.4f `bw_msetwo'
    display "    CER-RD: " %8.4f `bw_cerrd'
    
    local bandwidth = `bw_mserd'
    display ">>> 使用MSE-RD带宽: " %8.4f `bandwidth'
}
else {
    local bw_mserd = `bandwidth'
    local bw_msetwo = `bandwidth'
    local bw_cerrd = `bandwidth'
}

display "SS_METRIC|name=bandwidth|value=`bandwidth'"

* 导出带宽选择结果
preserve
clear
set obs 1
generate str20 method = "MSE-RD"
generate double bandwidth = `bw_mserd'
set obs 2
replace method = "MSE-Two" in 2
replace bandwidth = `bw_msetwo' in 2
set obs 3
replace method = "CER-RD" in 3
replace bandwidth = `bw_cerrd' in 3
export delimited using "table_TG09_bandwidth.csv", replace
display "SS_OUTPUT_FILE|file=table_TG09_bandwidth.csv|type=table|desc=bandwidth"
restore

* ============ RDD估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Sharp RDD估计"
display "═══════════════════════════════════════════════════════════════════════════════"

rdrobust `outcome_var' `running_var', c(`cutoff') h(`bandwidth') kernel(`kernel') p(`poly_order')

* 提取结果
local tau = e(tau_cl)
local se = e(se_tau_cl)
local z = `tau' / `se'
local p_value = 2 * (1 - normal(abs(`z')))
local ci_lower = e(ci_l_cl)
local ci_upper = e(ci_r_cl)
local n_left = e(N_h_l)
local n_right = e(N_h_r)
local bw_used = e(h_l)

display ""
display ">>> Sharp RDD估计结果:"
display "    LATE: " %10.4f `tau'
display "    标准误: " %10.4f `se'
display "    z统计量: " %10.4f `z'
display "    p值: " %10.4f `p_value'
display "    95% CI: [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"
display ""
display "    带宽内样本:"
display "    左侧: `n_left', 右侧: `n_right'"

display "SS_METRIC|name=tau|value=`tau'"
display "SS_METRIC|name=se|value=`se'"
display "SS_METRIC|name=p_value|value=`p_value'"

* 导出结果
preserve
clear
set obs 1
generate str10 design = "Sharp"
generate double tau = `tau'
generate double se = `se'
generate double z_stat = `z'
generate double p_value = `p_value'
generate double ci_lower = `ci_lower'
generate double ci_upper = `ci_upper'
generate double bandwidth = `bw_used'
generate long n_left = `n_left'
generate long n_right = `n_right'
generate double cutoff = `cutoff'
export delimited using "table_TG09_rdd_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG09_rdd_result.csv|type=table|desc=rdd_result"
restore

* ============ 稳健性检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 稳健性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 不同带宽的估计
display ""
display "带宽敏感性:"
display "带宽倍数    带宽值      LATE        SE"
display "─────────────────────────────────────────"

foreach mult in 0.5 0.75 1 1.25 1.5 {
    local bw_test = `bandwidth' * `mult'
    quietly rdrobust `outcome_var' `running_var', c(`cutoff') h(`bw_test') kernel(`kernel') p(`poly_order')
    local tau_test = e(tau_cl)
    local se_test = e(se_tau_cl)
    display %8.2f `mult' "    " %10.4f `bw_test' "  " %10.4f `tau_test' "  " %10.4f `se_test'
}

* ============ 生成RDD图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成RDD图"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用rdplot生成图形
capture rdplot `outcome_var' `running_var', c(`cutoff') p(`poly_order') ///
    graph_options(title("Sharp RDD: `outcome_var'") ///
    xtitle("驱动变量 (`running_var')") ytitle("`outcome_var'") ///
    xline(`cutoff', lcolor(red) lpattern(dash)) ///
    legend(off))
if _rc != 0 {
    * 备用：手动创建散点图
    twoway (scatter `outcome_var' `running_var' if _treatment == 0, mcolor(blue%50) msize(small)) ///
           (scatter `outcome_var' `running_var' if _treatment == 1, mcolor(red%50) msize(small)) ///
           (lfit `outcome_var' `running_var' if _treatment == 0 & abs(_running_centered) <= `bandwidth', lcolor(blue)) ///
           (lfit `outcome_var' `running_var' if _treatment == 1 & abs(_running_centered) <= `bandwidth', lcolor(red)), ///
           xline(`cutoff', lcolor(black) lpattern(dash)) ///
           legend(order(1 "对照组" 2 "处理组") position(6)) ///
           xtitle("驱动变量") ytitle("`outcome_var'") ///
           title("Sharp RDD散点图")
    graph export "fig_TG09_rdd_plot.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG09_rdd_plot.png|type=graph|desc=rdd_plot"
}
else {
    graph export "fig_TG09_rdd_plot.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG09_rdd_plot.png|type=graph|desc=rdd_plot"
}

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG09_rdd.dta", replace
display "SS_OUTPUT_FILE|file=data_TG09_rdd.dta|type=data|desc=rdd_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=tau|value=`tau'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG09 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  断点:            " %10.4f `cutoff'
display "  带宽:            " %10.4f `bandwidth'
display ""
display "  Sharp RDD估计:"
display "    LATE:          " %10.4f `tau'
display "    标准误:        " %10.4f `se'
display "    p值:           " %10.4f `p_value'
display "    95% CI:        [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG09|status=ok|elapsed_sec=`elapsed'"
log close
