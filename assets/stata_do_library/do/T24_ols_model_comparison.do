* ==============================================================================
* SS_TEMPLATE: id=T24  level=L0  module=D  title="Model Comparison"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T24_model_comparison.csv type=table desc="Model comparison metrics"
*   - table_T24_paper.docx type=report desc="Publication-style table (docx)"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core commands"
* ==============================================================================
* Task ID:      T24_ols_model_comparison
* Task Name:    多模型对比
* Family:       D - 线性回归
* Description:  比较多个回归模型的关键指标
* 
* Placeholders: __DEPVAR__     - 因变量
*               __BASE_VARS__   - 基础模型变量
*               __FULL_VARS__   - 完整模型变量
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official + community commands)
* ==============================================================================

* ==============================================================================
* BEST_PRACTICE_REVIEW (Phase 5.2)
* - 2026-01-08: Keep nested-model comparison via AIC/BIC and LR test where applicable (保留 AIC/BIC + 嵌套模型 LR 检验).
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

program define ss_fail_T24
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T24|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T24|level=L0|title=Model_Comparison"
display "SS_SUMMARY|key=template_version|value=2.1.0"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T24_ols_model_comparison                                         ║"
display "║  TASK_NAME: 多模型对比（Model Comparison）                                   ║"
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
        ss_fail_T24 601 "confirm file" "data_file_not_found"
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
* SECTION 1: 变量检查与准备
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与准备"
display "═══════════════════════════════════════════════════════════════════════════════"

local dep_var "__DEPVAR__"
local base_vars "__BASE_VARS__"
local full_vars "__FULL_VARS__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    ss_fail_T24 111 "confirm variable" "dep_var_not_found"
}

display ""
display ">>> 因变量:          `dep_var'"
display ">>> 基础模型变量:    `base_vars'"
display ">>> 完整模型变量:    `full_vars'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 模型1 - 基础模型
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 模型1 - 基础模型"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
regress `dep_var' `base_vars'

estimates store model1
local r2_1 = e(r2)
local r2a_1 = e(r2_a)
local n_1 = e(N)
local k_1 = e(rank)
local rmse_1 = e(rmse)
local aic_1 = -2*e(ll) + 2*e(rank)
local bic_1 = -2*e(ll) + e(rank)*ln(e(N))

* ==============================================================================
* SECTION 3: 模型2 - 完整模型
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 模型2 - 完整模型"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
regress `dep_var' `full_vars'

estimates store model2
local r2_2 = e(r2)
local r2a_2 = e(r2_a)
local n_2 = e(N)
local k_2 = e(rank)
local rmse_2 = e(rmse)
local aic_2 = -2*e(ll) + 2*e(rank)
local bic_2 = -2*e(ll) + e(rank)*ln(e(N))

* ==============================================================================
* SECTION 4: 模型比较汇总
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 模型比较汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "指标" _col(25) "模型1(基础)" _col(45) "模型2(完整)" _col(60) "更优"
display "{hline 70}"
display "样本量 (N)" _col(25) %10.0fc `n_1' _col(45) %10.0fc `n_2'
display "参数数量 (k)" _col(25) %10.0f `k_1' _col(45) %10.0f `k_2'

* R² 比较
if `r2_2' > `r2_1' {
    display "R²" _col(25) %10.4f `r2_1' _col(45) %10.4f `r2_2' _col(60) "模型2"
}
else {
    display "R²" _col(25) %10.4f `r2_1' _col(45) %10.4f `r2_2' _col(60) "模型1"
}

* 调整R² 比较
if `r2a_2' > `r2a_1' {
    display "调整R²" _col(25) %10.4f `r2a_1' _col(45) %10.4f `r2a_2' _col(60) "模型2"
}
else {
    display "调整R²" _col(25) %10.4f `r2a_1' _col(45) %10.4f `r2a_2' _col(60) "模型1"
}

* RMSE 比较
if `rmse_2' < `rmse_1' {
    display "RMSE" _col(25) %10.4f `rmse_1' _col(45) %10.4f `rmse_2' _col(60) "模型2"
}
else {
    display "RMSE" _col(25) %10.4f `rmse_1' _col(45) %10.4f `rmse_2' _col(60) "模型1"
}

* AIC 比较
if `aic_2' < `aic_1' {
    display "AIC" _col(25) %10.2f `aic_1' _col(45) %10.2f `aic_2' _col(60) "模型2"
}
else {
    display "AIC" _col(25) %10.2f `aic_1' _col(45) %10.2f `aic_2' _col(60) "模型1"
}

