* ==============================================================================
* SS_TEMPLATE: id=T41  level=L0  module=H  title="Kaplan-Meier Survival Curve"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - fig_T41_km.png type=graph desc="Grouped KM survival curve"
*   - fig_T41_km_overall.png type=graph desc="Overall KM survival curve"
*   - table_T41_survival.csv type=table desc="Survival statistics"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="survival analysis commands"
* ==============================================================================
* Task ID:      T41_survival_km_curve
* Task Name:    Kaplan-Meier生存曲线
* Family:       H - 生存分析
* Description:  绘制KM生存曲线，估计生存函数
* 
* Placeholders: __TIME_VAR__    - 生存时间变量
*               __EVENT_VAR__   - 事件变量
*               __GROUP_VAR__   - 分组变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
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

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T41|level=L0|title=Kaplan_Meier_Survival_Curve"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T41_survival_km_curve                                          ║"
display "║  TASK_NAME: Kaplan-Meier生存曲线（Survival Curve）                        ║"
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
        display as error "ERROR: No data.dta or data.csv found."
        log close
        display "SS_ERROR:200:Task failed with error code 200"
        display "SS_ERR:200:Task failed with error code 200"

        exit 200
    }
    import delimited "data.csv", clear varnames(1) encoding(utf8)
    save "`datafile'", replace
display "SS_OUTPUT_FILE|file=`datafile'|type=table|desc=output"
    display ">>> 已从 data.csv 转换并保存为 data.dta"
}
else {
    use "`datafile'", clear
}
local n_total = _N
display ">>> 数据加载成功: `n_total' 条观测"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 1: 变量设置与生存数据声明
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量设置与生存数据声明"
display "═══════════════════════════════════════════════════════════════════════════════"

local time_var "__TIME_VAR__"
local event_var "__EVENT_VAR__"
local group_var "__GROUP_VAR__"

display ""
display ">>> 时间变量:        `time_var'"
display ">>> 事件变量:        `event_var' (1=事件发生, 0=删失)"
display ">>> 分组变量:        `group_var'"
display "-------------------------------------------------------------------------------"

* ---------- Survival pre-checks (T41–T44 通用) ----------
capture confirm variable `time_var'
if _rc {
    display as error "ERROR: Time variable `time_var' not found（时间变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `event_var'
if _rc {
    display as error "ERROR: Event variable `event_var' not found（事件变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

capture confirm variable `group_var'
if _rc {
    display as error "ERROR: Group variable `group_var' not found（分组变量不存在）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

quietly count if `time_var' < 0 & !missing(`time_var')
if r(N) > 0 {
    display as error "ERROR: Survival time `time_var' contains negative values（生存时间存在负值）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

quietly count if `event_var' != 0 & `event_var' != 1 & !missing(`event_var')
if r(N) > 0 {
    display as error "ERROR: Event variable `event_var' must be coded as 0/1（事件变量必须为0/1编码）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

quietly count if `event_var' == 1 & !missing(`event_var')
if r(N) == 0 {
    display as error "ERROR: No events (=1) found in `event_var'（无事件发生，无法进行生存分析）."
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}
display ">>> 生存数据检查通过"
* ---------- Survival pre-checks end ----------

stset `time_var', failure(`event_var')

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 生存数据概况
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 生存数据概况"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 生存数据描述："
stdescribe

display ""
display ">>> 生存时间汇总："
stsum

quietly stsum
local n_subjects = r(N_sub)
local n_events = r(N_fail)
local time_total = r(tr)

display ""
display "{hline 50}"
display "研究对象数:          " %10.0fc `n_subjects'
display "事件发生数:          " %10.0fc `n_events'
display "删失数:              " %10.0fc `n_subjects' - `n_events'
display "总随访时间:          " %10.2f `time_total'
display "{hline 50}"

* ==============================================================================
* SECTION 3: 总体Kaplan-Meier曲线
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 总体Kaplan-Meier曲线"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 绘制总体生存曲线"

sts graph, ///
    title("Kaplan-Meier 生存曲线", size(medium)) ///
    ytitle("生存概率 S(t)") ///
    xtitle("时间") ///
    ci ///
    note("阴影区域为95%置信区间", size(small)) ///
    scheme(s1color)

graph export "fig_T41_km_overall.png", replace width(1000) height(700)
display "SS_OUTPUT_FILE|file=fig_T41_km_overall.png|type=graph|desc=overall_km_curve"
display ">>> 总体生存曲线已导出: fig_T41_km_overall.png"

* ==============================================================================
* SECTION 4: 分组Kaplan-Meier曲线
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 分组Kaplan-Meier曲线"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 绘制分组生存曲线"

sts graph, by(`group_var') ///
    title("分组 Kaplan-Meier 生存曲线", size(medium)) ///
    ytitle("生存概率 S(t)") ///
    xtitle("时间") ///
    legend(position(6) rows(1)) ///
    scheme(s1color)

graph export "fig_T41_km.png", replace width(1000) height(700)
display "SS_OUTPUT_FILE|file=fig_T41_km.png|type=graph|desc=grouped_km_curve"
display ">>> 分组生存曲线已导出: fig_T41_km.png"

* ==============================================================================
* SECTION 5: 中位生存时间
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 中位生存时间"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各组中位生存时间及95%置信区间："
stci, by(`group_var')

* ==============================================================================
* SECTION 6: 特定时间点生存概率
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 特定时间点生存概率"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 特定时间点的生存概率估计："
sts list, at(30 90 180 365) by(`group_var')

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出生存统计: table_T41_survival.csv"

preserve
clear
set obs 1

generate int n_subjects = `n_subjects'
generate int n_events = `n_events'
generate int n_censored = `n_subjects' - `n_events'
generate double total_time = `time_total'

export delimited using "table_T41_survival.csv", replace
display "SS_OUTPUT_FILE|file=table_T41_survival.csv|type=table|desc=survival_statistics"
display ">>> 生存统计已导出"
restore

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T41 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "生存数据概况:"
display "  - 研究对象数:      " %10.0fc `n_subjects'
display "  - 事件发生数:      " %10.0fc `n_events'
display "  - 删失数:          " %10.0fc `n_subjects' - `n_events'
display "  - 删失比例:        " %10.2f (1 - `n_events'/`n_subjects')*100 "%"
display ""
display "输出文件:"
display "  - fig_T41_km_overall.png   总体生存曲线"
display "  - fig_T41_km.png           分组生存曲线"
display "  - table_T41_survival.csv   生存统计"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_subjects|value=`n_subjects'"
display "SS_SUMMARY|key=n_events|value=`n_events'"
display "SS_SUMMARY|key=total_time|value=`time_total'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_subjects'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T41|status=ok|elapsed_sec=`elapsed'"

log close
