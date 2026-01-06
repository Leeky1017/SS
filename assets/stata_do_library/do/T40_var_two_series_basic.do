* ==============================================================================
* SS_TEMPLATE: id=T40  level=L0  module=G  title="Vector Autoregression"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_T40_granger.csv type=table desc="Granger causality test"
*   - fig_T40_stability.png type=graph desc="VAR stability"
*   - fig_T40_irf.png type=graph desc="Impulse response functions"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="VAR commands"
* ==============================================================================
* Task ID:      T40_var_two_series_basic
* Task Name:    双变量VAR模型
* Family:       G - 时间序列分析
* Description:  估计双变量VAR模型
* 
* Placeholders: __TIME_VAR__  - 时间变量
*               __VAR1__      - 第一个时间序列变量
*               __VAR2__      - 第二个时间序列变量
*               __LAGS__      - 滞后阶数
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
display "SS_TASK_BEGIN|id=T40|level=L0|title=Vector_Autoregression"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"


display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║  TASK_ID: T40_var_two_series_basic                                        ║"
display "║  TASK_NAME: 双变量VAR模型（Vector Autoregression）                          ║"
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
* SECTION 1: 变量设置与时间序列声明
* ==============================================================================
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 变量设置与VAR参数"
display "═══════════════════════════════════════════════════════════════════════════════"

local time_var "__TIME_VAR__"
local var1 "__VAR1__"
local var2 "__VAR2__"
local lags = __LAGS__

display ""
display ">>> 时间变量:        `time_var'"
display ">>> 变量1:           `var1'"
display ">>> 变量2:           `var2'"
display ">>> VAR滞后阶数:     `lags'"
display "-------------------------------------------------------------------------------"

tsset `time_var'

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 2: 变量描述统计
* ==============================================================================
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 变量描述统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
summarize `var1' `var2'

display ""
display ">>> 相关系数："
correlate `var1' `var2'

* ==============================================================================
* SECTION 3: 滞后阶数选择
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: VAR滞后阶数选择"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 信息准则比较（选择AIC/BIC最小的阶数）："
varsoc `var1' `var2', maxlag(8)

* ==============================================================================
* SECTION 4: VAR模型估计
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: VAR(`lags') 模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> VAR模型设定："
display "    Y_t = A_1·Y_{t-1} + ... + A_p·Y_{t-p} + ε_t"
display "    其中 Y_t = [`var1', `var2']'"
display "-------------------------------------------------------------------------------"

var `var1' `var2', lags(1/`lags')

local ll = e(ll)
local aic = e(aic)

* ==============================================================================
* SECTION 5: 模型诊断
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 模型诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

* 残差自相关检验
display ""
display ">>> 残差自相关检验（LM检验）："
display "    H0: 残差无自相关"
display "-------------------------------------------------------------------------------"
varlmar, mlag(4)

* 残差正态性检验
display ""
display ">>> 残差正态性检验："
varnorm

* 稳定性检验
display ""
display ">>> VAR稳定性检验（特征根）："
display "    所有特征根应在单位圆内"
display "-------------------------------------------------------------------------------"
varstable, graph

graph export "fig_T40_stability.png", replace width(800) height(600)
display "SS_OUTPUT_FILE|file=fig_T40_stability.png|type=graph|desc=var_stability"
display ">>> 稳定性图已导出: fig_T40_stability.png"

* ==============================================================================
* SECTION 6: Granger因果检验
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 6: Granger因果检验"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> Granger因果检验："
display "    H0: X不Granger因果Y（X的滞后项联合不显著）"
display "-------------------------------------------------------------------------------"

vargranger

* 导出 Granger 因果检验结果
display ""
display ">>> 导出Granger因果检验结果: table_T40_granger.csv"

* 获取 vargranger 结果矩阵
matrix granger_results = r(gstats)
local rows = rowsof(granger_results)

preserve
clear
set obs `rows'
generate str50 equation = ""
generate str50 excluded = ""
generate double chi2 = .
generate double df = .
generate double p_value = .

local rownames : rownames granger_results
local i = 1
foreach rn of local rownames {
    replace equation = word("`rn'", 1) in `i'
    replace excluded = word("`rn'", 2) in `i'
    replace chi2 = granger_results[`i', 1] in `i'
    replace df = granger_results[`i', 2] in `i'
    replace p_value = granger_results[`i', 3] in `i'
    local i = `i' + 1
}

export delimited using "table_T40_granger.csv", replace
display "SS_OUTPUT_FILE|file=table_T40_granger.csv|type=table|desc=granger_causality"
display ">>> Granger因果检验结果已导出"
restore

* ==============================================================================
* SECTION 7: 脉冲响应函数（IRF）
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 7: 脉冲响应函数（IRF）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 计算正交化脉冲响应函数（20期）"

irf create var_irf, set(irf_results) replace step(20)

* 绘制所有IRF组合图
irf graph oirf, ///
    title("正交化脉冲响应函数", size(medium)) ///
    note("实线为点估计，阴影为95%置信区间", size(small))

graph export "fig_T40_irf.png", replace width(1200) height(800)
display "SS_OUTPUT_FILE|file=fig_T40_irf.png|type=graph|desc=impulse_response"
display ">>> IRF图已导出: fig_T40_irf.png"

* ==============================================================================
* SECTION 8: 方差分解
* ==============================================================================
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 8: 预测误差方差分解（FEVD）"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 方差分解表（各变量对预测误差的贡献）："
irf table fevd, impulse(`var1' `var2') response(`var1' `var2')

display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ==============================================================================
* SECTION 9: 任务完成摘要
* ==============================================================================
display ""
display "╔══════════════════════════════════════════════════════════════════════════════╗"
display "║                            T40 任务完成摘要                                  ║"
display "╚══════════════════════════════════════════════════════════════════════════════╝"
display ""
display "VAR模型设定:"
display "  - 变量1:           `var1'"
display "  - 变量2:           `var2'"
display "  - 滞后阶数:        `lags'"
display "  - 样本量:          " %10.0fc `n_total'
display ""
display "模型拟合:"
display "  - 对数似然:        " %10.4f `ll'
display "  - AIC:             " %10.4f `aic'
display ""
display "输出文件:"
display "  - table_T40_granger.csv   Granger因果检验结果"
display "  - fig_T40_stability.png   VAR稳定性图"
display "  - fig_T40_irf.png         脉冲响应函数图"
display ""
display "任务完成时间: $S_DATE $S_TIME"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_obs|value=`n_total'"
display "SS_SUMMARY|key=lags|value=`lags'"
display "SS_SUMMARY|key=aic|value=`aic'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_total'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END|id=T40|status=ok|elapsed_sec=`elapsed'"

log close
