* ==============================================================================
* SS_TEMPLATE: id=T28  level=L0  module=E  title="Multinomial Logit Model"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T28_mlogit_gof.csv type=table desc="Goodness of fit"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="multinomial logit commands"
* ==============================================================================
* Task ID:      T28_mlogit_multinomial
* Task Name:    多项Logit模型
* Family:       E - 有限因变量模型
* Description:  估计无序多分类因变量的Multinomial Logit模型
* 
* Placeholders: __DEPVAR__        - 因变量（无序多分类）
*               __INDEPVARS__     - 自变量列表
*               __BASE_CATEGORY__  - 基础类别
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
display "SS_TASK_BEGIN|id=T28|level=L0|title=Multinomial_Logit_Model"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T28_mlogit_multinomial                                           ║"
display "║  TASK_NAME: 多项Logit模型（Multinomial Logistic Regression）                 ║"
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
local indep_vars "__INDEPVARS__"
local base_cat "__BASE_CATEGORY__"

capture confirm variable `dep_var'
if _rc {
    display as error "ERROR: Dependent variable `dep_var' not found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

display ""
display ">>> 因变量:          `dep_var' (无序多分类)"
display ">>> 自变量:          `indep_vars'"
display ">>> 基准类别:        `base_cat'"
display ""

* 因变量分布
display ">>> 因变量频率分布："
tabulate `dep_var'

quietly levelsof `dep_var', local(levels)
local n_levels: word count `levels'
display ""
display "{hline 50}"
display "类别数量:            " %10.0f `n_levels'
display "基准类别:            " %10.0f `base_cat'
display "{hline 50}"

if `n_levels' < 3 {
    display as error "WARNING: 因变量仅有 `n_levels' 个类别，建议使用二元Logit"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 多项Logit回归（系数）
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 多项Logit回归（系数）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 模型: ln[P(Y=j)/P(Y=base)] = X'βⱼ"
display ">>> 系数解释: 相对于基准类别的对数几率变化"
display ">>> 基准类别: `base_cat'"
display "-------------------------------------------------------------------------------"

mlogit `dep_var' `indep_vars', baseoutcome(`base_cat')

estimates store mlogit_model
local ll = e(ll)
local ll_0 = e(ll_0)
local pseudo_r2 = e(r2_p)
local n_obs = e(N)
local chi2 = e(chi2)
local p_chi2 = e(p)

* ==============================================================================
* SECTION 3: 相对风险比（Relative Risk Ratio）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 相对风险比（Relative Risk Ratio）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> RRR解释: 自变量增加1单位，选择类别j相对于基准类别的几率变化"
display ">>> RRR > 1: 更倾向于选择类别j"
display ">>> RRR < 1: 更倾向于选择基准类别"
display "-------------------------------------------------------------------------------"

mlogit `dep_var' `indep_vars', baseoutcome(`base_cat') rrr

* ==============================================================================
* SECTION 4: 各类别边际效应
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 各类别边际效应"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 边际效应: 自变量变化1单位，各类别选择概率的变化"
display ">>> 注意: 各类别边际效应之和为0"
display "-------------------------------------------------------------------------------"

quietly mlogit `dep_var' `indep_vars', baseoutcome(`base_cat')

* 计算各类别边际效应
local cat_count = 0
foreach lev of local levels {
    local cat_count = `cat_count' + 1
    if `cat_count' <= 3 {
        display ""
        display ">>> 类别 `lev' 的边际效应:"
        margins, dydx(*) predict(outcome(`lev'))
    }
}

if `cat_count' > 3 {
    display ""
    display ">>> (仅显示前3个类别的边际效应)"
}

* ==============================================================================
* SECTION 5: 预测概率
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 预测概率"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各类别的平均预测概率："

quietly mlogit `dep_var' `indep_vars', baseoutcome(`base_cat')

foreach lev of local levels {
    quietly margins, predict(outcome(`lev'))
    matrix M = r(table)
    local prob = M[1,1]
    display "    P(Y=`lev'):  " %8.4f `prob'
}

* ==============================================================================
* SECTION 6: 模型拟合优度
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 模型拟合优度"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 60}"
display "对数似然 (Log-Likelihood):     " %12.4f `ll'
display "零模型对数似然 (LL₀):          " %12.4f `ll_0'
display "Pseudo R² (McFadden):          " %12.4f `pseudo_r2'
display "LR χ²:                         " %12.4f `chi2'
display "Prob > χ²:                     " %12.4f `p_chi2'
display "样本量:                        " %12.0fc `n_obs'
display "类别数:                        " %12.0f `n_levels'
display "{hline 60}"

* ==============================================================================
* SECTION 7: IIA假设说明
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: IIA假设（Independence of Irrelevant Alternatives）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 多项Logit假设各选项相互独立（IIA）"
display ">>> 即: 两个选项之间的相对几率不受第三个选项影响"
display ""
display ">>> 如果IIA可能被违反（如选项相似），考虑使用:"
display "    - 嵌套Logit（nested logit）"
display "    - 混合Logit（mixed logit）"
display ""
display ">>> 提示: IIA假设需在实际研究中通过理论判断"
display ">>> 可通过分别排除某类别后重新估计，对比系数变化检验IIA"

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 8: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出拟合优度
display ""
display ">>> 导出拟合优度: table_T28_mlogit_gof.csv"

preserve
clear
set obs 1

generate double n = `n_obs'
generate int n_categories = `n_levels'
generate int base_category = `base_cat'
generate double ll = `ll'
generate double pseudo_r2 = `pseudo_r2'
generate double chi2 = `chi2'
generate double p_chi2 = `p_chi2'

export delimited using "table_T28_mlogit_gof.csv", replace
display "SS_OUTPUT_FILE|file=table_T28_mlogit_gof.csv|type=table|desc=goodness_of_fit"
display ">>> 拟合优度已导出"
restore

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T28 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "模型概况:"
display "  - 因变量:          `dep_var'"
display "  - 自变量:          `indep_vars'"
display "  - 基准类别:        `base_cat'"
display "  - 样本量:          " %10.0fc `n_obs'
display "  - 类别数:          " %10.0f `n_levels'
display ""
display "拟合优度:"
display "  - Pseudo R²:       " %10.4f `pseudo_r2'
display "  - LR χ²:           " %10.4f `chi2'
display ""
display "输出文件:"
display "  - table_T28_mlogit_gof.csv    拟合优度指标"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_obs'"
display "SS_SUMMARY|key=n_categories|value=`n_levels'"
display "SS_SUMMARY|key=pseudo_r2|value=`pseudo_r2'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T28|status=ok|elapsed_sec=`elapsed'"

log close
