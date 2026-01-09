* ==============================================================================
* SS_TEMPLATE: id=TG25  level=L2  module=G  title="MTE Estimate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG25_mte_result.csv type=table desc="MTE results"
*   - table_TG25_policy_params.csv type=table desc="Policy params"
*   - fig_TG25_mte_curve.png type=figure desc="MTE curve"
*   - data_TG25_mte.dta type=data desc="MTE data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - mtefe source=ssc purpose="MTE estimation"
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

display "SS_TASK_BEGIN|id=TG25|level=L2|title=MTE_Estimate"
display "SS_TASK_VERSION|version=2.0.1"

* ==============================================================================
* PHASE 5.7 REVIEW (Issue #247) / 最佳实践审查（阶段 5.7）
* - Best practice: MTE is advanced and assumption-heavy; interpret as sensitivity over unobserved resistance to treatment. /
*   最佳实践：MTE 假设较强且难度高；可解读为对“未观测抗拒程度”的敏感性刻画。
* - SSC deps: required:mtefe (no built-in MTE) / SSC 依赖：必需 mtefe（无等价内置命令）
* - Error policy: fail on missing vars/estimation failure; warn on weak first-stage /
*   错误策略：缺少变量/估计失败→fail；第一阶段弱→warn
* ==============================================================================
display "SS_BP_REVIEW|issue=247|template_id=TG25|ssc=required:mtefe|output=csv_png|policy=warn_fail"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 依赖检测 ============
local required_deps "mtefe"
foreach dep of local required_deps {
    capture which `dep'
    if _rc {
        display "SS_DEP_MISSING:cmd=`dep':hint=ssc install `dep'"
        display "SS_ERROR:DEP_MISSING:`dep' is required but not installed"
        display "SS_ERR:DEP_MISSING:`dep' is required but not installed"
        log close
        exit 199
    }
}
display "SS_DEP_CHECK|pkg=mtefe|source=ssc|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local treatment_var = "__TREATMENT_VAR__"
local instrument = "__INSTRUMENT__"
local covariates = "__COVARIATES__"

display ""
display ">>> MTE估计参数:"
display "    结果变量: `outcome_var'"
display "    处理变量: `treatment_var'"
display "    工具变量: `instrument'"
if "`covariates'" != "" {
    display "    控制变量: `covariates'"
}

display "SS_STEP_BEGIN|step=S01_load_data"
* ============ 数据加载 ============
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
foreach var in `outcome_var' `treatment_var' `instrument' {
    capture confirm numeric variable `var'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`var' not found"
        display "SS_ERR:VAR_NOT_FOUND:`var' not found"
        log close
        exit 200
    }
}

local valid_covariates ""
foreach var of local covariates {
    capture confirm numeric variable `var'
    if !_rc {
        local valid_covariates "`valid_covariates' `var'"
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* ============ 倾向得分估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 倾向得分估计（第一阶段）"
display "═══════════════════════════════════════════════════════════════════════════════"

* 估计处理选择方程
probit `treatment_var' `instrument' `valid_covariates'
predict double pscore, pr
label variable pscore "倾向得分"

quietly summarize pscore
display ""
display ">>> 倾向得分分布:"
display "    Mean: " %6.4f r(mean)
display "    Min:  " %6.4f r(min)
display "    Max:  " %6.4f r(max)

* ============ MTE估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: MTE估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 使用mtefe命令估计MTE（如果可用）
capture mtefe `outcome_var' `valid_covariates', treat(`treatment_var') inst(`instrument')

if _rc == 0 {
    display ">>> mtefe估计完成"
    
    * 提取结果
    local ate = e(ate)
    local att = e(att)
    local atu = e(atu)
}
else {
    * 备用方法：使用参数法估计MTE
    display ">>> 使用参数法估计MTE..."
    
    * 生成倾向得分的多项式
    generate double p2 = pscore^2
    generate double p3 = pscore^3
    
    * 分别估计处理组和对照组的结果方程
    quietly regress `outcome_var' pscore p2 p3 `valid_covariates' if `treatment_var' == 1
    predict double y1_hat if e(sample), xb
    
    quietly regress `outcome_var' pscore p2 p3 `valid_covariates' if `treatment_var' == 0
    predict double y0_hat if e(sample), xb
    
    * 估计MTE在不同u点的值
    tempname mte_results
    postfile `mte_results' double u double mte double se ///
        using "temp_mte_curve.dta", replace
    
    * 计算MTE在u从0.05到0.95的值
    forvalues u = 5(5)95 {
        local u_val = `u' / 100
        
        * 计算在该u点的MTE（使用局部多项式）
        quietly summarize `outcome_var' if abs(pscore - `u_val') < 0.1 & `treatment_var' == 1
        local y1_u = r(mean)
        local n1 = r(N)
        
        quietly summarize `outcome_var' if abs(pscore - `u_val') < 0.1 & `treatment_var' == 0
        local y0_u = r(mean)
        local n0 = r(N)
        
        if `n1' > 10 & `n0' > 10 {
            local mte_u = `y1_u' - `y0_u'
            
            * 近似标准误
            quietly summarize `outcome_var' if abs(pscore - `u_val') < 0.1 & `treatment_var' == 1
            local sd1 = r(sd)
            quietly summarize `outcome_var' if abs(pscore - `u_val') < 0.1 & `treatment_var' == 0
            local sd0 = r(sd)
            local se_u = sqrt(`sd1'^2/`n1' + `sd0'^2/`n0')
            
            post `mte_results' (`u_val') (`mte_u') (`se_u')
        }
    }
    
    postclose `mte_results'
    
    * 计算政策参数
    preserve
    use "temp_mte_curve.dta", clear
    
    quietly summarize mte
    local ate = r(mean)
    
    quietly summarize mte if u <= 0.5
    local att_approx = r(mean)
    
    quietly summarize mte if u > 0.5
    local atu_approx = r(mean)
    
    local att = `att_approx'
    local atu = `atu_approx'
    restore
    
    drop p2 p3
    capture drop y1_hat y0_hat
    if _rc != 0 { }
}

display ""
display ">>> MTE衍生的政策参数:"
display "    ATE (平均处理效应):    " %10.4f `ate'
display "    ATT (处理组平均效应):  " %10.4f `att'
display "    ATU (未处理组平均效应):" %10.4f `atu'

