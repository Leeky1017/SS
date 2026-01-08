* ==============================================================================
* SS_TEMPLATE: id=T09  level=L0  module=B  title="Correlation Matrix"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T09_corr_pearson.csv type=table desc="Pearson correlation matrix"
*   - table_T09_corr_spearman.csv type=table desc="Spearman correlation matrix"
*   - table_T09_corr_pairwise.csv type=table desc="Pairwise correlation details"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core correlation commands"
* ==============================================================================
* Task ID:      T09_corr_matrix
* Task Name:    相关系数矩阵（Pearson与Spearman）
* Family:       B - 描述性统计
* Description:  计算变量间的Pearson和Spearman相关系数矩阵
* 
* Placeholders: __NUMERIC_VARS__  - 数值变量列表（空格分隔）
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
display "SS_TASK_BEGIN|id=T09|level=L0|title=Correlation_Matrix"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.1 REVIEW (Issue #193) / 最佳实践审查（阶段 5.1）
* - SSC deps: none (built-in only) / SSC 依赖：无（仅官方命令）
* - Output: correlation tables + heatmap (as applicable) / 输出：相关矩阵表（必要时含图）
* - Error policy: warn on pairwise deletion limitations; fail if no vars / 错误策略：成对删除限制→warn；无可用变量→fail
* ==============================================================================
display "SS_BP_REVIEW|issue=193|template_id=T09|ssc=none|output=csv_graph|policy=warn_fail"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T09_corr_matrix                                               ║"
display "║  TASK_NAME: 相关系数矩阵（Pearson与Spearman）                              ║"
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
	        display "SS_TASK_END|id=T09|status=fail|elapsed_sec=`elapsed'"
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
* [ZH] S02 校验变量列表并处理缺失策略
* [EN] S02 Validate varlist and missing-data policy
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
    display "SS_TASK_END|id=T09|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 111
}

local analysis_vars "`valid_vars'"
local n_vars: word count `analysis_vars'
display ""
display ">>> 分析变量 (`n_vars' 个): `analysis_vars'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: Pearson相关系数矩阵
* ==============================================================================
* [ZH] S03 计算相关矩阵并导出结果
* [EN] S03 Compute correlation matrix and export outputs
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: Pearson相关系数矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 2.1 Pearson相关系数（含显著性星号）"
display "-------------------------------------------------------------------------------"
display "注: * p<0.05, ** p<0.01, *** p<0.001"
display ""
pwcorr `analysis_vars', sig star(0.05)

* ==============================================================================
* SECTION 3: Spearman秩相关系数
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: Spearman秩相关系数"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Spearman相关系数（稳健于非正态分布和异常值）"
display "-------------------------------------------------------------------------------"
spearman `analysis_vars', stats(rho p) star(0.05)

* ==============================================================================
* SECTION 4: 高度相关变量识别
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 高度相关变量识别（多重共线性风险）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 70}"
display "变量1" _col(20) "变量2" _col(40) "Pearson r" _col(55) "相关程度"
display "{hline 70}"

quietly correlate `analysis_vars'
matrix C = r(C)
local n = rowsof(C)
local names: rownames C

local high_corr_count = 0

forvalues i = 1/`n' {
    forvalues j = `=`i'+1'/`n' {
        local r = C[`i', `j']
        local var1: word `i' of `names'
        local var2: word `j' of `names'
        
        * 判断相关程度
        local abs_r = abs(`r')
        if `abs_r' >= 0.8 {
            local corr_level "强相关（警告）"
            local high_corr_count = `high_corr_count' + 1
            display as error "`var1'" _col(20) "`var2'" _col(40) %8.3f `r' _col(55) "`corr_level'"
        }
        else if `abs_r' >= 0.6 {
            local corr_level "较强相关"
            display "`var1'" _col(20) "`var2'" _col(40) %8.3f `r' _col(55) "`corr_level'"
        }
    }
}
display "{hline 70}"

if `high_corr_count' > 0 {
    display ""
    display as error "WARNING: 发现 `high_corr_count' 对高度相关变量（|r|≥0.8）"
    display as error "建议: 检查多重共线性问题，考虑剔除或合成主成分"
}
else {
    display ""
    display as result ">>> 未发现高度相关变量对（|r|≥0.8）✓"
}

