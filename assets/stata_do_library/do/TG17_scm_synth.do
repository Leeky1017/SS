* ==============================================================================
* SS_TEMPLATE: id=TG17  level=L2  module=G  title="SCM Synth"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG17_synth_path.csv type=table desc="Synth path"
*   - fig_TG17_synth_path.png type=graph desc="Synth path plot"
*   - data_TG17_synth.dta type=data desc="Synth data"
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

display "SS_TASK_BEGIN|id=TG17|level=L2|title=SCM_Synth"
display "SS_TASK_VERSION|version=2.0.1"

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
local predictors = "__PREDICTORS__"

display ""
display ">>> 合成控制法参数:"
display "    结果变量: `outcome_var'"
display "    处理单位: `treated_unit'"
display "    处理时间: `treatment_time'"
display "    ID变量: `id_var'"
display "    时间变量: `time_var'"
display "    预测变量: `predictors'"

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
tempfile original_data
save `original_data', replace
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
foreach var in `outcome_var' `id_var' `time_var' {
    capture confirm variable `var'
    if _rc {
display "SS_RC|code=200|cmd=confirm_variable|msg=var_not_found|detail=`var'_not_found|var=`var'|severity=fail"
        log close
        exit 200
    }
}

local valid_predictors ""
foreach var of local predictors {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_predictors "`valid_predictors' `var'"
    }
}

* ============ 数据准备 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 数据准备"
display "═══════════════════════════════════════════════════════════════════════════════"

* 检查处理单位是否存在
quietly levelsof `id_var', local(units)
local found_treated = 0
foreach u of local units {
    if `u' == `treated_unit' {
        local found_treated = 1
    }
}

if !`found_treated' {
display "SS_RC|code=198|cmd=task|msg=treated_not_found|detail=Treated_unit_`treated_unit'_not_found|severity=fail"
    log close
    exit 198
}

* 获取时间范围
quietly summarize `time_var'
local t_min = r(min)
local t_max = r(max)

* 对照单位列表
local control_units ""
foreach u of local units {
    if `u' != `treated_unit' {
        local control_units "`control_units' `u'"
    }
}
local n_control : word count `control_units'

display ""
display ">>> 数据结构:"
display "    处理单位: `treated_unit'"
display "    对照单位数: `n_control'"
display "    时间范围: `t_min' - `t_max'"
display "    处理时间: `treatment_time'"

* 设置tsset
tsset `id_var' `time_var'
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 执行合成控制 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 执行合成控制法"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建预测变量规范
local pretreat_period = `treatment_time' - 1
local trperiod_spec "trperiod(`treatment_time')"
local trunit_spec "trunit(`treated_unit')"

* 构建预测变量
local pred_spec ""
if "`valid_predictors'" != "" {
    foreach var of local valid_predictors {
        local pred_spec "`pred_spec' `var'"
    }
}

* 添加结果变量的预处理期作为预测变量
local pred_spec "`pred_spec' `outcome_var'(`t_min'(1)`pretreat_period')"

display ">>> 执行synth命令..."

synth `outcome_var' `pred_spec', ///
    `trunit_spec' `trperiod_spec' ///
    counit(`control_units') ///
    resultsperiod(`t_min'(1)`t_max') ///
    mspeperiod(`t_min'(1)`pretreat_period') ///
    keep(synth_results) replace

* ============ 提取结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 提取合成控制结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 加载合成结果
use synth_results, clear

* 计算处理效应
generate double effect = _Y_treated - _Y_synthetic

* 处理后平均效应
quietly summarize effect if _time >= `treatment_time'
local avg_effect = r(mean)
local se_effect = r(sd) / sqrt(r(N))

display ""
display ">>> 合成控制估计结果:"
display "    处理后平均效应: " %10.4f `avg_effect'
display "    标准误(近似): " %10.4f `se_effect'

display "SS_METRIC|name=avg_effect|value=`avg_effect'"

* 处理前MSPE
quietly summarize effect if _time < `treatment_time'
local pre_mspe = r(sd)^2 * (r(N)-1) / r(N)
display "    处理前MSPE: " %10.4f `pre_mspe'

display "SS_METRIC|name=pre_mspe|value=`pre_mspe'"

* ============ 生成路径图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成图表"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway (line _Y_treated _time, lcolor(black) lwidth(medium)) ///
       (line _Y_synthetic _time, lcolor(gray) lpattern(dash) lwidth(medium)), ///
       xline(`treatment_time', lcolor(red) lpattern(dash)) ///
       legend(order(1 "实际值" 2 "合成对照") position(6)) ///
       xtitle("时间") ytitle("`outcome_var'") ///
       title("合成控制法: 实际 vs 合成对照") ///
       note("红色虚线=处理时间")
graph export "fig_TG17_synth_path.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TG17_synth_path.png|type=graph|desc=synth_path"

* 导出结果数据
export delimited using "table_TG17_synth_path.csv", replace
display "SS_OUTPUT_FILE|file=table_TG17_synth_path.csv|type=table|desc=synth_path_data"

* ============ 恢复原始数据并保存 ============
use `original_data', clear

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG17_synth.dta", replace
display "SS_OUTPUT_FILE|file=data_TG17_synth.dta|type=data|desc=synth_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=avg_effect|value=`avg_effect'"

* 清理
capture erase "synth_results.dta"
if _rc != 0 {
    * Expected non-fatal return code
}

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG17 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  处理单位:        `treated_unit'"
display "  处理时间:        `treatment_time'"
display "  对照单位数:      " %10.0fc `n_control'
display ""
display "  合成控制估计:"
display "    平均效应:      " %10.4f `avg_effect'
display "    处理前MSPE:    " %10.4f `pre_mspe'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TG17|status=ok|elapsed_sec=`elapsed'"
log close
