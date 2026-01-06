* ==============================================================================
* SS_TEMPLATE: id=TK13  level=L2  module=K  title="Performance Attr"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK13_attribution.csv type=table desc="Attribution results"
*   - fig_TK13_attribution.png type=figure desc="Attribution chart"
*   - data_TK13_perf.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TK13|level=L2|title=Performance_Attr"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local port_return = "__PORT_RETURN__"
local bench_return = "__BENCH_RETURN__"
local port_weight = "__PORT_WEIGHT__"
local bench_weight = "__BENCH_WEIGHT__"
local sector_var = "__SECTOR_VAR__"

display ""
display ">>> 业绩归因参数:"
display "    组合收益: `port_return'"
display "    基准收益: `bench_return'"
display "    组合权重: `port_weight'"
display "    基准权重: `bench_weight'"
display "    行业变量: `sector_var'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_ERROR:FILE_NOT_FOUND:data.csv not found"
    display "SS_ERR:FILE_NOT_FOUND:data.csv not found"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `port_return' `bench_return' `port_weight' `bench_weight' `sector_var' {
    capture confirm variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ Brinson归因分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: Brinson业绩归因"
display "═══════════════════════════════════════════════════════════════════════════════"

* 按行业计算归因
tempname attribution
postfile `attribution' str30 sector double alloc_effect double select_effect double interact_effect double total ///
    using "temp_attribution.dta", replace

* 计算基准总收益
quietly summarize `bench_return' [aw=`bench_weight']
local bench_total = r(mean)

display ""
display "行业                配置效应    选股效应    交互效应    总效应"
display "───────────────────────────────────────────────────────────────"

quietly levelsof `sector_var', local(sectors)

local total_alloc = 0
local total_select = 0
local total_interact = 0

foreach s of local sectors {
    * 组合权重
    quietly summarize `port_weight' if `sector_var' == "`s'"
    local wp = r(mean) * r(N)
    
    * 基准权重
    quietly summarize `bench_weight' if `sector_var' == "`s'"
    local wb = r(mean) * r(N)
    
    * 组合收益
    quietly summarize `port_return' if `sector_var' == "`s'" [aw=`port_weight']
    local rp = r(mean)
    
    * 基准收益
    quietly summarize `bench_return' if `sector_var' == "`s'" [aw=`bench_weight']
    local rb = r(mean)
    
    * 配置效应: (wp - wb) * (rb - bench_total)
    local alloc = (`wp' - `wb') * (`rb' - `bench_total')
    
    * 选股效应: wb * (rp - rb)
    local select = `wb' * (`rp' - `rb')
    
    * 交互效应: (wp - wb) * (rp - rb)
    local interact = (`wp' - `wb') * (`rp' - `rb')
    
    local total = `alloc' + `select' + `interact'
    
    post `attribution' ("`s'") (`alloc') (`select') (`interact') (`total')
    
    local total_alloc = `total_alloc' + `alloc'
    local total_select = `total_select' + `select'
    local total_interact = `total_interact' + `interact'
    
    display %20s "`s'" "  " %10.4f `alloc' "  " %10.4f `select' "  " %10.4f `interact' "  " %10.4f `total'
}

postclose `attribution'

display "───────────────────────────────────────────────────────────────"
display %20s "合计" "  " %10.4f `total_alloc' "  " %10.4f `total_select' "  " %10.4f `total_interact' "  " %10.4f `=`total_alloc'+`total_select'+`total_interact''

local active_return = `total_alloc' + `total_select' + `total_interact'
display ""
display ">>> 主动收益: " %10.4f `active_return'

display "SS_METRIC|name=alloc_effect|value=`total_alloc'"
display "SS_METRIC|name=select_effect|value=`total_select'"
display "SS_METRIC|name=active_return|value=`active_return'"

* 导出归因结果
preserve
use "temp_attribution.dta", clear
export delimited using "table_TK13_attribution.csv", replace
display "SS_OUTPUT_FILE|file=table_TK13_attribution.csv|type=table|desc=attribution"

* 生成归因图
graph bar alloc_effect select_effect interact_effect, over(sector, label(angle(45))) ///
    legend(order(1 "配置效应" 2 "选股效应" 3 "交互效应") position(6)) ///
    title("Brinson业绩归因") ///
    ytitle("收益贡献")
graph export "fig_TK13_attribution.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK13_attribution.png|type=figure|desc=attribution_chart"
restore

capture erase "temp_attribution.dta"
if _rc != 0 { }

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK13_perf.dta", replace
display "SS_OUTPUT_FILE|file=data_TK13_perf.dta|type=data|desc=perf_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK13 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  归因结果:"
display "    配置效应:      " %10.4f `total_alloc'
display "    选股效应:      " %10.4f `total_select'
display "    交互效应:      " %10.4f `total_interact'
display "    主动收益:      " %10.4f `active_return'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=active_return|value=`active_return'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK13|status=ok|elapsed_sec=`elapsed'"
log close
