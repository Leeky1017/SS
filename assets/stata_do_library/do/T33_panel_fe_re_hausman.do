* ==============================================================================
* SS_TEMPLATE: id=T33  level=L0  module=F  title="Hausman Specification Test"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T33_hausman.csv type=table desc="Hausman test results"
*   - table_T33_comparison.csv type=table desc="FE/RE coefficient comparison"
*   - table_T33_paper.docx type=report desc="Publication-style table (docx)"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
* ==============================================================================
* Task ID:      T33_panel_fe_re_hausman
* Task Name:    FE/RE比较与Hausman检验
* Family:       F - 面板数据与政策评估
* Description:  比较FE和RE模型，进行Hausman检验
* 
* Placeholders: __DEPVAR__     - 因变量
*               __INDEPVARS__  - 自变量列表
*               __ID_VAR__      - 个体标识变量
*               __TIME_VAR__    - 时间变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands)
* ==============================================================================

* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.2)
* - 2026-01-08: Keep Hausman test as the explicit FE vs RE decision point (保留 Hausman 检验作为 FE/RE 选择依据).
* - 2026-01-08: Replace optional SSC `estout/esttab` with Stata 18 native `putdocx` report (移除 SSC 依赖，使用原生 docx 输出).
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 {
    display "SS_RC|code=`=_rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

program define ss_fail_T33
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T33|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T33|level=L0|title=Hausman_Specification_Test"
display "SS_SUMMARY|key=template_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T33_panel_fe_re_hausman                                          ║"
display "║  TASK_NAME: FE/RE比较与Hausman检验                                          ║"
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
        ss_fail_T33 601 "confirm file" "data_file_not_found"
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
local indep_vars "__INDEPVARS__"
local id_var "__ID_VAR__"
local time_var "__TIME_VAR__"

display ""
display ">>> 因变量:          `dep_var'"
display ">>> 自变量:          `indep_vars'"
display ">>> 个体变量:        `id_var'"
display ">>> 时间变量:        `time_var'"
display "-------------------------------------------------------------------------------"

* ---------- Panel pre-checks (T31–T33 通用) ----------
capture confirm variable `id_var'
if _rc {
    display as error "ERROR: ID variable `id_var' not found（个体标识变量不存在）."
    ss_fail_T33 111 "confirm variable" "id_var_not_found"
}

capture confirm variable `time_var'
if _rc {
    display as error "ERROR: Time variable `time_var' not found（时间变量不存在）."
    ss_fail_T33 111 "confirm variable" "time_var_not_found"
}

capture ss_smart_xtset `id_var' `time_var'
if _rc {
    display as error "ERROR: Failed to xtset panel structure with `id_var' and `time_var'（面板结构设置失败）."
    ss_fail_T33 200 "runtime" "task_failed"
}

tempvar __panel_first
quietly bysort `id_var': gen byte `__panel_first' = (_n == 1) if !missing(`id_var')
quietly count if `__panel_first' == 1
local n_groups_check = r(N)
drop `__panel_first'

if `n_groups_check' <= 1 {
    display as error "ERROR: Panel models require at least 2 groups in `id_var'（面板个体数必须大于 1）."
    ss_fail_T33 200 "runtime" "task_failed"
}
display ">>> 面板设置成功: `n_groups_check' 个个体"
* ---------- Panel pre-checks end ----------

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 固定效应回归
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 固定效应回归（FE）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
xtreg `dep_var' `indep_vars', fe
estimates store fe

local r2_w_fe = e(r2_w)
local r2_o_fe = e(r2_o)
local n_obs = e(N)
local n_groups = e(N_g)

* ==============================================================================
* SECTION 3: 随机效应回归
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 随机效应回归（RE）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
xtreg `dep_var' `indep_vars', re
estimates store re

local r2_w_re = e(r2_w)
local r2_o_re = e(r2_o)

* ==============================================================================
* SECTION 4: 模型对比
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: FE vs RE 系数对比"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
estimates table fe re, star stats(N r2_w r2_o) b(%9.4f) se(%9.4f)

* ==============================================================================
* SECTION 5: Hausman检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: Hausman检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Hausman检验原理："
display "    H0: Cov(α_i, X_it) = 0 → RE一致且有效"
display "    H1: Cov(α_i, X_it) ≠ 0 → 仅FE一致"
display ""
display ">>> 检验统计量: H = (β_FE - β_RE)'[Var(β_FE) - Var(β_RE)]^(-1)(β_FE - β_RE)"
display ">>> 分布: χ²(K)"
display "-------------------------------------------------------------------------------"

hausman fe re

local h_chi2 = r(chi2)
local h_df = r(df)
local h_p = r(p)

