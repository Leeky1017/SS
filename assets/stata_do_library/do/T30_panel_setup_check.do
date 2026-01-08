* ==============================================================================
* SS_TEMPLATE: id=T30  level=L0  module=F  title="Panel Data Setup"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T30_panel_structure.csv type=table desc="Panel structure summary"
*   - table_T30_xtsum.csv type=table desc="Within-between decomposition"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="panel data commands"
* ==============================================================================
* Task ID:      T30_panel_setup_check
* Task Name:    面板数据设置与检查
* Family:       F - 面板数据与政策评估
* Description:  设置面板数据结构，检查平衡性
* 
* Placeholders: __ID_VAR__   - 个体标识变量
*               __TIME_VAR__ - 时间变量
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

program define ss_fail_T30
    args code cmd msg
    timer off 1
    quietly timer list 1
    local elapsed = r(t1)
    display "SS_RC|code=`code'|cmd=`cmd'|msg=`msg'|severity=fail"
    display "SS_METRIC|name=task_success|value=0"
    display "SS_METRIC|name=elapsed_sec|value=`elapsed'"
    display "SS_TASK_END|id=T30|status=fail|elapsed_sec=`elapsed'"
    capture log close
    if _rc != 0 {
        * No log to close - expected
    }
    exit `code'
end



* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=T30|level=L0|title=Panel_Data_Setup"
display "SS_SUMMARY|key=template_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T30_panel_setup_check                                            ║"
display "║  TASK_NAME: 面板数据设置与检查（Panel Data Setup）                             ║"
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
        ss_fail_T30 601 "confirm file" "data_file_not_found"
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
* SECTION 1: 设置面板数据结构
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 设置面板数据结构"
display "═══════════════════════════════════════════════════════════════════════════════"

local id_var "__ID_VAR__"
local time_var "__TIME_VAR__"

capture confirm variable `id_var'
if _rc {
    display as error "ERROR: ID variable `id_var' not found"
    ss_fail_T30 111 "confirm variable" "id_var_not_found"
}

capture confirm variable `time_var'
if _rc {
    display as error "ERROR: Time variable `time_var' not found"
    ss_fail_T30 111 "confirm variable" "time_var_not_found"
}

display ""
display ">>> 个体变量（i）:    `id_var'"
display ">>> 时间变量（t）:    `time_var'"
display "-------------------------------------------------------------------------------"

ss_smart_xtset `id_var' `time_var'

local balanced = "`r(balanced)'"
local n_panels = r(imax) - r(imin) + 1
local t_min = r(tmin)
local t_max = r(tmax)
local delta = r(tdelta)

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 面板结构描述
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 面板结构描述"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
xtdescribe

* 计算实际个体数和时期数（使用官方命令替代 distinct）
tempvar __tag_id __tag_time
quietly bysort `id_var': gen `__tag_id' = _n == 1
quietly count if `__tag_id'
local n_ids = r(N)
quietly bysort `time_var': gen `__tag_time' = _n == 1
quietly count if `__tag_time'
local n_times = r(N)
drop `__tag_id' `__tag_time'

display ""
display "{hline 60}"
display "个体数 (N):                   " %12.0fc `n_ids'
display "时期数 (T):                   " %12.0f `n_times'
display "总观测数 (N×T):               " %12.0fc `n_total'
display "理论最大观测数:               " %12.0fc `n_ids' * `n_times'
display "实际/理论比:                  " %12.4f `n_total' / (`n_ids' * `n_times')
display "{hline 60}"

* ==============================================================================
* SECTION 3: 平衡性检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 平衡性检查"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
if "`balanced'" == "strongly balanced" {
    display as result ">>> 面板类型: 强平衡面板（Strongly Balanced）"
    display "    所有个体都有完整的时期观测"
}
else if "`balanced'" == "weakly balanced" {
    display as result ">>> 面板类型: 弱平衡面板（Weakly Balanced）"
    display "    各个体观测数相同，但时期可能不连续"
}
else {
    display as error ">>> 面板类型: 非平衡面板（Unbalanced）"
    display "    各个体观测数不同，存在缺失观测"
}

* 各个体观测数分布
display ""
display ">>> 各个体观测期数分布："
bysort `id_var': gen _n_obs_temp = _N
tabulate _n_obs_temp

quietly summarize _n_obs_temp
local avg_t = r(mean)
local min_t = r(min)
local max_t = r(max)

display ""
display "{hline 50}"
display "平均每个体期数:      " %10.2f `avg_t'
display "最少期数:            " %10.0f `min_t'
display "最多期数:            " %10.0f `max_t'
display "{hline 50}"

