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

program define ss_fail_TQ05
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=TQ05|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        display "SS_RC|code=`=_rc'|cmd=log close|msg=log_close_failed|severity=warn"
    }
    exit `code'
end

display "SS_TASK_BEGIN|id=TQ05|level=L2|title=Seasonal_Decomp"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ==============================================================================
* PHASE 5.14 REVIEW (Issue #363) / 最佳实践审查（阶段 5.14）
* - Best practice: decomposition depends on a sensible seasonal period and stable sampling frequency; inspect time gaps before interpreting seasonal factors. /
*   最佳实践：分解依赖合理的季节周期与稳定采样频率；解读季节因子前先检查时间缺口。
* - SSC deps: none / SSC 依赖：无
* - Error policy: fail on missing inputs/tsset/estimation; warn on time gaps and plot failures /
*   错误策略：缺少输入/tsset/估计失败→fail；时间缺口与绘图失败→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=363|template_id=TQ05|ssc=none|output=csv_png_dta|policy=warn_fail"

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
    ss_fail_TQ05 601 "confirm file data.csv" "input_file_not_found"
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
        ss_fail_TQ05 200 "confirm variable `var'" "var_not_found"
    }
}

capture confirm numeric variable `series_var'
if _rc {
    ss_fail_TQ05 200 "confirm numeric variable `series_var'" "series_var_not_numeric"
}

local tsvar "`time_var'"
local _ss_need_index = 0
capture confirm numeric variable `time_var'
if _rc {
    local _ss_need_index = 1
    display "SS_RC|code=TIMEVAR_NOT_NUMERIC|var=`time_var'|severity=warn"
}
if `_ss_need_index' == 0 {
    capture isid `time_var'
    if _rc {
        local _ss_need_index = 1
        display "SS_RC|code=TIMEVAR_NOT_UNIQUE|var=`time_var'|severity=warn"
    }
}
if `_ss_need_index' == 1 {
    sort `time_var'
    capture drop ss_time_index
    local rc_drop = _rc
    if `rc_drop' != 0 & `rc_drop' != 111 {
        display "SS_RC|code=`rc_drop'|cmd=drop ss_time_index|msg=drop_failed|severity=warn"
    }
    gen long ss_time_index = _n
    local tsvar "ss_time_index"
    display "SS_METRIC|name=ts_timevar|value=ss_time_index"
}
capture tsset `tsvar'
if _rc {
    ss_fail_TQ05 `=_rc' "tsset `tsvar'" "tsset_failed"
}
capture tsreport, report
if _rc == 0 {
    display "SS_METRIC|name=ts_n_gaps|value=`=r(N_gaps)'"
    if r(N_gaps) > 0 {
        display "SS_RC|code=TIME_GAPS|n_gaps=`=r(N_gaps)'|severity=warn"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 趋势提取（移动平均） ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 趋势成分"
display "═══════════════════════════════════════════════════════════════════════════════"

* 中心化移动平均
local half = floor(`period' / 2)
capture tssmooth ma trend = `series_var', window(`half' 1 `half')
if _rc {
    ss_fail_TQ05 `=_rc' "tssmooth ma" "tssmooth_failed"
}

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
generate int season = mod(`tsvar' - 1, `period') + 1

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
capture save `season_file'
if _rc {
    ss_fail_TQ05 `=_rc' "save season_file" "save_failed"
}
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
keep `tsvar' `series_var' trend seasonal residual
capture export delimited using "table_TQ05_decomp.csv", replace
if _rc {
    ss_fail_TQ05 `=_rc' "export delimited table_TQ05_decomp.csv" "export_failed"
}
display "SS_OUTPUT_FILE|file=table_TQ05_decomp.csv|type=table|desc=decomp_results"
restore

* ============ 生成分解图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成分解图"
display "═══════════════════════════════════════════════════════════════════════════════"

local plot_ok = 1
capture twoway line `series_var' `tsvar', title("原始序列") lcolor(navy) name(g_raw, replace)
if _rc {
    display "SS_RC|code=`=_rc'|cmd=twoway line raw|msg=plot_failed|severity=warn"
    local plot_ok = 0
}
capture twoway line trend `tsvar', title("趋势") lcolor(red) name(g_trend, replace)
if _rc {
    display "SS_RC|code=`=_rc'|cmd=twoway line trend|msg=plot_failed|severity=warn"
    local plot_ok = 0
}
capture twoway line seasonal `tsvar', title("季节") lcolor(green) name(g_season, replace)
if _rc {
    display "SS_RC|code=`=_rc'|cmd=twoway line seasonal|msg=plot_failed|severity=warn"
    local plot_ok = 0
}
capture twoway line residual `tsvar', title("残差") lcolor(gray) name(g_resid, replace)
if _rc {
    display "SS_RC|code=`=_rc'|cmd=twoway line residual|msg=plot_failed|severity=warn"
    local plot_ok = 0
}
if `plot_ok' {
    capture graph combine g_raw g_trend g_season g_resid, cols(1) xsize(8) ysize(10) ///
        title("时间序列分解 (`method')")
    if _rc {
        display "SS_RC|code=`=_rc'|cmd=graph combine|msg=plot_failed|severity=warn"
        local plot_ok = 0
    }
}
if `plot_ok' {
    capture graph export "fig_TQ05_decomp.png", replace width(1200)
    local rc_gexp = _rc
    if `rc_gexp' != 0 {
        display "SS_RC|code=`rc_gexp'|cmd=graph export fig_TQ05_decomp.png|msg=graph_export_failed|severity=warn"
    }
    display "SS_OUTPUT_FILE|file=fig_TQ05_decomp.png|type=figure|desc=decomp_plot"
}
else {
    display "SS_RC|code=PLOT_SKIPPED|cmd=graph|msg=decomp_plot_skipped|severity=warn"
}

capture erase "temp_season.dta"
local rc_last = _rc
if `rc_last' != 0 {
    display "SS_RC|code=`rc_last'|cmd=capture|msg=nonzero_rc|severity=warn"
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

capture save "data_TQ05_decomp.dta", replace
if _rc {
    ss_fail_TQ05 `=_rc' "save data_TQ05_decomp.dta" "save_failed"
}
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
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TQ05|status=ok|elapsed_sec=`elapsed'"
log close
