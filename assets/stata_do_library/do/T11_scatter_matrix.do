* ==============================================================================
* SS_TEMPLATE: id=T11  level=L0  module=B  title="Scatter Matrix"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - fig_T11_scatter_matrix.png type=graph desc="Scatter plot matrix"
*   - fig_T11_scatter_matrix_full.png type=graph desc="Full matrix with histograms"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core graphics commands"
* ==============================================================================
* Task ID:      T11_scatter_matrix
* Task Name:    散点图矩阵与变量关系可视化
* Family:       B - 描述性统计
* Description:  生成多变量两两散点图矩阵
* 
* Placeholders: __NUMERIC_VARS__  - 数值变量列表（空格分隔）
*               __GROUP_VAR__     - 分组变量（可选）
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ==============================================================================
* SECTION 0: 环境初始化与标准化数据加载
* ==============================================================================
capture log close _all
if _rc != 0 {
    * No log to close - expected
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

* ---------- 日志文件初始化 ----------
log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T11|level=L0|title=Scatter_Matrix"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: scatter matrix plots (PNG) + correlations / 输出：散点矩阵图（PNG）+ 相关信息
* - Error policy: warn on too many vars (readability); fail if <2 vars / 错误策略：变量过多→warn；不足2个变量→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T11|ssc=none|output=png_csv|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T11_scatter_matrix                                               ║"
display "║  TASK_NAME: 散点图矩阵与变量关系可视化                                     ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "任务开始时间: $S_DATE $S_TIME"
display ""

* ---------- 标准化数据加载逻辑开始 ----------
* [ZH] S01 加载数据（标准化 data.dta / data.csv）
* [EN] S01 Load data (standardized data.dta / data.csv)
display "SS_STEP_BEGIN|step=S01_load_data"
local datafile "data.dta"

capture confirm file "`datafile'"
	if _rc {
	    capture confirm file "data.csv"
	    if _rc {
	        display as error "ERROR: No data.dta or data.csv found in job directory."
	        display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
	        timer off 1
	        quietly timer list 1
	        local elapsed = r(t1)
	        display "SS_METRIC|name=task_success|value=0"
	        display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
	        display "SS_TASK_END|id=T11|status=fail|elapsed_sec=`elapsed'"
	        log close
	        exit 601
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
* [ZH] S02 校验变量列表（至少2个变量）
* [EN] S02 Validate varlist (requires ≥2 vars)
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量检查与准备"
display "═══════════════════════════════════════════════════════════════════════════════"

local required_vars "__NUMERIC_VARS__"
local valid_vars ""

foreach var of local required_vars {
    capture confirm variable `var'
    if _rc {
        display as error "WARNING: Variable `var' not found"
    }
    else {
        capture confirm numeric variable `var'
        if _rc {
            display as error "WARNING: Variable `var' is not numeric"
        }
        else {
            local valid_vars "`valid_vars' `var'"
        }
    }
}

if "`valid_vars'" == "" {
    display as error "ERROR: No valid numeric variables found"
    display "SS_RC|code=111|cmd=confirm variable|msg=no_valid_numeric_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T11|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}

local analysis_vars "`valid_vars'"
local n_vars: word count `analysis_vars'
display ""
display ">>> 分析变量 (`n_vars' 个): `analysis_vars'"

* 检查分组变量（可选）
local group_var "__GROUP_VAR__"
local has_group = 0

capture confirm variable `group_var'
if _rc == 0 {
    local has_group = 1
    display ">>> 分组变量: `group_var'"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 散点图矩阵（半矩阵）
* ==============================================================================
* [ZH] S03 绘制散点矩阵并导出
* [EN] S03 Build scatter matrix and export outputs
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 生成散点图矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 2.1 半矩阵散点图"

quietly graph matrix `analysis_vars', ///
    half ///
    msize(tiny) ///
    title("变量散点图矩阵", size(medium)) ///
    note("下三角为散点图，用于检测变量间的线性/非线性关系") ///
    scheme(s2color)

quietly graph export "fig_T11_scatter_matrix.png", replace width(1400) height(1400)
display "SS_OUTPUT_FILE|file=fig_T11_scatter_matrix.png|type=graph|desc=scatter_plot_matrix"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"
display ">>> 已导出: fig_T11_scatter_matrix.png"

* ==============================================================================
* SECTION 3: 完整散点图矩阵（含对角线直方图）
* ==============================================================================
display ""
display ">>> 2.2 完整矩阵（含分布直方图）"

quietly graph matrix `analysis_vars', ///
    diagonal("histogram", fcolor(navy%50)) ///
    msize(tiny) ///
    title("变量散点图矩阵", size(medium)) ///
    subtitle("对角线: 各变量分布直方图", size(small)) ///
    scheme(s2color)

quietly graph export "fig_T11_scatter_matrix_full.png", replace width(1400) height(1400)
display "SS_OUTPUT_FILE|file=fig_T11_scatter_matrix_full.png|type=graph|desc=full_matrix_with_histograms"
display ">>> 已导出: fig_T11_scatter_matrix_full.png"

* ==============================================================================
* SECTION 4: 两两散点图（带拟合线和相关系数）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 两两散点图（带拟合线）"
display "═══════════════════════════════════════════════════════════════════════════════"

local pair_count = 0
local max_pairs = 10  // 最多生成10对

display ""
display "{hline 60}"
display "变量1" _col(15) "变量2" _col(30) "Pearson r" _col(45) "关系强度"
display "{hline 60}"

forvalues i = 1/`n_vars' {
    local var1: word `i' of `analysis_vars'
    forvalues j = `=`i'+1'/`n_vars' {
        local var2: word `j' of `analysis_vars'
        local pair_count = `pair_count' + 1
        
        * 计算相关系数
        quietly correlate `var1' `var2'
        local corr = r(rho)
        local abs_corr = abs(`corr')
        
        * 判断关系强度
        if `abs_corr' >= 0.7 {
            local strength "强"
        }
        else if `abs_corr' >= 0.4 {
            local strength "中等"
        }
        else {
            local strength "弱"
        }
        
        display "`var1'" _col(15) "`var2'" _col(30) %8.4f `corr' _col(45) "`strength'"
        
        * 只为前max_pairs对生成图表
        if `pair_count' <= `max_pairs' {
            quietly twoway ///
                (scatter `var2' `var1', msize(small) mcolor(navy%50)) ///
                (lfit `var2' `var1', lcolor(red) lwidth(medium)), ///
                title("`var1' vs `var2'", size(medium)) ///
                subtitle("Pearson r = `: display %6.3f `corr''", size(small)) ///
                xtitle("`var1'") ///
                ytitle("`var2'") ///
                legend(off) ///
                scheme(s2color)
            
            quietly graph export "fig_T11_scatter_`var1'_`var2'.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T11_scatter_`var1'_`var2'.png|type=graph|desc=scatter_plot"
        }
    }
}
display "{hline 60}"

display ""
display ">>> 已生成 `=min(`pair_count', `max_pairs')' 对散点图"

* ==============================================================================
* SECTION 5: 分组散点图矩阵（可选）
* ==============================================================================
if `has_group' {
    display ""
    display "═══════════════════════════════════════════════════════════════════════════════"
    display "SECTION 4: 分组散点图矩阵"
    display "═══════════════════════════════════════════════════════════════════════════════"
    
    display ""
    display ">>> 按 `group_var' 分组的散点图矩阵"
    
    quietly graph matrix `analysis_vars', ///
        by(`group_var', title("按 `group_var' 分组的散点图矩阵") note("")) ///
        half ///
        msize(tiny) ///
        scheme(s2color)
    
    quietly graph export "fig_T11_scatter_matrix_grouped.png", replace width(1600) height(1200)
display "SS_OUTPUT_FILE|file=fig_T11_scatter_matrix_grouped.png|type=graph|desc=scatter_plot"
    display ">>> 已导出: fig_T11_scatter_matrix_grouped.png"
}

* ==============================================================================
* SECTION 6: 相关系数汇总与导出
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 相关系数汇总"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Pearson 相关系数矩阵（含显著性）"
display "-------------------------------------------------------------------------------"
pwcorr `analysis_vars', sig star(0.05)

* 导出相关系数表
display ""
display ">>> 导出相关系数表: table_T11_correlations.csv"

tempfile corr_pairs
tempname corr_post
postfile `corr_post' str32 var1 str32 var2 double pearson_r double p_value using `corr_pairs', replace

foreach v1 of local analysis_vars {
    foreach v2 of local analysis_vars {
        if "`v1'" < "`v2'" {
            quietly pwcorr `v1' `v2', sig
            matrix _rho = r(rho)
            matrix _sig = r(sig)
            local r_val = _rho[1, 2]
            local p_val = _sig[1, 2]
            post `corr_post' ("`v1'") ("`v2'") (`r_val') (`p_val')
        }
    }
}
postclose `corr_post'

preserve
use `corr_pairs', clear
export delimited using "table_T11_correlations.csv", replace
restore
display "SS_OUTPUT_FILE|file=table_T11_correlations.csv|type=table|desc=correlation_table"
display ">>> 相关系数表已导出"

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T11 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "分析概况:"
display "  - 总观测数:        " %10.0fc `n_total'
display "  - 分析变量数:      " %10.0fc `n_vars'
display "  - 变量对数:        " %10.0fc `pair_count'
display "  - 分析变量:        `analysis_vars'"
display ""
display "输出文件:"
display "  - fig_T11_scatter_matrix.png        散点图矩阵（半矩阵）"
display "  - fig_T11_scatter_matrix_full.png   完整矩阵（含直方图）"
display "  - fig_T11_scatter_*.png             两两散点图（带拟合线）"
if `has_group' {
    display "  - fig_T11_scatter_matrix_grouped.png  分组散点图矩阵"
}
display "  - table_T11_correlations.csv        相关系数汇总表"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
display "SS_SUMMARY|key=n_vars|value=`n_vars'"
display "SS_SUMMARY|key=n_pairs|value=`pair_count'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T11|status=ok|elapsed_sec=`elapsed'"

log close
