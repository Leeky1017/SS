* ==============================================================================
* SS_TEMPLATE: id=T35  level=L0  module=F  title="Event Study DID"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T35_event_coef.csv type=table desc="Dynamic coefficients by period"
*   - fig_T35_event_study.png type=graph desc="Event study coefficient plot"
*   - table_T35_paper.rtf type=table desc="Publication-quality table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
*   - estout source=ssc purpose="publication-quality tables (optional)" purpose="panel regression commands"
* ==============================================================================
* Task ID:      T35_diff_in_diff_event_study
* Task Name:    事件研究法DID
* Family:       F - 面板数据与政策评估
* Description:  估计事件研究法DID模型
* 
* Placeholders: __DEPVAR__     - 因变量
*               __TREAT_VAR__   - 处理组变量
*               __TIME_VAR__    - 时间变量
*               __EVENT_TIME__  - 事件时间变量
*               __ID_VAR__      - 个体标识变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands)
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

program define ss_fail_T35
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T35|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T35|level=L0|title=Event_Study_DID"
display "SS_SUMMARY|key=template_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* 检查 esttab (可选依赖，用于论文级表格)
local has_esttab = 0
capture which esttab
if _rc {
    display "SS_DEP_CHECK|pkg=estout|source=ssc|status=missing"
    display ">>> estout 未安装，将使用基础 CSV 导出"
} 
else {
    display "SS_DEP_CHECK|pkg=estout|source=ssc|status=ok"
    local has_esttab = 1
}

display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T35_diff_in_diff_event_study                                     ║"
display "║  TASK_NAME: 事件研究法DID（Event Study DID）                                 ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ---------- 标准化数据加载逻辑开始 ----------
display "SS_STEP_BEGIN|step=S01_load_data"
local datafile "data.dta"

capture confirm file "`datafile'"
if _rc {
    capture confirm file "data.csv"
    if _rc {
        display as error "ERROR: No data.dta or data.csv found in job directory."
        ss_fail_T35 601 "confirm file" "data_file_not_found"
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
display "SS_OUTPUT_FILE|file=`datafile'|type=data|desc=converted_from_csv"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}
* ---------- 标准化数据加载逻辑结束 ----------

local n_total = _N
display ">>> 数据加载成功: `n_total' 条观测"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 1: 变量检查与面板设置
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与面板设置"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEPVAR__"
local treat_var "__TREAT_VAR__"
local time_var "__TIME_VAR__"
local event_time "__EVENT_TIME__"
local id_var "__ID_VAR__"

display ""
display ">>> 因变量:          `dep_var'"
display ">>> 处理组指示:      `treat_var'"
display ">>> 时间变量:        `time_var'"
display ">>> 相对事件时间:    `event_time' (负=事件前, 0=事件年, 正=事件后)"
display ">>> 个体标识:        `id_var'"
display "-------------------------------------------------------------------------------"

ss_smart_xtset `id_var' `time_var'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 相对时间分布
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 相对事件时间分布"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 相对事件时间分布："
tabulate `event_time'

* 确定事件窗口
quietly summarize `event_time'
local et_min = r(min)
local et_max = r(max)

display ""
display "{hline 50}"
display "事件窗口范围:        " %5.0f `et_min' " 至 " %5.0f `et_max'
display "基准期:              t = -1"
display "{hline 50}"

* ==============================================================================
* SECTION 3: 生成事件时间虚拟变量
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成事件时间虚拟变量"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生成 Treat × I(EventTime=t) 虚拟变量"
display ">>> 基准期: t = -1（系数固定为0）"
display "-------------------------------------------------------------------------------"

* 生成各期虚拟变量（处理组 × 各期）
* 使用更合理的窗口：-4 到 +4
forvalues t = -4/4 {
    if `t' != -1 {
        local vname = cond(`t'<0, "et_m"+string(abs(`t')), "et_p"+string(`t'))
        generate `vname' = (`treat_var' == 1 & `event_time' == `t')
        label variable `vname' "Treat × I(t=`t')"
    }
}

display ">>> 事件时间虚拟变量已生成（t = -4 至 +4，排除 t = -1）"

* ==============================================================================
* SECTION 4: 事件研究回归
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 事件研究回归"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 模型: Y_it = α + Σ_τ β_τ · (Treat_i × I(t-Event=τ)) + γ_t + ε_it"
display ">>> 聚类标准误: 按个体聚类"
display "-------------------------------------------------------------------------------"

regress `dep_var' et_* i.`time_var', vce(cluster `id_var')

local n_obs = e(N)
local n_cluster = e(N_clust)
local r2 = e(r2)

* ==============================================================================
* SECTION 5: 提取系数与绘图
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 事件研究图"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 提取各期系数并绘制事件研究图"

