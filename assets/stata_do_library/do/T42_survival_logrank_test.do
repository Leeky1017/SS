* ==============================================================================
* SS_TEMPLATE: id=T42  level=L0  module=H  title="Log-rank Test"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T42_logrank.csv type=table desc="Log-rank test results"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="survival analysis commands"
* ==============================================================================
* Task ID:      T42_survival_logrank_test
* Task Name:    Log-rank检验
* Family:       H - 生存分析
* Description:  进行组间生存曲线的Log-rank检验
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

program define ss_fail_T42
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T42|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T42|level=L0|title=Log_rank_Test"
display "SS_SUMMARY|key=template_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T42_survival_logrank_test                                      ║"
display "║  TASK_NAME: Log-rank检验（生存曲线比较）                                  ║"
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
        ss_fail_T42 601 "confirm file" "data_file_not_found"
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
display ">>> 事件变量:        `event_var'"
display ">>> 分组变量:        `group_var'"
display "-------------------------------------------------------------------------------"

* ---------- Survival pre-checks (T41–T44 通用) ----------
capture confirm variable `time_var'
if _rc {
    display as error "ERROR: Time variable `time_var' not found（时间变量不存在）."
    ss_fail_T42 111 "confirm variable" "time_var_not_found"
}

capture confirm variable `event_var'
if _rc {
    display as error "ERROR: Event variable `event_var' not found（事件变量不存在）."
    ss_fail_T42 111 "confirm variable" "event_var_not_found"
}

capture confirm variable `group_var'
if _rc {
    display as error "ERROR: Group variable `group_var' not found（分组变量不存在）."
    ss_fail_T42 111 "confirm variable" "group_var_not_found"
}

quietly count if `time_var' < 0 & !missing(`time_var')
if r(N) > 0 {
    display as error "ERROR: Survival time `time_var' contains negative values（生存时间存在负值）."
    ss_fail_T42 200 "runtime" "task_failed"
}

quietly count if `event_var' != 0 & `event_var' != 1 & !missing(`event_var')
if r(N) > 0 {
    display as error "ERROR: Event variable `event_var' must be coded as 0/1（事件变量必须为0/1编码）."
    ss_fail_T42 111 "confirm variable" "event_var_not_found"
}

quietly count if `event_var' == 1 & !missing(`event_var')
if r(N) == 0 {
    display as error "ERROR: No events (=1) found in `event_var'（无事件发生，无法进行生存分析）."
    ss_fail_T42 200 "runtime" "task_failed"
}
display ">>> 生存数据检查通过"
* ---------- Survival pre-checks end ----------

stset `time_var', failure(`event_var')

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 各组生存数据描述
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 各组生存数据描述"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 组别分布："
tabulate `group_var'

display ""
display ">>> 各组生存统计："
stsum, by(`group_var')

display ""
display ">>> 各组中位生存时间："
stci, by(`group_var')

* ==============================================================================
* SECTION 3: Log-rank检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: Log-rank检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Log-rank检验（最常用）："
display "    H0: 各组生存函数无差异"
display "    H1: 各组生存函数存在差异"
display "-------------------------------------------------------------------------------"

sts test `group_var'

local lr_chi2 = r(chi2)
local lr_df = r(df)
local lr_p = r(p)

display ""
display "{hline 50}"
display "Log-rank χ²:         " %12.4f `lr_chi2'
display "自由度:              " %12.0f `lr_df'
display "p值:                 " %12.4f `lr_p'
display "{hline 50}"

if `lr_p' < 0.05 {
    display ""
    display as result ">>> 拒绝H0 (p < 0.05): 各组生存曲线存在显著差异"
}
else {
    display ""
    display as text ">>> 不拒绝H0 (p >= 0.05): 各组生存曲线无显著差异"
}

* ==============================================================================
* SECTION 4: 其他非参数检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 其他非参数检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Wilcoxon (Breslow) 检验（对早期差异更敏感）："
sts test `group_var', wilcoxon

local wil_chi2 = r(chi2)
local wil_p = r(p)

display ""
display ">>> Tarone-Ware检验（Log-rank与Wilcoxon的折中）："
sts test `group_var', tware

local tw_chi2 = r(chi2)
local tw_p = r(p)

display ""
display ">>> Peto-Peto检验："
sts test `group_var', peto

local pp_chi2 = r(chi2)
local pp_p = r(p)

* ==============================================================================
* SECTION 5: 检验结果汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 检验结果汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 60}"
display "检验方法              χ²统计量      自由度      p值"
display "{hline 60}"
display "Log-rank            " %12.4f `lr_chi2' "    " %4.0f `lr_df' "    " %8.4f `lr_p'
display "Wilcoxon            " %12.4f `wil_chi2' "    " %4.0f `lr_df' "    " %8.4f `wil_p'
display "Tarone-Ware         " %12.4f `tw_chi2' "    " %4.0f `lr_df' "    " %8.4f `tw_p'
display "Peto-Peto           " %12.4f `pp_chi2' "    " %4.0f `lr_df' "    " %8.4f `pp_p'
display "{hline 60}"

display ""
display ">>> 检验方法选择建议："
display "    - Log-rank: 比例风险成立时最优"
display "    - Wilcoxon: 早期差异明显时更敏感"
display "    - 若各检验结果不一致，需检查比例风险假设"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 6: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出检验结果: table_T42_logrank.csv"

preserve
clear
set obs 4

generate str20 test = ""
generate double chi2 = .
generate int df = .
generate double p_value = .

replace test = "log_rank" in 1
replace chi2 = `lr_chi2' in 1
replace df = `lr_df' in 1
replace p_value = `lr_p' in 1

replace test = "wilcoxon" in 2
replace chi2 = `wil_chi2' in 2
replace df = `lr_df' in 2
replace p_value = `wil_p' in 2

replace test = "tarone_ware" in 3
replace chi2 = `tw_chi2' in 3
replace df = `lr_df' in 3
replace p_value = `tw_p' in 3

replace test = "peto_peto" in 4
replace chi2 = `pp_chi2' in 4
replace df = `lr_df' in 4
replace p_value = `pp_p' in 4

export delimited using "table_T42_logrank.csv", replace
display "SS_OUTPUT_FILE|file=table_T42_logrank.csv|type=table|desc=logrank_test_results"
display ">>> 检验结果已导出"
restore

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T42 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "检验结果:"
display "  - Log-rank χ²:     " %10.4f `lr_chi2'
display "  - p值:             " %10.4f `lr_p'
if `lr_p' < 0.05 {
    display "  - 结论:            各组生存曲线显著不同 ✓"
}
else {
    display "  - 结论:            各组生存曲线无显著差异"
}
display ""
display "输出文件:"
display "  - table_T42_logrank.csv    检验结果"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=lr_chi2|value=`lr_chi2'"
display "SS_SUMMARY|key=lr_p|value=`lr_p'"
display "SS_SUMMARY|key=lr_df|value=`lr_df'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_subjects'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T42|status=ok|elapsed_sec=`elapsed'"

log close
