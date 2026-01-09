* ==============================================================================
* SS_TEMPLATE: id=TG10  level=L1  module=G  title="RDD Fuzzy"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG10_fuzzy_result.csv type=table desc="Fuzzy RDD results"
*   - table_TG10_first_stage.csv type=table desc="First stage results"
*   - fig_TG10_fuzzy_plot.png type=figure desc="Fuzzy RDD plot"
*   - data_TG10_fuzzy.dta type=data desc="Fuzzy data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - rdrobust source=ssc purpose="RDD estimation"
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

display "SS_TASK_BEGIN|id=TG10|level=L1|title=RDD_Fuzzy"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: fuzzy RDD is local IV; report first-stage strength and interpret LATE at cutoff. /
*   最佳实践：Fuzzy RDD 本质为局部 IV；应报告第一阶段强度并解读断点处的 LATE。
* - SSC deps: required:rdrobust / SSC 依赖：必需 rdrobust
* - Error policy: fail on missing vars; warn on weak first-stage /
*   错误策略：缺少变量→fail；第一阶段弱→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG10|ssc=required:rdrobust|output=csv_png|policy=warn_fail"
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
local treatment_var = "__TREATMENT_VAR__"
local running_var = "__RUNNING_VAR__"
local cutoff = __CUTOFF__
local bandwidth = __BANDWIDTH__

display ""
display ">>> Fuzzy RDD参数:"
display "    结果变量: `outcome_var'"
display "    处理变量: `treatment_var'"
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
foreach var in `outcome_var' `treatment_var' `running_var' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

* 生成指示变量
generate byte _above_cutoff = (`running_var' >= `cutoff')

* 统计
quietly count if _above_cutoff == 1 & `treatment_var' == 1
local n_above_treated = r(N)
quietly count if _above_cutoff == 1
local n_above = r(N)
quietly count if _above_cutoff == 0 & `treatment_var' == 1
local n_below_treated = r(N)
quietly count if _above_cutoff == 0
local n_below = r(N)

local compliance_above = `n_above_treated' / `n_above' * 100
local compliance_below = `n_below_treated' / `n_below' * 100

display ""
display ">>> 处理状态分布:"
display "    断点以上: " %5.1f `compliance_above' "% 接受处理 (`n_above_treated'/`n_above')"
display "    断点以下: " %5.1f `compliance_below' "% 接受处理 (`n_below_treated'/`n_below')"
display "    跳跃幅度: " %5.1f `=`compliance_above'-`compliance_below'' "%"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 第一阶段估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 第一阶段（处理概率跳跃）"
display "═══════════════════════════════════════════════════════════════════════════════"

rdrobust `treatment_var' `running_var', c(`cutoff')

local fs_tau = e(tau_cl)
local fs_se = e(se_tau_cl)
local fs_z = `fs_tau' / `fs_se'
local fs_p = 2 * (1 - normal(abs(`fs_z')))
local bw_opt = e(h_l)

display ""
display ">>> 第一阶段结果（处理概率跳跃）:"
display "    跳跃幅度: " %10.4f `fs_tau'
display "    标准误: " %10.4f `fs_se'
display "    z统计量: " %10.4f `fs_z'
display "    p值: " %10.4f `fs_p'

if `bandwidth' <= 0 {
    local bandwidth = `bw_opt'
}

display "SS_METRIC|name=first_stage_jump|value=`fs_tau'"

* 检查第一阶段强度
if abs(`fs_tau') < 0.1 {
    display ""
    display "SS_WARNING:WEAK_FIRST_STAGE:First stage jump < 0.1, may have weak instrument"
}

* 导出第一阶段结果
preserve
clear
set obs 1
generate str20 stage = "First Stage"
generate double tau = `fs_tau'
generate double se = `fs_se'
generate double z_stat = `fs_z'
generate double p_value = `fs_p'
generate double bandwidth = `bw_opt'
export delimited using "table_TG10_first_stage.csv", replace
display "SS_OUTPUT_FILE|file=table_TG10_first_stage.csv|type=table|desc=first_stage"
restore

* ============ Fuzzy RDD估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Fuzzy RDD估计（约简形式/第一阶段）"
display "═══════════════════════════════════════════════════════════════════════════════"

rdrobust `outcome_var' `running_var', c(`cutoff') fuzzy(`treatment_var') h(`bandwidth')

local tau = e(tau_cl)
local se = e(se_tau_cl)
local z = `tau' / `se'
local p_value = 2 * (1 - normal(abs(`z')))
local ci_lower = e(ci_l_cl)
local ci_upper = e(ci_r_cl)
local n_left = e(N_h_l)
local n_right = e(N_h_r)

display ""
display ">>> Fuzzy RDD估计结果 (LATE):"
display "    效应值: " %10.4f `tau'
display "    标准误: " %10.4f `se'
display "    z统计量: " %10.4f `z'
display "    p值: " %10.4f `p_value'
display "    95% CI: [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"

display "SS_METRIC|name=tau|value=`tau'"
display "SS_METRIC|name=se|value=`se'"
display "SS_METRIC|name=p_value|value=`p_value'"

* 导出结果
preserve
clear
set obs 1
generate str10 design = "Fuzzy"
generate double tau = `tau'
generate double se = `se'
generate double z_stat = `z'
generate double p_value = `p_value'
generate double ci_lower = `ci_lower'
generate double ci_upper = `ci_upper'
generate double bandwidth = `bandwidth'
generate double first_stage = `fs_tau'
generate long n_left = `n_left'
generate long n_right = `n_right'
export delimited using "table_TG10_fuzzy_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG10_fuzzy_result.csv|type=table|desc=fuzzy_result"
restore

* ============ 生成图形 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成Fuzzy RDD图"
display "═══════════════════════════════════════════════════════════════════════════════"

* 结果变量图
twoway (scatter `outcome_var' `running_var' if _above_cutoff == 0, mcolor(blue%30) msize(vsmall)) ///
       (scatter `outcome_var' `running_var' if _above_cutoff == 1, mcolor(red%30) msize(vsmall)) ///
       (lpoly `outcome_var' `running_var' if _above_cutoff == 0, lcolor(blue) lwidth(medium)) ///
       (lpoly `outcome_var' `running_var' if _above_cutoff == 1, lcolor(red) lwidth(medium)), ///
       xline(`cutoff', lcolor(black) lpattern(dash)) ///
       legend(order(1 "断点以下" 2 "断点以上") position(6)) ///
       xtitle("驱动变量") ytitle("`outcome_var'") ///
       title("Fuzzy RDD: 结果变量")
graph export "fig_TG10_fuzzy_plot.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG10_fuzzy_plot.png|type=figure|desc=fuzzy_plot"

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG10_fuzzy.dta", replace
display "SS_OUTPUT_FILE|file=data_TG10_fuzzy.dta|type=data|desc=fuzzy_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=tau|value=`tau'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG10 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  断点:            " %10.4f `cutoff'
display "  带宽:            " %10.4f `bandwidth'
display ""
display "  第一阶段:"
display "    跳跃幅度:      " %10.4f `fs_tau'
display "    p值:           " %10.4f `fs_p'
display ""
display "  Fuzzy RDD估计 (LATE):"
display "    效应值:        " %10.4f `tau'
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

display "SS_TASK_END|id=TG10|status=ok|elapsed_sec=`elapsed'"
log close