display ""
display "{hline 60}"
display "Hausman χ²(" %3.0f `h_df' "):           " %12.4f `h_chi2'
display "Prob > χ²:                    " %12.4f `h_p'
display "{hline 60}"

* ==============================================================================
* SECTION 6: 检验结论与推荐
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 检验结论与模型推荐"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
local recommended = ""
if `h_p' < 0.05 {
    display as result ">>> 检验结论: 拒绝H0 (p = " %6.4f `h_p' " < 0.05)"
    display ""
    display "    个体效应与自变量相关，RE不一致"
    display "    ════════════════════════════════════════"
    display "    推荐模型: 固定效应（FE）+ 聚类标准误"
    display "    ════════════════════════════════════════"
    local recommended = "FE"
}
else {
    display as result ">>> 检验结论: 不拒绝H0 (p = " %6.4f `h_p' " >= 0.05)"
    display ""
    display "    个体效应与自变量不相关，RE一致且有效"
    display "    ════════════════════════════════════════"
    display "    推荐模型: 随机效应（RE）+ 稳健标准误"
    display "    ════════════════════════════════════════"
    local recommended = "RE"
}

* ==============================================================================
* SECTION 7: 推荐模型输出
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 推荐模型回归结果"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
if "`recommended'" == "FE" {
    display ">>> 固定效应模型（聚类标准误）："
    xtreg `dep_var' `indep_vars', fe vce(cluster `id_var')
}
else {
    display ">>> 随机效应模型（稳健标准误）："
    xtreg `dep_var' `indep_vars', re vce(robust)
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出Hausman检验结果
display ""
display ">>> 导出Hausman检验结果: table_T33_hausman.csv"

preserve
clear
set obs 1

generate double chi2 = `h_chi2'
generate int df = `h_df'
generate double p = `h_p'
generate str10 recommended = "`recommended'"

export delimited using "table_T33_hausman.csv", replace
display "SS_OUTPUT_FILE|file=table_T33_hausman.csv|type=table|desc=hausman_test_results"
display ">>> Hausman检验结果已导出"
restore
* 导出FE/RE系数对比表
display ""
display ">>> 导出FE/RE系数对比表: table_T33_comparison.csv"

preserve
clear
local nvars: word count `indep_vars'
local nrows = `nvars' + 1
set obs `nrows'

generate str32 variable = ""
generate double coef_fe = .
generate double se_fe = .
generate double coef_re = .
generate double se_re = .

local varlist "`indep_vars' _cons"
local i = 1
foreach var of local varlist {
    quietly replace variable = "`var'" in `i'
    estimates restore fe
    quietly replace coef_fe = _b[`var'] in `i'
    quietly replace se_fe = _se[`var'] in `i'
    estimates restore re
    quietly replace coef_re = _b[`var'] in `i'
    quietly replace se_re = _se[`var'] in `i'
    local i = `i' + 1
}

export delimited using "table_T33_comparison.csv", replace
display "SS_OUTPUT_FILE|file=table_T33_comparison.csv|type=table|desc=fe_re_comparison"
display ">>> FE/RE系数对比表已导出"

display ""
display ">>> 导出论文级表格: table_T33_paper.docx"
putdocx clear
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("T33: Hausman Test / FE-RE 选择")
local __hchi2_s : display %6.3f `h_chi2'
local __hdf_s : display %3.0f `h_df'
local __hp_s : display %6.4f `h_p'
putdocx paragraph
putdocx text ("Hausman: chi2=`__hchi2_s', df=`__hdf_s', p=`__hp_s'")
putdocx paragraph
putdocx text ("Recommended: `recommended'")
putdocx table t1 = data(variable coef_fe se_fe coef_re se_re), varnames
putdocx save "table_T33_paper.docx", replace
display "SS_OUTPUT_FILE|file=table_T33_paper.docx|type=report|desc=publication_table_docx"
display ">>> 论文级表格已导出 ✓"
restore

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T33 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 个体数:          " %10.0fc `n_groups'
display ""
display "Hausman检验:"
display "  - χ²统计量:        " %10.4f `h_chi2'
display "  - 自由度:          " %10.0f `h_df'
display "  - p值:             " %10.4f `h_p'
display ""
display "模型选择:"
if "`recommended'" == "FE" {
    display "  - 推荐模型:        固定效应（FE）"
}
else {
    display "  - 推荐模型:        随机效应（RE）"
}
display ""
display "输出文件:"
display "  - table_T33_hausman.csv       Hausman检验结果"
display "  - table_T33_comparison.csv    FE/RE系数对比表"
display "  - table_T33_paper.docx         论文级表格（docx）"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=hausman_chi2|value=`h_chi2'"
display "SS_SUMMARY|key=hausman_p|value=`h_p'"
display "SS_SUMMARY|key=n_obs|value=`n_obs'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T33|status=ok|elapsed_sec=`elapsed'"

log close
