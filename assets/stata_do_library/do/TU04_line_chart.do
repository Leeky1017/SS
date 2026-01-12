* ==============================================================================
* SS_TEMPLATE: id=TU04  level=L1  module=U  title="Line Chart"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - fig_TU04_line.png type=figure desc="Line chart"
*   - data_TU04_line.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Sort by the x-axis variable and label units; time-series-like charts should reflect correct ordering.
* - When comparing groups, keep consistent scales and limit the number of lines for readability.
* - Consider uncertainty bands or smoothing only when justified; document any transformations.
* 最佳实践审查（ZH）:
* - 请按 x 轴变量排序并标注单位；类时间序列折线图需保证顺序正确。
* - 分组对比时保持一致尺度并避免过多折线，以保证可读性。
* - 不确定性带/平滑需有依据；任何变换都应明确记录。

* ============ 初始化 ============
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

display "SS_TASK_BEGIN|id=TU04|level=L1|title=Line_Chart"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local yvar = "__YVAR__"
local xvar = "__XVAR__"
local by_var = "__BY_VAR__"

display ""
display ">>> 折线图参数:"
display "    Y变量: `yvar'"
display "    X变量: `xvar'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate plotting variables existence/type.
* ZH: 校验绘图变量存在且为数值型。

* ============ 变量检查 ============
foreach var in `yvar' `xvar' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm numeric variable|msg=var_not_found|severity=fail"
        log close
        exit 200
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Plot line chart (optionally by group) and export outputs.
* ZH: 绘制折线图（可选分组）并导出输出。

sort `xvar'

* ============ 绘制折线图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 绘制折线图"
display "═══════════════════════════════════════════════════════════════════════════════"

capture confirm variable `by_var'
if !_rc & "`by_var'" != "" & "`by_var'" != "__BY_VAR__" {
    separate `yvar', by(`by_var')
    local sep_vars = r(varlist)
    
    twoway (line `sep_vars' `xvar', lwidth(medium..)), ///
        title("趋势图: `yvar'") ///
        xtitle("`xvar'") ytitle("`yvar'") ///
        legend(position(6))
}
else {
    twoway (line `yvar' `xvar', lcolor(navy) lwidth(medium)), ///
        title("趋势图: `yvar'") ///
        xtitle("`xvar'") ytitle("`yvar'")
}

graph export "fig_TU04_line.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TU04_line.png|type=figure|desc=line_chart"

* 趋势统计
quietly summarize `yvar'
local mean_y = r(mean)
local sd_y = r(sd)

display ""
display ">>> `yvar' 统计:"
display "    均值: " %12.4f `mean_y'
display "    标准差: " %12.4f `sd_y'

display "SS_METRIC|name=mean_y|value=`mean_y'"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU04_line.dta", replace
display "SS_OUTPUT_FILE|file=data_TU04_line.dta|type=data|desc=line_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  均值:            " %10.4f `mean_y'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=mean_y|value=`mean_y'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU04|status=ok|elapsed_sec=`elapsed'"
log close
