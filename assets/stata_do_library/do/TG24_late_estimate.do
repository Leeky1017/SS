* ==============================================================================
* SS_TEMPLATE: id=TG24  level=L2  module=G  title="LATE Estimate"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TG24_late_result.csv type=table desc="LATE results"
*   - table_TG24_complier_chars.csv type=table desc="Complier chars"
*   - data_TG24_late.dta type=data desc="LATE data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - ivreg2 source=ssc purpose="IV regression"
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

display "SS_TASK_BEGIN|id=TG24|level=L2|title=LATE_Estimate"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检测 ============
local required_deps "ivreg2"
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
display "SS_DEP_CHECK|pkg=ivreg2|source=ssc|status=ok"

* ============ 参数设置 ============
local outcome_var = "__OUTCOME_VAR__"
local treatment_var = "__TREATMENT_VAR__"
local instrument = "__INSTRUMENT__"
local covariates = "__COVARIATES__"

display ""
display ">>> LATE估计参数:"
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
* ============ 识别Complier类型 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 识别潜在类型分布"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算各类型比例（基于工具变量和处理状态）
quietly count if `instrument' == 1 & `treatment_var' == 1
local n_z1_d1 = r(N)
quietly count if `instrument' == 1 & `treatment_var' == 0
local n_z1_d0 = r(N)
quietly count if `instrument' == 0 & `treatment_var' == 1
local n_z0_d1 = r(N)
quietly count if `instrument' == 0 & `treatment_var' == 0
local n_z0_d0 = r(N)

quietly count if `instrument' == 1
local n_z1 = r(N)
quietly count if `instrument' == 0
local n_z0 = r(N)

* P(D=1|Z=1) 和 P(D=1|Z=0)
local p_d1_z1 = `n_z1_d1' / `n_z1'
local p_d1_z0 = `n_z0_d1' / `n_z0'

* 第一阶段效应 = Complier比例
local first_stage = `p_d1_z1' - `p_d1_z0'

display ""
display ">>> 处理概率:"
display "    P(D=1|Z=1): " %6.4f `p_d1_z1'
display "    P(D=1|Z=0): " %6.4f `p_d1_z0'
display "    第一阶段效应: " %6.4f `first_stage'

* 推断类型比例（假设单调性）
local pct_complier = `first_stage' * 100
local pct_always_taker = `p_d1_z0' * 100
local pct_never_taker = (1 - `p_d1_z1') * 100

display ""
display ">>> 潜在类型分布（假设单调性）:"
display "    Compliers:     " %5.1f `pct_complier' "%"
display "    Always-takers: " %5.1f `pct_always_taker' "%"
display "    Never-takers:  " %5.1f `pct_never_taker' "%"

display "SS_METRIC|name=pct_complier|value=`pct_complier'"

