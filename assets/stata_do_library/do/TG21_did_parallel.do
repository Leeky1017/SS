* ==============================================================================
* SS_TEMPLATE: id=TG21  level=L1  module=G  title="DID Parallel"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG21_parallel_test.csv type=table desc="Parallel test"
*   - table_TG21_pretrend_coefs.csv type=table desc="Pretrend coefs"
*   - fig_TG21_trends.png type=graph desc="Trends"
*   - fig_TG21_pretrend_test.png type=graph desc="Pretrend test"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
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

display "SS_TASK_BEGIN|id=TG21|level=L1|title=DID_Parallel"
display "SS_TASK_VERSION|version=2.0.1"

display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local treat_var = "__TREAT_VAR__"
local time_var = "__TIME_VAR__"
local treatment_time = __TREATMENT_TIME__
local id_var = "__ID_VAR__"

display ""
display ">>> 平行趋势检验参数:"
display "    结果变量: `outcome_var'"
display "    处理组: `treat_var'"
display "    时间变量: `time_var'"
display "    处理时间: `treatment_time'"

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
foreach var in `outcome_var' `treat_var' `time_var' {
    capture confirm numeric variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

	* 设置面板（如果有ID变量）
	if "`id_var'" != "" {
	    capture confirm variable `id_var'
	    if !_rc {
	        capture xtset `id_var' `time_var'
	    }
	}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 视觉检验：趋势图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 视觉检验 - 组别趋势图"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算各时间点各组均值