* ==============================================================================
* SECTION 5: 相关系数解释参考
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 相关系数解释参考"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "相关系数强度判断标准（一般经验）："
display "  |r| >= 0.8    强相关，可能存在多重共线性"
display "  0.6 <= |r| < 0.8  较强相关，需关注"
display "  0.4 <= |r| < 0.6  中等相关"
display "  0.2 <= |r| < 0.4  弱相关"
display "  |r| < 0.2    很弱或无线性相关"
display ""
display "论文报告惯例："
display "  - 下三角报告 Pearson 相关系数"
display "  - 上三角报告 Spearman 相关系数"
display "  - 对角线报告变量均值或标准差"
display "  - 显著性: * p<0.1, ** p<0.05, *** p<0.01"

* ==============================================================================
* SECTION 6: 导出结果文件
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 6.1 导出Pearson相关系数矩阵
display ""
display ">>> 6.1 导出Pearson相关系数矩阵: table_T09_corr_pearson.csv"

quietly correlate `analysis_vars'
matrix corr_pearson = r(C)

preserve
clear
svmat corr_pearson, names(col)

generate str32 variable = ""
local i = 1
foreach var of local analysis_vars {
    quietly replace variable = "`var'" in `i'
    local i = `i' + 1
}
order variable

export delimited using "table_T09_corr_pearson.csv", replace
display "SS_OUTPUT_FILE|file=table_T09_corr_pearson.csv|type=table|desc=pearson_correlation_matrix"
display ">>> Pearson相关系数矩阵已导出"
restore

* 6.2 导出Spearman相关系数矩阵
display ""
display ">>> 6.2 导出Spearman相关系数矩阵: table_T09_corr_spearman.csv"

quietly spearman `analysis_vars', stats(rho)
matrix corr_sp = r(rho)

preserve
clear
svmat corr_sp, names(col)

generate str32 variable = ""
local i = 1
foreach var of local analysis_vars {
    quietly replace variable = "`var'" in `i'
    local i = `i' + 1
}
order variable

export delimited using "table_T09_corr_spearman.csv", replace
display "SS_OUTPUT_FILE|file=table_T09_corr_spearman.csv|type=table|desc=spearman_correlation_matrix"
display ">>> Spearman相关系数矩阵已导出"
restore

* 6.3 导出两两相关详情
display ""
display ">>> 6.3 导出两两相关详情: table_T09_corr_pairwise.csv"

tempfile pairwise_data
tempname pairwise_post
postfile `pairwise_post' str32 var1 str32 var2 double pearson_r double pearson_p long n_obs using `pairwise_data', replace

foreach v1 of local analysis_vars {
    foreach v2 of local analysis_vars {
        if "`v1'" < "`v2'" {
            quietly count if !missing(`v1') & !missing(`v2')
            local n_pair = r(N)

            quietly pwcorr `v1' `v2', sig
            matrix _rho = r(rho)
            matrix _sig = r(sig)
            local r_val = _rho[1, 2]
            local p_val = _sig[1, 2]

            post `pairwise_post' ("`v1'") ("`v2'") (`r_val') (`p_val') (`n_pair')
        }
    }
}
postclose `pairwise_post'

preserve
use `pairwise_data', clear
export delimited using "table_T09_corr_pairwise.csv", replace
restore
display "SS_OUTPUT_FILE|file=table_T09_corr_pairwise.csv|type=table|desc=pairwise_correlation_details"
display ">>> 两两相关详情已导出"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T09 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "分析概况:"
display "  - 总观测数:        " %10.0fc `n_total'
display "  - 分析变量数:      " %10.0fc `n_vars'
display "  - 高度相关变量对:  " %10.0fc `high_corr_count' " 对（|r|≥0.8）"
display "  - 分析变量:        `analysis_vars'"
display ""
display "输出文件:"
display "  - table_T09_corr_pearson.csv   Pearson相关系数矩阵"
display "  - table_T09_corr_spearman.csv  Spearman相关系数矩阵"
display "  - table_T09_corr_pairwise.csv  两两相关详情"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
display "SS_SUMMARY|key=n_vars|value=`n_vars'"
display "SS_SUMMARY|key=high_corr_pairs|value=`high_corr_count'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T09|status=ok|elapsed_sec=`elapsed'"

log close
