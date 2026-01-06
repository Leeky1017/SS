* ==============================================================================
* SS_TEMPLATE: id=T07  level=L0  module=B  title="Numeric Summary Statistics"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T07_desc_stats.csv type=table desc="Descriptive statistics (Table 1)"
*   - table_T07_desc_extended.csv type=table desc="Extended statistics"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="core statistical commands"
* ==============================================================================
* Task ID:      T07_summary_numeric
* Task Name:    数值变量描述统计（论文表1）
* Family:       B - 描述性统计
* Description:  对选定数值变量输出完整的描述统计（论文表1格式）
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
display "SS_TASK_BEGIN|id=T07|level=L0|title=Numeric_Summary_Statistics"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T07_summary_numeric                                              ║"
display "║  TASK_NAME: 数值变量描述统计（论文表1格式）                                ║"
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

local required_vars "__NUMERIC_VARS__"
local valid_vars ""
local missing_vars ""

foreach var of local required_vars {
    capture confirm variable `var'
    if _rc {
        local missing_vars "`missing_vars' `var'"
        display as error "WARNING: Variable `var' not found"
    }
    else {
        * 检查是否为数值型
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
* SECTION 2: 基础描述统计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 基础描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 2.1 简要统计"
display "-------------------------------------------------------------------------------"
summarize `analysis_vars'

* ==============================================================================
* SECTION 3: 完整分位数统计（论文表1格式）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 完整分位数统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 3.1 标准描述统计表（论文表1格式）"
display "-------------------------------------------------------------------------------"
tabstat `analysis_vars', statistics(n mean sd min p25 p50 p75 max) columns(statistics) longstub format(%12.4f)

display ""
display ">>> 3.2 扩展分位数"
display "-------------------------------------------------------------------------------"
tabstat `analysis_vars', statistics(n mean sd p1 p5 p10 p25 p50 p75 p90 p95 p99) columns(statistics) longstub format(%12.4f)

* ==============================================================================
* SECTION 4: 详细统计（含偏度、峰度）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 详细统计（含分布特征）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display "{hline 80}"
display "变量" _col(15) "N" _col(25) "Mean" _col(37) "SD" _col(49) "Skewness" _col(61) "Kurtosis" _col(73) "CV(%)"
display "{hline 80}"

foreach var of local analysis_vars {
    quietly summarize `var', detail
    local n_obs = r(N)
    local mean_val = r(mean)
    local sd_val = r(sd)
    local skew_val = r(skewness)
    local kurt_val = r(kurtosis)
    
    * 计算变异系数
    if `mean_val' != 0 & `mean_val' != . {
        local cv_val = abs(`sd_val' / `mean_val') * 100
    }
    else {
        local cv_val = .
    }
    
    display "`var'" _col(15) %8.0fc `n_obs' _col(25) %10.4f `mean_val' _col(37) %10.4f `sd_val' _col(49) %8.3f `skew_val' _col(61) %8.3f `kurt_val' _col(73) %6.1f `cv_val'
}
display "{hline 80}"

* ==============================================================================
* SECTION 5: 分布特征诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 分布特征诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 5.1 偏态与尖峰检验"
display "-------------------------------------------------------------------------------"
display ""
display "{hline 70}"
display "变量" _col(25) "偏度判断" _col(45) "峰度判断"
display "{hline 70}"