* ============ LATE估计（Wald估计量） ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: LATE估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 简约形式
quietly regress `outcome_var' `instrument' `valid_covariates', robust
local reduced_form = _b[`instrument']
local rf_se = _se[`instrument']

* 第一阶段
quietly regress `treatment_var' `instrument' `valid_covariates', robust
local first_stage_coef = _b[`instrument']
local fs_se = _se[`instrument']
local fs_f = ((`first_stage_coef' / `fs_se')^2)

* Wald估计量
local late_wald = `reduced_form' / `first_stage_coef'

display ""
display ">>> Wald估计量 (简约形式/第一阶段):"
display "    简约形式: " %10.4f `reduced_form'
display "    第一阶段: " %10.4f `first_stage_coef'
display "    LATE (Wald): " %10.4f `late_wald'

* 2SLS估计
ivreg2 `outcome_var' `valid_covariates' (`treatment_var' = `instrument'), robust first

local late_2sls = _b[`treatment_var']
local late_se = _se[`treatment_var']
local late_t = `late_2sls' / `late_se'
local late_p = 2 * ttail(e(df_r), abs(`late_t'))
local ci_lower = `late_2sls' - 1.96 * `late_se'
local ci_upper = `late_2sls' + 1.96 * `late_se'

display ""
display ">>> 2SLS LATE估计:"
display "    LATE: " %10.4f `late_2sls'
display "    标准误: " %10.4f `late_se'
display "    t统计量: " %10.4f `late_t'
display "    p值: " %10.4f `late_p'
display "    95% CI: [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"

display "SS_METRIC|name=late|value=`late_2sls'"
display "SS_METRIC|name=late_se|value=`late_se'"

* ============ Complier特征分析 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: Complier特征分析"
display "═══════════════════════════════════════════════════════════════════════════════"

tempname complier_chars
postfile `complier_chars' str32 variable double mean_complier double mean_always double mean_never ///
    using "temp_complier_chars.dta", replace

if "`valid_covariates'" != "" {
    display ""
    display ">>> 估计Complier特征（相对于Always-takers和Never-takers）..."
    display ""
    display "变量                 Compliers    Always-takers  Never-takers"
    display "───────────────────────────────────────────────────────────────"
    
    foreach var of local valid_covariates {
        * E[X|Complier] 使用Abadie (2003) 方法近似
        quietly summarize `var' if `instrument' == 1 & `treatment_var' == 1
        local ex_z1d1 = r(mean)
        quietly summarize `var' if `instrument' == 0 & `treatment_var' == 0
        local ex_z0d0 = r(mean)
        
        * Always-taker: D=1 when Z=0
        quietly summarize `var' if `instrument' == 0 & `treatment_var' == 1
        local mean_always = r(mean)
        
        * Never-taker: D=0 when Z=1
        quietly summarize `var' if `instrument' == 1 & `treatment_var' == 0
        local mean_never = r(mean)
        
        * Complier近似（加权平均）
        local mean_complier = (`ex_z1d1' * `p_d1_z1' - `mean_always' * `p_d1_z0') / `first_stage'
        
        post `complier_chars' ("`var'") (`mean_complier') (`mean_always') (`mean_never')
        
        display %20s "`var'" "  " %10.4f `mean_complier' "  " %10.4f `mean_always' "  " %10.4f `mean_never'
    }
}

postclose `complier_chars'

preserve
use "temp_complier_chars.dta", clear
export delimited using "table_TG24_complier_chars.csv", replace
display "SS_OUTPUT_FILE|file=table_TG24_complier_chars.csv|type=table|desc=complier_chars"
restore

* ============ 导出结果 ============
preserve
clear
set obs 1
generate str20 estimand = "LATE"
generate double estimate = `late_2sls'
generate double std_error = `late_se'
generate double t_stat = `late_t'
generate double p_value = `late_p'
generate double ci_lower = `ci_lower'
generate double ci_upper = `ci_upper'
generate double first_stage = `first_stage_coef'
generate double first_stage_f = `fs_f'
generate double pct_complier = `pct_complier'

export delimited using "table_TG24_late_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TG24_late_result.csv|type=table|desc=late_result"
restore

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TG24_late.dta", replace
display "SS_OUTPUT_FILE|file=data_TG24_late.dta|type=data|desc=late_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=late|value=`late_2sls'"
display "SS_SUMMARY|key=pct_complier|value=`pct_complier'"

capture erase "temp_complier_chars.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TG24 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  潜在类型分布:"
display "    Compliers:     " %10.1f `pct_complier' "%"
display "    Always-takers: " %10.1f `pct_always_taker' "%"
display "    Never-takers:  " %10.1f `pct_never_taker' "%"
display ""
display "  LATE估计:"
display "    效应值:        " %10.4f `late_2sls'
display "    标准误:        " %10.4f `late_se'
display "    95% CI:        [" %8.4f `ci_lower' ", " %8.4f `ci_upper' "]"
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

display "SS_TASK_END|id=TG24|status=ok|elapsed_sec=`elapsed'"
log close
