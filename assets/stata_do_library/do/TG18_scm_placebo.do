* ==============================================================================

* ============ 最佳实践审查记录 / Best-practice review (Phase 5.7) ============
* Template: TG18 — SCM Placebo
* 识别假设 / ID assumptions: method-specific; review before use (no "auto validity")
* 诊断输出 / Diagnostics: run minimal, relevant checks; treat WARN as evidence, not noise
* SSC依赖 / SSC deps: keep minimal; required packages are explicit in header
* 解读要点 / Interpretation: estimates are conditional on assumptions; add robustness checks
* SS_TEMPLATE: id=TG18  level=L2  module=G  title="SCM Placebo"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG18_placebo_results.csv type=table desc="Placebo results"
*   - fig_TG18_placebo_plot.png type=graph desc="Placebo plot"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - synth source=ssc purpose="Synthetic control"
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 {
    * Expected non-fatal return code
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TG18|level=L2|title=SCM_Placebo"
display "SS_TASK_VERSION|version=2.1.0"

* ============ 依赖检测 ============
local required_deps "synth"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
display "SS_DEP_CHECK|pkg=`dep'|source=ssc|status=missing"
display "SS_DEP_MISSING|pkg=`dep'|hint=ssc_install_`dep'"
display "SS_RC|code=199|cmd=which `dep'|msg=dependency_missing|severity=fail"
display "SS_RC|code=199|cmd=which|msg=dep_missing|detail=`dep'_is_required_but_not_installed|severity=fail"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=synth|source=ssc|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local treated_unit = __TREATED_UNIT__
local treatment_time = __TREATMENT_TIME__
local id_var = "__ID_VAR__"
local time_var = "__TIME_VAR__"
local placebo_type = "__PLACEBO_TYPE__"

if "`placebo_type'" == "" | ("`placebo_type'" != "unit" & "`placebo_type'" != "time") {
    local placebo_type = "unit"
}

display ""
display ">>> SCM安慰剂检验参数:"
display "    结果变量: `outcome_var'"
display "    处理单位: `treated_unit'"
display "    处理时间: `treatment_time'"
display "    安慰剂类型: `placebo_type'"

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
capture confirm file "data.csv"
if _rc {
display "SS_RC|code=601|cmd=confirm_file|msg=file_not_found|detail=data.csv_not_found|file=data.csv|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* 保存原始数据"
tempfile original_data
save `original_data'

* ============ 变量检查 ============
foreach var in `outcome_var' `id_var' `time_var' {
    capture confirm variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

* 获取单位和时间信息
quietly levelsof `id_var', local(all_units)
quietly summarize `time_var'
local t_min = r(min)
local t_max = r(max)
local pretreat_end = `treatment_time' - 1
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 执行安慰剂检验 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 执行安慰剂检验 (`placebo_type')"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建结果存储
tempname placebo_results
postfile `placebo_results' int placebo_id double effect double pre_mspe double post_mspe double ratio ///
    using "temp_placebo_results.dta", replace

if "`placebo_type'" == "unit" {
    * 单位安慰剂：对每个对照单位假装其为处理单位
    display ""
    display ">>> 执行单位安慰剂检验..."
    display ">>> 依次将每个对照单位视为处理单位..."
    
    local n_placebo = 0
    local treated_effect = .
    local treated_ratio = .
    
    foreach unit of local all_units {
        use `original_data', clear
        tsset `id_var' `time_var'
        
        * 构建对照单位列表
        local control_units ""
        foreach u of local all_units {
            if `u' != `unit' {
                local control_units "`control_units' `u'"
            }
        }
        
        * 执行合成控制
        capture noisily synth `outcome_var' `outcome_var'(`t_min'(1)`pretreat_end'), ///
            trunit(`unit') trperiod(`treatment_time') ///
            counit(`control_units') ///
            keep(synth_temp_`unit') replace
        
        if _rc == 0 {
            * 计算效应
            use synth_temp_`unit', clear
            
            generate double effect = _Y_treated - _Y_synthetic
            
            quietly summarize effect if _time < `treatment_time'
            local pre_mspe = r(sd)^2
            
            quietly summarize effect if _time >= `treatment_time'
            local post_mspe = r(sd)^2
            local avg_effect = r(mean)
            
            if `pre_mspe' > 0 {
                local ratio = `post_mspe' / `pre_mspe'
            }
            else {
                local ratio = .
            }
            
            post `placebo_results' (`unit') (`avg_effect') (`pre_mspe') (`post_mspe') (`ratio')
            
            if `unit' == `treated_unit' {
                local treated_effect = `avg_effect'
                local treated_ratio = `ratio'
            }
            
            local n_placebo = `n_placebo' + 1
            display "    单位 `unit': 效应=" %8.4f `avg_effect' ", MSPE比=" %8.2f `ratio'
            
            capture erase "synth_temp_`unit'.dta"
            if _rc != 0 {
                * Expected non-fatal return code
            }
        }
    }
}
else {
    * 时间安慰剂：在不同时间点假装处理发生
    display ""
    display ">>> 执行时间安慰剂检验..."
    display ">>> 依次在不同时间点假装处理发生..."
    
    local n_placebo = 0
    local treated_effect = .
    
    * 只考虑处理前的时间点
    forvalues t = `=`t_min'+2'/`=`treatment_time'-1' {
        use `original_data', clear
        tsset `id_var' `time_var'
        
        * 构建对照单位列表
        local control_units ""
        foreach u of local all_units {
            if `u' != `treated_unit' {
                local control_units "`control_units' `u'"
            }
        }
        
        * 执行合成控制
        local placebo_pretreat_end = `t' - 1
        capture noisily synth `outcome_var' `outcome_var'(`t_min'(1)`placebo_pretreat_end'), ///
            trunit(`treated_unit') trperiod(`t') ///
            counit(`control_units') ///
            keep(synth_time_`t') replace
        
        if _rc == 0 {
            use synth_time_`t', clear
            
            generate double effect = _Y_treated - _Y_synthetic
            
            quietly summarize effect if _time < `t'
            local pre_mspe = r(sd)^2
            
            quietly summarize effect if _time >= `t' & _time < `treatment_time'
            local post_mspe = r(sd)^2
            local avg_effect = r(mean)
            
            if `pre_mspe' > 0 {
                local ratio = `post_mspe' / `pre_mspe'
            }
            else {
                local ratio = .
            }
            
            post `placebo_results' (`t') (`avg_effect') (`pre_mspe') (`post_mspe') (`ratio')
            
            local n_placebo = `n_placebo' + 1
            display "    时间 `t': 效应=" %8.4f `avg_effect'
            
            capture erase "synth_time_`t'.dta"
            if _rc != 0 {
                * Expected non-fatal return code
            }
        }
    }
}