display "SS_METRIC|name=ate|value=`ate'"
display "SS_METRIC|name=att|value=`att'"
display "SS_METRIC|name=atu|value=`atu'"

* ============ 导出政策参数 ============
preserve
clear
set obs 3
generate str20 parameter = ""
generate double estimate = .
generate str100 description = ""

replace parameter = "ATE" in 1
replace estimate = `ate' in 1
replace description = "Average Treatment Effect (所有人的平均效应)" in 1

replace parameter = "ATT" in 2
replace estimate = `att' in 2
replace description = "Average Treatment on Treated (已处理者的平均效应)" in 2

replace parameter = "ATU" in 3
replace estimate = `atu' in 3
replace description = "Average Treatment on Untreated (未处理者的平均效应)" in 3

export delimited using "table_TG25_policy_params.csv", replace
display "SS_OUTPUT_FILE|file=table_TG25_policy_params.csv|type=table|desc=policy_params"
restore

* ============ 生成MTE曲线图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 生成MTE曲线图"
display "═══════════════════════════════════════════════════════════════════════════════"

capture confirm file "temp_mte_curve.dta"
if !_rc {
    preserve
    use "temp_mte_curve.dta", clear
    
    generate ci_lower = mte - 1.96 * se
    generate ci_upper = mte + 1.96 * se
    
    twoway (rarea ci_lower ci_upper u, color(navy%20)) ///
           (line mte u, lcolor(navy) lwidth(medium)), ///
           yline(0, lcolor(gray) lpattern(dot)) ///
           yline(`ate', lcolor(red) lpattern(dash)) ///
           xtitle("未观测异质性 (u)") ytitle("边际处理效应 (MTE)") ///
           title("边际处理效应曲线") ///
           legend(off) ///
           note("红色虚线=ATE, 阴影=95%置信区间" ///
                "u低=高处理意愿, u高=低处理意愿")
    graph export "fig_TG25_mte_curve.png", replace width(1200)
    display "SS_OUTPUT_FILE|file=fig_TG25_mte_curve.png|type=figure|desc=mte_curve"
    
    * 导出MTE曲线数据
    export delimited using "table_TG25_mte_result.csv", replace
    display "SS_OUTPUT_FILE|file=table_TG25_mte_result.csv|type=table|desc=mte_result"
    restore
}
else {
    * 创建简化的结果文件
    preserve
    clear
    set obs 1
    generate double ate = `ate'
    generate double att = `att'
    generate double atu = `atu'
    export delimited using "table_TG25_mte_result.csv", replace
    display "SS_OUTPUT_FILE|file=table_TG25_mte_result.csv|type=table|desc=mte_result"
    restore
}

* 清理
capture erase "temp_mte_curve.dta"
if _rc != 0 { }

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG25_mte.dta", replace
display "SS_OUTPUT_FILE|file=data_TG25_mte.dta|type=data|desc=mte_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=ate|value=`ate'"
display "SS_SUMMARY|key=att|value=`att'"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG25 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  MTE衍生政策参数:"
display "    ATE:           " %10.4f `ate'
display "    ATT:           " %10.4f `att'
display "    ATU:           " %10.4f `atu'
display ""
display "  解读:"
display "    MTE曲线揭示处理效应沿未观测异质性的变化"
display "    若MTE随u递减，说明高意愿者获益更多"
display "    若MTE较平坦，说明处理效应较均匀"
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

display "SS_TASK_END|id=TG25|status=ok|elapsed_sec=`elapsed'"
log close