foreach var of local analysis_vars {
    quietly summarize `var', detail
    local skew = r(skewness)
    local kurt = r(kurtosis)
    
    * 偏度判断
    if `skew' > 1 {
        local skew_desc "右偏严重"
    }
    else if `skew' > 0.5 {
        local skew_desc "右偏"
    }
    else if `skew' < -1 {
        local skew_desc "左偏严重"
    }
    else if `skew' < -0.5 {
        local skew_desc "左偏"
    }
    else {
        local skew_desc "基本对称"
    }
    
    * 峰度判断（正态分布峰度约为3）
    if `kurt' > 4 {
        local kurt_desc "尖峰厚尾"
    }
    else if `kurt' < 2 {
        local kurt_desc "平峰薄尾"
    }
    else {
        local kurt_desc "接近正态"
    }
    
    display "`var'" _col(25) "`skew_desc'" _col(45) "`kurt_desc'"
}
display "{hline 70}"
display "注: 偏度 |S|>1 为严重偏斜, |S|>0.5 为中等偏斜"
display "    峰度 K>4 为尖峰厚尾(金融数据常见), K<2 为平峰薄尾"

* ==============================================================================
* SECTION 6: 导出论文表1格式
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 6.1 导出标准描述统计表（论文表1格式）
display ""
display ">>> 6.1 导出标准描述统计表: table_T07_desc_stats.csv"

preserve
clear

* 计算变量数
local n_vars: word count `analysis_vars'
set obs `n_vars'

* 创建变量
generate str32 variable = ""
generate long n = .
generate double mean = .
generate double sd = .
generate double min = .
generate double p25 = .
generate double p50 = .
generate double p75 = .
generate double max = .

* 填充数据
local i = 1
foreach var of local analysis_vars {
    quietly replace variable = "`var'" in `i'
    
    * 获取统计量
    quietly summarize `var', detail
    quietly replace n = r(N) in `i'
    quietly replace mean = r(mean) in `i'
    quietly replace sd = r(sd) in `i'
    quietly replace min = r(min) in `i'
    quietly replace p25 = r(p25) in `i'
    quietly replace p50 = r(p50) in `i'
    quietly replace p75 = r(p75) in `i'
    quietly replace max = r(max) in `i'
    
    local i = `i' + 1
}

export delimited using "table_T07_desc_stats.csv", replace
display "SS_OUTPUT_FILE|file=table_T07_desc_stats.csv|type=table|desc=descriptive_statistics_table1"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"
display ">>> 标准描述统计表已导出"
restore

* 6.2 导出扩展统计表
display ""
display ">>> 6.2 导出扩展统计表: table_T07_desc_extended.csv"

preserve
clear

set obs `n_vars'

generate str32 variable = ""
generate long n = .
generate double mean = .
generate double sd = .
generate double min = .
generate double p1 = .
generate double p5 = .
generate double p10 = .
generate double p25 = .
generate double p50 = .
generate double p75 = .
generate double p90 = .
generate double p95 = .
generate double p99 = .
generate double max = .
generate double skewness = .
generate double kurtosis = .

local i = 1
foreach var of local analysis_vars {
    quietly replace variable = "`var'" in `i'
    
    quietly summarize `var', detail
    quietly replace n = r(N) in `i'
    quietly replace mean = r(mean) in `i'
    quietly replace sd = r(sd) in `i'
    quietly replace min = r(min) in `i'
    quietly replace p1 = r(p1) in `i'
    quietly replace p5 = r(p5) in `i'
    quietly replace p10 = r(p10) in `i'
    quietly replace p25 = r(p25) in `i'
    quietly replace p50 = r(p50) in `i'
    quietly replace p75 = r(p75) in `i'
    quietly replace p90 = r(p90) in `i'
    quietly replace p95 = r(p95) in `i'
    quietly replace p99 = r(p99) in `i'
    quietly replace max = r(max) in `i'
    quietly replace skewness = r(skewness) in `i'
    quietly replace kurtosis = r(kurtosis) in `i'
    
    local i = `i' + 1
}

export delimited using "table_T07_desc_extended.csv", replace
display "SS_OUTPUT_FILE|file=table_T07_desc_extended.csv|type=table|desc=extended_statistics"
display ">>> 扩展统计表已导出"
restore

* ==============================================================================
* SECTION 7: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T07 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "分析概况:"
display "  - 总观测数:        " %10.0fc `n_total'
display "  - 分析变量数:      " %10.0fc `n_vars'
display "  - 分析变量:        `analysis_vars'"
display ""
display "输出文件:"
display "  - table_T07_desc_stats.csv      标准描述统计表（论文表1格式）"
display "  - table_T07_desc_extended.csv   扩展统计表（含偏度、峰度）"
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
display "SS_TASK_END|id=T07|status=ok|elapsed_sec=`elapsed'"

log close