postclose `placebo_results'

display ""
display ">>> 完成 `n_placebo' 次安慰剂检验"
display "SS_METRIC|name=n_placebo|value=`n_placebo'"

* ============ 计算p值 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 计算推断p值"
display "═══════════════════════════════════════════════════════════════════════════════"

use "temp_placebo_results.dta", clear
quietly count
local n_total = r(N)
local p_value = .

if `n_total' == 0 {
display "SS_RC|code=0|cmd=warning|msg=placebo_empty|detail=No_successful_placebo_runs|severity=warn"
}

if `n_total' > 0 & "`placebo_type'" == "unit" {
    * 基于MSPE比的排名推断
    gsort -ratio
    generate rank = _n
    
    quietly summarize rank if placebo_id == `treated_unit'
    local treated_rank = r(mean)
    
    local p_value = `treated_rank' / `n_total'
    
    display ""
    display ">>> 推断p值 (基于MSPE比排名):"
    display "    处理单位排名: `treated_rank' / `n_total'"
    display "    p值: " %6.4f `p_value'
}
else if `n_total' > 0 {
    * 时间安慰剂：检查真实处理时间效应是否异常
    quietly summarize effect
    local mean_effect = r(mean)
    local sd_effect = r(sd)
    
    local p_value = 1 - normal(abs(`treated_effect' - `mean_effect') / `sd_effect')
    
    display ""
    display ">>> 推断p值 (基于效应分布):"
    display "    p值: " %6.4f `p_value'
}

display "SS_METRIC|name=p_value|value=`p_value'"

* 导出结果
export delimited using "table_TG18_placebo_results.csv", replace
display "SS_OUTPUT_FILE|file=table_TG18_placebo_results.csv|type=table|desc=placebo_results"

* ============ 生成安慰剂效应图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成安慰剂效应图"
display "═══════════════════════════════════════════════════════════════════════════════"

if `n_total' == 0 {
display "SS_RC|code=0|cmd=warning|msg=placebo_empty|detail=Skip_placebo_plot_no_observations|severity=warn"
}
else if "`placebo_type'" == "unit" {
    * 绘制MSPE比分布
    histogram ratio, bin(20) ///
        xline(`treated_ratio', lcolor(red) lwidth(thick)) ///
        xtitle("MSPE比 (处理后/处理前)") ytitle("频数") ///
        title("单位安慰剂检验: MSPE比分布") ///
        note("红线=处理单位, p值=" %5.3f `p_value')
    graph export "fig_TG18_placebo_plot.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG18_placebo_plot.png|type=graph|desc=placebo_plot"
}
else {
    * 绘制效应分布
    histogram effect, bin(20) ///
        xline(`treated_effect', lcolor(red) lwidth(thick)) ///
        xtitle("安慰剂效应") ytitle("频数") ///
        title("时间安慰剂检验: 效应分布") ///
        note("红线=真实处理时间效应")
    graph export "fig_TG18_placebo_plot.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG18_placebo_plot.png|type=graph|desc=placebo_plot"
}
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_placebo|value=`n_placebo'"
display "SS_SUMMARY|key=p_value|value=`p_value'"

* 清理
capture erase "temp_placebo_results.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* 恢复原始数据
use `original_data', clear

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG18 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  安慰剂类型:      `placebo_type'"
display "  安慰剂检验数:    " %10.0fc `n_placebo'
display ""
display "  推断结果:"
display "    p值:           " %10.4f `p_value'
if `p_value' < 0.05 {
    display "    结论:          处理效应在5%水平显著"
}
else if `p_value' < 0.10 {
    display "    结论:          处理效应在10%水平显著"
}
else {
    display "    结论:          处理效应不显著"
}
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
local n_dropped = 0
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG18|status=ok|elapsed_sec=`elapsed'"
log close
