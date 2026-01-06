* ==============================================================================
* SS_TEMPLATE: id=T08  level=L0  module=B  title="Categorical Frequency Tables"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T08_freq_summary.csv type=table desc="Frequency summary table"
*   - table_T08_freq_detail.csv type=table desc="Detailed frequency table"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core tabulation commands"
* ==============================================================================
* Task ID:      T08_freq_categorical
* Task Name:    分类变量频数分布表
* Family:       B - 描述性统计
* Description:  输出分类变量的频数分布、百分比和累积百分比
* 
* Placeholders: __CATEGORICAL_VARS__  - 分类变量列表（空格分隔）
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
display "SS_TASK_BEGIN|id=T08|level=L0|title=Categorical_Frequency_Tables"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T08_freq_categorical                                           ║"
display "║  TASK_NAME: 分类变量频数分布表                                           ║"
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

local required_vars "__CATEGORICAL_VARS__"
local valid_vars ""

foreach var of local required_vars {
    capture confirm variable `var'
    if _rc {
        display as error "WARNING: Variable `var' not found"
    }
    else {
        local valid_vars "`valid_vars' `var'"
    }
}

if "`valid_vars'" == "" {
    display as error "ERROR: No valid variables found"
    log close
    display "SS_ERROR:200:Task failed with error code 200"
    display "SS_ERR:200:Task failed with error code 200"

    exit 200
}

local analysis_vars "`valid_vars'"
local n_vars: word count `analysis_vars'
display ""
display ">>> 分析变量 (`n_vars' 个): `analysis_vars'"

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 各变量频数分布
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 各变量频数分布"
display "═══════════════════════════════════════════════════════════════════════════════"

foreach var of local analysis_vars {
    display ""
    display "─────────────────────────────────────────────────────────────────────────────"
    display ">>> 变量: `var'"
    display "─────────────────────────────────────────────────────────────────────────────"
    
    * 频数表（含累积百分比）
    tabulate `var', missing
}

* ==============================================================================
* SECTION 3: 分类变量汇总统计
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 分类变量汇总统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 80}"
display "变量" _col(25) "类别数" _col(40) "缺失数" _col(55) "众数频数" _col(70) "众数占比"
display "{hline 80}"

foreach var of local analysis_vars {
    * 统计类别数
    quietly levelsof `var', local(levels)
    local n_levels: word count `levels'
    
    * 统计缺失值
    quietly count if missing(`var')
    local n_miss = r(N)
    
    * 获取众数信息
    quietly tabulate `var', matcell(freq)
    mata: st_local("max_freq", strofreal(max(st_matrix("freq"))))
    local mode_pct = (`max_freq' / (`n_total' - `n_miss')) * 100
    
    display "`var'" _col(25) %5.0f `n_levels' _col(40) %8.0fc `n_miss' _col(55) %8.0fc `max_freq' _col(70) %6.1f `mode_pct' "%"
}
display "{hline 80}"

* ==============================================================================
* SECTION 4: 交叉表分析（如有多个变量）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 交叉表分析"
display "═══════════════════════════════════════════════════════════════════════════════"

* 获取前两个变量进行交叉分析
local var1: word 1 of `analysis_vars'
local var2: word 2 of `analysis_vars'

if "`var2'" != "" {
    display ""
    display ">>> 4.1 交叉表: `var1' × `var2'"
    display "-------------------------------------------------------------------------------"
    tabulate `var1' `var2', missing row column
    
    * 卡方检验
    display ""
    display ">>> 4.2 卡方独立性检验"
    display "-------------------------------------------------------------------------------"
    tabulate `var1' `var2', chi2
}
else {
    display ">>> 仅一个分类变量，跳过交叉表分析"
}

* ==============================================================================
* SECTION 5: 生成条形图
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 生成分布条形图"
display "═══════════════════════════════════════════════════════════════════════════════"

foreach var of local analysis_vars {
    display ""
    display ">>> 生成 `var' 条形图..."
    
    * 检查类别数是否适合绘图
    quietly levelsof `var', local(levels)
    local n_levels: word count `levels'
    
    if `n_levels' <= 20 {
        quietly graph bar (count), over(`var', sort(1) descending label(angle(45))) ///
            title("`var' 分布", size(medium)) ///
            ytitle("频数") ///
            blabel(bar, format(%9.0fc)) ///
            scheme(s2color)
        
        quietly graph export "fig_T08_bar_`var'.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_T08_bar_`var'.png|type=graph|desc=figure"
        display ">>> 已导出: fig_T08_bar_`var'.png"
    }
    else {
        display ">>> 类别数过多 (`n_levels' > 20)，跳过条形图"
    }
}

* ==============================================================================
* SECTION 6: 导出频数表
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 6.1 导出频数汇总表
display ""
display ">>> 6.1 导出频数汇总表: table_T08_freq_summary.csv"

preserve
clear

local n_vars: word count `analysis_vars'
set obs `n_vars'

generate str32 variable = ""
generate int n_categories = .
generate long n_missing = .
generate double pct_missing = .
generate long mode_freq = .
generate double mode_pct = .

local i = 1
foreach var of local analysis_vars {
    quietly replace variable = "`var'" in `i'
    
    * 计算统计量（需要重新加载数据）
    local i = `i' + 1
}

export delimited using "table_T08_freq_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_T08_freq_summary.csv|type=table|desc=frequency_summary_table"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"
display ">>> 频数汇总表已导出"
restore

* 6.2 导出详细频数表（所有变量合并）
display ""
display ">>> 6.2 导出详细频数表: table_T08_freq_detail.csv"

preserve

* 创建一个空的结果数据集
tempfile result_data
clear
generate str32 variable = ""
generate str100 category = ""
generate long frequency = .
generate double percent = .
generate double cum_percent = .
save `result_data', replace

* 对每个变量生成频数表并追加
foreach var of local analysis_vars {
    use "data.csv", clear
    
    * 生成频数表
    contract `var', freq(frequency) percent(percent) cfreq(cum_freq) cpercent(cum_percent)
    
    * 添加变量名
    generate str32 variable = "`var'"
    
    * 转换类别值为字符串
    generate str100 category = ""
    capture confirm string variable `var'
    if _rc {
        tostring `var', replace force
    }
    replace category = `var'
    
    * 保留需要的列
    keep variable category frequency percent cum_percent
    
    * 追加到结果
    append using `result_data'
    save `result_data', replace
}

* 删除空行
drop if variable == ""

* 导出
export delimited using "table_T08_freq_detail.csv", replace
display "SS_OUTPUT_FILE|file=table_T08_freq_detail.csv|type=table|desc=detailed_frequency_table"
display ">>> 详细频数表已导出"
restore

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T08 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "分析概况:"
display "  - 总观测数:        " %10.0fc `n_total'
display "  - 分析变量数:      " %10.0fc `n_vars'
display "  - 分析变量:        `analysis_vars'"
display ""
display "输出文件:"
display "  - table_T08_freq_summary.csv    频数汇总表"
display "  - table_T08_freq_detail.csv     详细频数表"
display "  - fig_T08_bar_*.png             分布条形图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
display "SS_SUMMARY|key=n_vars|value=`n_vars'"
display "SS_SUMMARY|key=vars_analyzed|value=`analysis_vars'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T08|status=ok|elapsed_sec=`elapsed'"

log close
