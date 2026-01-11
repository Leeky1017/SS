* ==============================================================================
* SS_TEMPLATE: id=TQ05  level=L2  module=Q  title="Seasonal Decomp"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TQ05_decomp.csv type=table desc="Decomposition results"
*   - fig_TQ05_decomp.png type=figure desc="Decomposition plot"
*   - data_TQ05_decomp.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TQ05|level=L2|title=Seasonal_Decomp"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local series_var = "__SERIES_VAR__"
local time_var = "__TIME_VAR__"
local period = __PERIOD__
local method = "__METHOD__"

if `period' < 2 | `period' > 52 {
    local period = 12
}
if "`method'" == "" {
    local method = "additive"
}

display ""
display ">>> 季节性分解参数:"
display "    序列变量: `series_var'"
display "    季节周期: `period'"
display "    分解方法: `method'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    display "SS_TASK_END|id=TQ05|status=fail|elapsed_sec=."
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `series_var' `time_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_RC|code=200|cmd=confirm variable|msg=var_not_found|severity=fail|var=`var'"
        display "SS_TASK_END|id=TQ05|status=fail|elapsed_sec=."
        log close
        exit 200
    }
}

tsset `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 趋势提取（移动平均） ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 趋势成分"
display "═══════════════════════════════════════════════════════════════════════════════"

* 中心化移动平均
local half = floor(`period' / 2)
tssmooth ma trend = `series_var', window(`half' 1 `half')

quietly summarize trend
display ""
display ">>> 趋势统计:"
display "    均值: " %12.4f r(mean)
display "    标准差: " %12.4f r(sd)

* ============ 去趋势 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 季节成分"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`method'" == "multiplicative" {
    generate double detrended = `series_var' / trend
}
else {
    generate double detrended = `series_var' - trend
}

* 计算季节因子
generate int season = mod(`time_var' - 1, `period') + 1

* 计算各季节平均
tempname season_factors
postfile `season_factors' int season double factor using "temp_season.dta", replace

forvalues s = 1/`period' {
    quietly summarize detrended if season == `s'
    local sf = r(mean)
    post `season_factors' (`s') (`sf')
}

postclose `season_factors'

* 合并季节因子
preserve
use "temp_season.dta", clear

* 标准化使季节因子和为0（加法）或均值为1（乘法）
if "`method'" == "multiplicative" {
    quietly summarize factor
    replace factor = factor / r(mean)
}
else {
    quietly summarize factor
    replace factor = factor - r(mean)
}

tempfile season_file
save `season_file'
restore

merge m:1 season using `season_file', nogenerate

rename factor seasonal

* ============ 残差 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 残差成分"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`method'" == "multiplicative" {
    generate double residual = `series_var' / (trend * seasonal)
}
else {
    generate double residual = `series_var' - trend - seasonal
}

quietly summarize residual
local resid_mean = r(mean)
local resid_sd = r(sd)

display ""
display ">>> 残差统计:"
display "    均值: " %12.6f `resid_mean'
display "    标准差: " %12.6f `resid_sd'

display "SS_METRIC|name=resid_sd|value=`resid_sd'"

* ============ 导出分解结果 ============
preserve
keep `time_var' `series_var' trend seasonal residual
export delimited using "table_TQ05_decomp.csv", replace
display "SS_OUTPUT_FILE|file=table_TQ05_decomp.csv|type=table|desc=decomp_results"
restore

* ============ 生成分解图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成分解图"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway line `series_var' `time_var', title("原始序列") lcolor(navy) name(g_raw, replace)
twoway line trend `time_var', title("趋势") lcolor(red) name(g_trend, replace)
twoway line seasonal `time_var', title("季节") lcolor(green) name(g_season, replace)
twoway line residual `time_var', title("残差") lcolor(gray) name(g_resid, replace)
graph combine g_raw g_trend g_season g_resid, cols(1) xsize(8) ysize(10) ///
    title("时间序列分解 (`method')")
graph export "fig_TQ05_decomp.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TQ05_decomp.png|type=figure|desc=decomp_plot"

capture erase "temp_season.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TQ05_decomp.dta", replace
display "SS_OUTPUT_FILE|file=data_TQ05_decomp.dta|type=data|desc=decomp_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TQ05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  季节周期:        " %10.0fc `period'
display "  分解方法:        `method'"
display ""
display "  残差统计:"
display "    均值:          " %12.6f `resid_mean'
display "    标准差:        " %12.6f `resid_sd'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=resid_sd|value=`resid_sd'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ05|status=ok|elapsed_sec=`elapsed'"
log close