* BIC 比较
if `bic_2' < `bic_1' {
    display "BIC" _col(25) %10.2f `bic_1' _col(45) %10.2f `bic_2' _col(60) "模型2"
}
else {
    display "BIC" _col(25) %10.2f `bic_1' _col(45) %10.2f `bic_2' _col(60) "模型1"
}
display "{hline 70}"

display ""
display ">>> R² 增量:         " %10.4f (`r2_2' - `r2_1')
display ">>> 调整R² 增量:     " %10.4f (`r2a_2' - `r2a_1')
display ">>> AIC 变化:        " %10.2f (`aic_2' - `aic_1') " (负值表示改善)"
display ">>> BIC 变化:        " %10.2f (`bic_2' - `bic_1') " (负值表示改善)"

* ==============================================================================
* SECTION 5: 嵌套模型检验（似然比检验）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 嵌套模型检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 似然比检验（LR Test）"
display ">>> H0: 新增变量的系数联合为零"
display "-------------------------------------------------------------------------------"

lrtest model1 model2

local lr_chi2 = r(chi2)
local lr_df = r(df)
local lr_p = r(p)

display ""
if `lr_p' < 0.05 {
    display as result ">>> 新增变量联合显著 (p < 0.05)"
    display "    完整模型显著优于基础模型 ✓"
}
else {
    display as error ">>> 新增变量不显著 (p ≥ 0.05)"
    display "    新增变量对模型改善有限"
}

* ==============================================================================
* SECTION 6: 系数对比表
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 系数对比表"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
estimates table model1 model2, star stats(N r2 r2_a aic bic) b(%9.4f) se(%9.4f)

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 导出模型比较指标: table_T24_model_comparison.csv"

preserve
clear
set obs 2

generate str20 model = ""
generate int n = .
generate int k = .
generate double r2 = .
generate double r2_adj = .
generate double rmse = .
generate double aic = .
generate double bic = .

quietly replace model = "基础模型" in 1
quietly replace n = `n_1' in 1
quietly replace k = `k_1' in 1
quietly replace r2 = `r2_1' in 1
quietly replace r2_adj = `r2a_1' in 1
quietly replace rmse = `rmse_1' in 1
quietly replace aic = `aic_1' in 1
quietly replace bic = `bic_1' in 1

quietly replace model = "完整模型" in 2
quietly replace n = `n_2' in 2
quietly replace k = `k_2' in 2
quietly replace r2 = `r2_2' in 2
quietly replace r2_adj = `r2a_2' in 2
quietly replace rmse = `rmse_2' in 2
quietly replace aic = `aic_2' in 2
quietly replace bic = `bic_2' in 2

export delimited using "table_T24_model_comparison.csv", replace
display "SS_OUTPUT_FILE|file=table_T24_model_comparison.csv|type=table|desc=model_comparison"
display ">>> 模型比较指标已导出"

display ""
display ">>> 导出论文级表格: table_T24_paper.docx"
putdocx clear
putdocx begin
putdocx paragraph, style(Heading1)
putdocx text ("T24: Model Comparison / 多模型对比")
putdocx paragraph
putdocx text ("Metrics: N, k, R2, Adj R2, RMSE, AIC, BIC.")
putdocx table t1 = data(model n k r2 r2_adj rmse aic bic), varnames
putdocx save "table_T24_paper.docx", replace
display "SS_OUTPUT_FILE|file=table_T24_paper.docx|type=report|desc=publication_table_docx"
display ">>> 论文级表格已导出 ✓"
restore
* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T24 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型比较结果:"
display "  - 因变量:              `dep_var'"
display "  - 基础模型变量数:     " %5.0f `k_1' - 1
display "  - 完整模型变量数:     " %5.0f `k_2' - 1
display ""
display "拟合优度比较:"
display "  - R² 增量:            " %10.4f (`r2_2' - `r2_1')
display "  - 调整R² 增量:        " %10.4f (`r2a_2' - `r2a_1')
display ""
display "模型选择检验:"
display "  - LR χ²:              " %10.4f `lr_chi2'
display "  - 自由度:             " %10.0f `lr_df'
display "  - p 值:               " %10.4f `lr_p'
display ""
display "输出文件:"
display "  - table_T24_model_comparison.csv   模型比较指标表"
display "  - table_T24_paper.docx             论文级表格（docx）"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=r2_base|value=`r2_1'"
display "SS_SUMMARY|key=r2_full|value=`r2_2'"
display "SS_SUMMARY|key=lr_p|value=`lr_p'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_1'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T24|status=ok|elapsed_sec=`elapsed'"

log close
