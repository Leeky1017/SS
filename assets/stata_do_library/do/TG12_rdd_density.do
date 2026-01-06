* ==============================================================================
* SS_TEMPLATE: id=TG12  level=L1  module=G  title="RDD Density"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG12_density_test.csv type=table desc="Density test results"
*   - fig_TG12_density_plot.png type=figure desc="Density plot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - rddensity source=ssc purpose="RDD density test"
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

display "SS_TASK_BEGIN|id=TG12|level=L1|title=RDD_Density"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "rddensity"
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
display "SS_DEP_CHECK|pkg=rddensity|source=ssc|status=ok"

* ============ 参数设置 ============
local running_var = "__RUNNING_VAR__"
local cutoff = __CUTOFF__
local method = "__METHOD__"

if "`method'" == "" {
    local method = "rddensity"
}

display ""
display ">>> RDD密度检验参数:"
display "    驱动变量: `running_var'"
display "    断点: `cutoff'"
display "    方法: `method'"

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
capture confirm numeric variable `running_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`running_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`running_var' not found"
    log close
    exit 200
}

* 基本统计
quietly summarize `running_var'
local rv_mean = r(mean)
local rv_min = r(min)
local rv_max = r(max)

quietly count if `running_var' < `cutoff'
local n_below = r(N)
quietly count if `running_var' >= `cutoff'
local n_above = r(N)

display ""
display ">>> 驱动变量分布:"
display "    范围: [" %8.4f `rv_min' ", " %8.4f `rv_max' "]"
display "    断点以下: `n_below' 观测"
display "    断点以上: `n_above' 观测"
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 密度检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 密度连续性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用rddensity进行检验
rddensity `running_var', c(`cutoff')

* 提取结果
local t_stat = e(T_q)
local p_value = e(pv_q)
local h_left = e(h_l)
local h_right = e(h_r)
local n_left = e(N_l)
local n_right = e(N_r)
local f_left = e(f_ql)
local f_right = e(f_qr)

display ""
display ">>> 密度检验结果:"
display "    检验统计量: " %10.4f `t_stat'
display "    p值: " %10.4f `p_value'
display ""
display "    左侧带宽: " %10.4f `h_left'
display "    右侧带宽: " %10.4f `h_right'
display "    左侧密度估计: " %10.4f `f_left'
display "    右侧密度估计: " %10.4f `f_right'

display "SS_METRIC|name=t_stat|value=`t_stat'"
display "SS_METRIC|name=p_value|value=`p_value'"

* 判断结论
if `p_value' < 0.05 {
    display ""
    display ">>> 结论: 在5%水平下拒绝密度连续性假设"
    display ">>> 警告: 可能存在断点操纵！"
    display "SS_WARNING:MANIPULATION:Density discontinuity detected at cutoff"
    local conclusion = "拒绝H0:存在操纵嫌疑"
}
else if `p_value' < 0.10 {
    display ""
    display ">>> 结论: 在5%水平下不拒绝，但在10%水平下拒绝"
    display ">>> 建议: 需要进一步检验"
    local conclusion = "边际拒绝:需进一步检验"
}
else {
    display ""
    display ">>> 结论: 不能拒绝密度连续性假设"
    display ">>> 解释: 未发现明显的断点操纵证据"
    local conclusion = "不拒绝H0:未发现操纵"
}

* 导出结果
preserve
clear
set obs 1
generate str20 test = "rddensity"
generate double t_statistic = `t_stat'
generate double p_value = `p_value'
generate double bandwidth_left = `h_left'
generate double bandwidth_right = `h_right'
generate double density_left = `f_left'
generate double density_right = `f_right'
generate long n_left = `n_left'
generate long n_right = `n_right'
generate str50 conclusion = "`conclusion'"
export delimited using "table_TG12_density_test.csv", replace
display "SS_OUTPUT_FILE|file=table_TG12_density_test.csv|type=table|desc=density_test"
restore

* ============ 生成密度图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 生成密度分布图"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用rddensity的绘图功能
capture rddensity `running_var', c(`cutoff') plot ///
    graph_options(title("驱动变量密度分布") ///
    xtitle("`running_var'") ytitle("密度") ///
    xline(`cutoff', lcolor(red) lpattern(dash)) ///
    legend(order(1 "断点以下" 2 "断点以上") position(6)))
if _rc != 0 {
    * 备用方案：手动绘制
    twoway (kdensity `running_var' if `running_var' < `cutoff', lcolor(blue)) ///
           (kdensity `running_var' if `running_var' >= `cutoff', lcolor(red)), ///
           xline(`cutoff', lcolor(black) lpattern(dash)) ///
           legend(order(1 "断点以下" 2 "断点以上") position(6)) ///
           xtitle("`running_var'") ytitle("密度") ///
           title("驱动变量密度分布")
    graph export "fig_TG12_density_plot.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG12_density_plot.png|type=figure|desc=density_plot"
}
else {
    graph export "fig_TG12_density_plot.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG12_density_plot.png|type=figure|desc=density_plot"
}

* ============ 补充检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 补充检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 直方图检验（视觉）
display ">>> 断点附近观测分布:"
local bin_width = (`rv_max' - `rv_min') / 50
local cutoff_bin_low = `cutoff' - `bin_width'
local cutoff_bin_high = `cutoff' + `bin_width'

quietly count if `running_var' >= `cutoff_bin_low' & `running_var' < `cutoff'
local n_just_below = r(N)
quietly count if `running_var' >= `cutoff' & `running_var' < `cutoff_bin_high'
local n_just_above = r(N)

display "    断点正下方bin: `n_just_below' 观测"
display "    断点正上方bin: `n_just_above' 观测"

if `n_just_below' > 0 {
    local ratio = `n_just_above' / `n_just_below'
    display "    比率(上/下): " %5.2f `ratio'
}
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=t_stat|value=`t_stat'"
display "SS_SUMMARY|key=p_value|value=`p_value'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG12 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  断点:            " %10.4f `cutoff'
display ""
display "  密度检验结果:"
display "    检验统计量:    " %10.4f `t_stat'
display "    p值:           " %10.4f `p_value'
display "    结论:          `conclusion'"
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

display "SS_TASK_END|id=TG12|status=ok|elapsed_sec=`elapsed'"
log close