preserve
collapse (mean) mean_y = `outcome_var' (sd) sd_y = `outcome_var' (count) n = `outcome_var', by(`treat_var' `time_var')

* 计算标准误
generate se_y = sd_y / sqrt(n)
generate ci_lower = mean_y - 1.96 * se_y
generate ci_upper = mean_y + 1.96 * se_y

* 绘制趋势图
twoway (connected mean_y `time_var' if `treat_var' == 1, lcolor(red) mcolor(red)) ///
       (connected mean_y `time_var' if `treat_var' == 0, lcolor(blue) mcolor(blue)) ///
       (rarea ci_lower ci_upper `time_var' if `treat_var' == 1, color(red%20)) ///
       (rarea ci_lower ci_upper `time_var' if `treat_var' == 0, color(blue%20)), ///
       xline(`treatment_time', lcolor(black) lpattern(dash)) ///
       legend(order(1 "处理组" 2 "对照组") position(6)) ///
       xtitle("时间") ytitle("`outcome_var'均值") ///
       title("组别趋势对比") ///
       note("虚线=处理时间, 阴影=95%置信区间")
graph export "fig_TG21_trends.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG21_trends.png|type=graph|desc=trends"
restore

* ============ 事件研究法检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 事件研究法检验"
display "═══════════════════════════════════════════════════════════════════════════════"

* 生成相对时间
generate int rel_time = `time_var' - `treatment_time'
label variable rel_time "相对处理时间"

* 获取相对时间范围
quietly summarize rel_time
local rt_min = r(min)
local rt_max = r(max)

display ">>> 相对时间范围: `rt_min' 到 `rt_max'"

* 生成时间虚拟变量与处理组交互项
quietly levelsof rel_time, local(rel_times)

local pretrend_vars ""
local posttrend_vars ""

foreach rt of local rel_times {
    if `rt' != -1 {
        local rt_abs = abs(`rt')
        if `rt' < 0 {
            local varname "lead`rt_abs'"
        }
        else {
            local varname "lag`rt'"
        }
        
        generate byte `varname' = `treat_var' * (rel_time == `rt')
        
        if `rt' < -1 {
            local pretrend_vars "`pretrend_vars' `varname'"
        }
        else if `rt' >= 0 {
            local posttrend_vars "`posttrend_vars' `varname'"
        }
    }
}

display ">>> 预处理期变量: `pretrend_vars'"
display ">>> 处理后变量: `posttrend_vars'"

* 运行事件研究回归
regress `outcome_var' `pretrend_vars' `posttrend_vars' i.`time_var' i.`treat_var', robust

* 提取预处理期系数
tempname pretrend_coefs
postfile `pretrend_coefs' int rel_time double coef double se double t double p double ci_lower double ci_upper ///
    using "temp_pretrend_coefs.dta", replace

* 基准期
post `pretrend_coefs' (-1) (0) (0) (.) (.) (0) (0)

* 预处理期系数
foreach rt of local rel_times {
    if `rt' < -1 {
        local rt_abs = abs(`rt')
        local varname "lead`rt_abs'"
        
        local coef = _b[`varname']
        local se = _se[`varname']
        local t = `coef' / `se'
        local p = 2 * ttail(e(df_r), abs(`t'))
        local ci_l = `coef' - 1.96 * `se'
        local ci_u = `coef' + 1.96 * `se'
        
        post `pretrend_coefs' (`rt') (`coef') (`se') (`t') (`p') (`ci_l') (`ci_u')
    }
}

* 处理后系数
foreach rt of local rel_times {
    if `rt' >= 0 {
        local varname "lag`rt'"
        
        local coef = _b[`varname']
        local se = _se[`varname']
        local t = `coef' / `se'
        local p = 2 * ttail(e(df_r), abs(`t'))
        local ci_l = `coef' - 1.96 * `se'
        local ci_u = `coef' + 1.96 * `se'
        
        post `pretrend_coefs' (`rt') (`coef') (`se') (`t') (`p') (`ci_l') (`ci_u')
    }
}

postclose `pretrend_coefs'

* 导出系数
preserve
use "temp_pretrend_coefs.dta", clear
sort rel_time
export delimited using "table_TG21_pretrend_coefs.csv", replace
display "SS_OUTPUT_FILE|file=table_TG21_pretrend_coefs.csv|type=table|desc=pretrend_coefs"

* 绘制系数图
twoway (rarea ci_lower ci_upper rel_time, color(navy%20)) ///
       (scatter coef rel_time, mcolor(navy)) ///
       (rcap ci_lower ci_upper rel_time, lcolor(navy)), ///
       xline(-0.5, lcolor(red) lpattern(dash)) ///
       yline(0, lcolor(gray) lpattern(dot)) ///
       xtitle("相对处理时间") ytitle("估计系数") ///
       title("事件研究: 平行趋势检验") ///
       legend(off) ///
       note("基准期=t-1, 红色虚线=处理时间")
graph export "fig_TG21_pretrend_test.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG21_pretrend_test.png|type=graph|desc=pretrend_test"
restore

* ============ 联合显著性检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 预处理期联合显著性检验"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`pretrend_vars'" != "" {
    test `pretrend_vars'
    local f_stat = r(F)
    local f_p = r(p)
    local f_df1 = r(df)
    local f_df2 = r(df_r)
    
    display ""
    display ">>> 预处理期系数联合检验:"
    display "    H0: 所有预处理期系数=0（平行趋势成立）"
    display "    F统计量: " %10.4f `f_stat'
    display "    自由度: (`f_df1', `f_df2')"
    display "    p值: " %10.4f `f_p'
    
    if `f_p' >= 0.10 {
        display ""
        display ">>> 结论: 不能拒绝平行趋势假设 (p=" %5.4f `f_p' ")"
        local parallel_conclusion = "通过:平行趋势假设成立"
    }
    else if `f_p' >= 0.05 {
        display ""
        display ">>> 结论: 在10%水平拒绝平行趋势 (p=" %5.4f `f_p' ")"
display "SS_RC|code=0|cmd=warning|msg=parallel_marginal|detail=Marginal_rejection_of_parallel_trends|severity=warn"
        local parallel_conclusion = "边际拒绝:需谨慎"
    }
    else {
        display ""
        display ">>> 结论: 拒绝平行趋势假设 (p=" %5.4f `f_p' ")"
display "SS_RC|code=0|cmd=warning|msg=parallel_rejected|detail=Parallel_trends_assumption_rejected|severity=warn"
        local parallel_conclusion = "拒绝:平行趋势不成立"
    }
    
    display "SS_METRIC|name=parallel_f|value=`f_stat'"
    display "SS_METRIC|name=parallel_p|value=`f_p'"
}
else {
    display ">>> 预处理期不足，无法进行联合检验"
    local f_stat = .
    local f_p = .
    local parallel_conclusion = "无法检验:预处理期不足"
}

* ============ 导出检验结果 ============
preserve
clear
set obs 1
generate str30 test = "Joint F-test"
generate double f_statistic = `f_stat'
generate double p_value = `f_p'
generate str50 conclusion = "`parallel_conclusion'"
generate int n_pretrend_periods = `: word count `pretrend_vars''

export delimited using "table_TG21_parallel_test.csv", replace
display "SS_OUTPUT_FILE|file=table_TG21_parallel_test.csv|type=table|desc=parallel_test"
restore
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=parallel_f|value=`f_stat'"
display "SS_SUMMARY|key=parallel_p|value=`f_p'"

* 清理
capture erase "temp_pretrend_coefs.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG21 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理时间:        `treatment_time'"
display "  相对时间范围:    `rt_min' 到 `rt_max'"
display ""
display "  平行趋势检验:"
display "    F统计量:       " %10.4f `f_stat'
display "    p值:           " %10.4f `f_p'
display "    结论:          `parallel_conclusion'"
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

display "SS_TASK_END|id=TG21|status=ok|elapsed_sec=`elapsed'"
log close