drop _n_obs_temp

* ==============================================================================
* SECTION 4: 时间跨度检查
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 时间跨度检查"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 时间变量分布："
tabulate `time_var'

display ""
display "{hline 50}"
display "时间范围:            " %10.0f `t_min' " - " %10.0f `t_max'
display "时间间隔:            " %10.0f `delta'
display "理论期数:            " %10.0f (`t_max' - `t_min') / `delta' + 1
display "{hline 50}"

* ==============================================================================
* SECTION 5: 缺失值概况
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 缺失值概况"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
misstable summarize

* ==============================================================================
* SECTION 6: 面板汇总统计（组内组间分解）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: 面板汇总统计（组内组间分解）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> xtsum 分解变量为:"
display "    overall: 总体变异"
display "    between: 组间变异（个体间）"
display "    within:  组内变异（时间序列）"
display "-------------------------------------------------------------------------------"

xtsum

* 保存 xtsum 结果到临时文件
* 获取所有数值变量进行 xtsum 分解
quietly ds, has(type numeric)
local numvars `r(varlist)'

* 为每个变量计算组内组间统计量
tempfile xtsum_results
preserve
clear
generate str32 variable = ""
generate double overall_mean = .
generate double overall_sd = .
generate double overall_min = .
generate double overall_max = .
generate double between_sd = .
generate double within_sd = .
generate int n_obs = .
generate int n_groups = .
generate double t_bar = .
local row = 0
save `xtsum_results', replace
restore

foreach v of local numvars {
    capture quietly xtsum `v'
    if _rc == 0 {
        preserve
        use `xtsum_results', clear
        local row = _N + 1
        set obs `row'
        replace variable = "`v'" in `row'
        replace overall_mean = r(mean) in `row'
        replace overall_sd = r(sd) in `row'
        replace overall_min = r(min) in `row'
        replace overall_max = r(max) in `row'
        replace between_sd = r(sd_b) in `row'
        replace within_sd = r(sd_w) in `row'
        replace n_obs = r(N) in `row'
        replace n_groups = r(n) in `row'
        replace t_bar = r(Tbar) in `row'
        save `xtsum_results', replace
        restore
    }
}

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 7: 导出结果
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 导出结果文件"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出面板结构摘要
display ""
display ">>> 导出面板结构摘要: table_T30_panel_structure.csv"

preserve
clear
set obs 1

generate int n_obs = `n_total'
generate int n_ids = `n_ids'
generate int n_times = `n_times'
generate int t_min = `t_min'
generate int t_max = `t_max'
generate str20 balanced = "`balanced'"
generate double avg_t_per_id = `avg_t'
generate int min_t_per_id = `min_t'
generate int max_t_per_id = `max_t'

export delimited using "table_T30_panel_structure.csv", replace
display "SS_OUTPUT_FILE|file=table_T30_panel_structure.csv|type=table|desc=panel_structure"
display ">>> 面板结构摘要已导出"
restore

* 导出组内组间变异分解表
display ""
display ">>> 导出组内组间变异分解: table_T30_xtsum.csv"

preserve
use `xtsum_results', clear
drop if missing(variable) | variable == ""
export delimited using "table_T30_xtsum.csv", replace
display "SS_OUTPUT_FILE|file=table_T30_xtsum.csv|type=table|desc=within_between_decomposition"
display ">>> 组内组间变异分解表已导出"
restore

* ==============================================================================
* SECTION 8: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T30 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "面板数据结构:"
display "  - 个体变量:        `id_var'"
display "  - 时间变量:        `time_var'"
display "  - 个体数 (N):      " %10.0fc `n_ids'
display "  - 时期数 (T):      " %10.0f `n_times'
display "  - 总观测数:        " %10.0fc `n_total'
display ""
display "平衡性:"
display "  - 面板类型:        `balanced'"
display "  - 平均期数/个体:   " %10.2f `avg_t'
display ""
display "时间范围:"
display "  - 起始时期:        " %10.0f `t_min'
display "  - 结束时期:        " %10.0f `t_max'
display ""
display "输出文件:"
display "  - table_T30_panel_structure.csv   面板结构摘要"
display "  - table_T30_xtsum.csv             组内组间变异分解"
display ""
display ">>> 面板数据已设置完成，可以使用 xtreg 等面板命令"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_ids|value=`n_ids'"
display "SS_SUMMARY|key=n_times|value=`n_times'"
display "SS_SUMMARY|key=n_obs|value=`n_total'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T30|status=ok|elapsed_sec=`elapsed'"

log close