* 存储系数
matrix coef = J(9, 4, .)
local row = 1
forvalues t = -4/4 {
    matrix coef[`row', 1] = `t'
    if `t' == -1 {
        matrix coef[`row', 2] = 0
        matrix coef[`row', 3] = 0
        matrix coef[`row', 4] = .
    }
    else {
        local vname = cond(`t'<0, "et_m"+string(abs(`t')), "et_p"+string(`t'))
        matrix coef[`row', 2] = _b[`vname']
        matrix coef[`row', 3] = _se[`vname']
        local t_val = _b[`vname'] / _se[`vname']
        matrix coef[`row', 4] = 2 * ttail(e(df_r), abs(`t_val'))
    }
    local row = `row' + 1
}

* 显示各期系数
display ""
display "{hline 60}"
display "事件时间" _col(15) "系数" _col(30) "标准误" _col(45) "p值"
display "{hline 60}"
forvalues row = 1/9 {
    local t = coef[`row', 1]
    local b = coef[`row', 2]
    local se = coef[`row', 3]
    local p = coef[`row', 4]
    if `t' == -1 {
        display %6.0f `t' _col(15) %10.4f `b' _col(30) "(基准期)"
    }
    else {
        display %6.0f `t' _col(15) %10.4f `b' _col(30) %10.4f `se' _col(45) %10.4f `p'
    }
}
display "{hline 60}"

* 转为数据集绘图
preserve
clear
svmat coef
rename coef1 event_time
rename coef2 coef
rename coef3 se
rename coef4 pvalue
generate ci_lo = coef - 1.96*se
generate ci_hi = coef + 1.96*se

twoway (rarea ci_lo ci_hi event_time, fcolor(navy%20) lwidth(none)) ///
       (rcap ci_lo ci_hi event_time, lcolor(navy)) ///
       (scatter coef event_time, mcolor(navy) msize(medium) msymbol(circle)) ///
       (function y=0, range(-4 4) lcolor(cranberry) lpattern(dash) lwidth(medium)), ///
    title("Event Study: 动态处理效应", size(medium)) ///
    subtitle("平行趋势检验 & 处理效应估计", size(small)) ///
    xtitle("相对事件时间（t=0 为事件年）") ///
    ytitle("系数估计值") ///
    xlabel(-4(1)4) ///
    xline(-0.5, lcolor(gray) lpattern(shortdash)) ///
    legend(off) ///
    note("基准期: t=-1; 阴影区域为95%置信区间; 红色虚线为零参考线", size(small)) ///
    scheme(s1color)
    
graph export "fig_T35_event_study.png", replace width(1200) height(800)
display "SS_OUTPUT_FILE|file=fig_T35_event_study.png|type=graph|desc=event_study_coefficient_plot"
restore

display ""
display ">>> 事件研究图已导出: fig_T35_event_study.png"

* ==============================================================================
* SECTION 6: 平行趋势检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 平行趋势检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 检验事件前各期系数是否联合为0"
display ">>> H0: β_{-4} = β_{-3} = β_{-2} = 0（平行趋势成立）"
display "-------------------------------------------------------------------------------"

test et_m4 et_m3 et_m2

local pretrend_f = r(F)
local pretrend_p = r(p)

display ""
display "{hline 60}"
display "事件前系数联合检验:"
display "  F统计量:           " %10.4f `pretrend_f'
display "  p值:               " %10.4f `pretrend_p'
display "{hline 60}"

if `pretrend_p' >= 0.10 {
    display ""
    display as result ">>> 不拒绝H0 (p >= 0.10): 支持平行趋势假设"
}
else {
    display ""
    display as error ">>> 拒绝H0 (p < 0.10): 平行趋势假设可能不成立"
    display as error "    建议检查数据或使用其他方法"
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出各期系数: table_T35_event_coef.csv"

preserve
clear
svmat coef
rename coef1 event_time
rename coef2 coef
rename coef3 se
rename coef4 pvalue
generate ci_lo = coef - 1.96*se
generate ci_hi = coef + 1.96*se

export delimited using "table_T35_event_coef.csv", replace
display "SS_OUTPUT_FILE|file=table_T35_event_coef.csv|type=table|desc=dynamic_coefficients"
display ">>> 各期系数已导出"
restore

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {
    display ""
    display ">>> 导出论文级表格: table_T35_paper.rtf"
    
    esttab using "table_T35_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_T35_paper.rtf|type=table|desc=publication_table"
    display ">>> 论文级表格已导出 ✓"
}
else {
    display ""
    display ">>> 跳过论文级表格 (estout 未安装)"
}


* 清理
capture drop et_*
if _rc != 0 { }

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T35 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "事件研究概况:"
display "  - 因变量:          `dep_var'"
display "  - 处理组指示:      `treat_var'"
display "  - 事件窗口:        t = -4 至 +4"
display "  - 基准期:          t = -1"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 聚类数:          " %10.0fc `n_cluster'
display ""
display "平行趋势检验:"
display "  - F统计量:         " %10.4f `pretrend_f'
display "  - p值:             " %10.4f `pretrend_p'
if `pretrend_p' >= 0.10 {
    display "  - 结论:            支持平行趋势"
}
else {
    display "  - 结论:            平行趋势可疑"
}
display ""
display "输出文件:"
display "  - fig_T35_event_study.png     事件研究系数图"
display "  - table_T35_event_coef.csv    各期系数表"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_cluster|value=`n_cluster'"
display "SS_SUMMARY|key=pretrend_p|value=`pretrend_p'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T35|status=ok|elapsed_sec=`elapsed'"

log close
