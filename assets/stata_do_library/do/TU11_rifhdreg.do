* ==============================================================================
* SS_TEMPLATE: id=TU11  level=L2  module=U  title="RIF-HDReg"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TU11_rifhdreg.csv type=table desc="RIF regression results"
*   - data_TU11_rifhdreg.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Unconditional quantile effects are typically estimated via RIF regression; document the target quantile and density estimation choices.
* - Density at the quantile must be well-behaved; if the estimated density is near zero, RIF becomes unstable—inspect distribution and bandwidth.
* - Use robust/clustered SE when appropriate; interpretation is descriptive unless identification assumptions are satisfied.
* 最佳实践审查（ZH）:
* - 无条件分位数效应通常通过 RIF 回归估计；请明确目标分位数以及密度估计设定。
* - 分位点处密度需稳定；若估计密度接近 0，RIF 会非常不稳定——应检查分布与带宽设定。
* - 在需要时使用稳健/聚类标准误；除非满足识别假设，否则解释偏描述性。

* ============ 初始化 ============
capture log close _all
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=no_active_log|severity=warn"
}
clear all
set more off
version 18

timer clear 1
timer on 1

log using "result.log", text replace

display "SS_TASK_BEGIN|id=TU11|level=L2|title=RIF_HDReg"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local depvar = "__DEPVAR__"
local indepvars = "__INDEPVARS__"
local quantile_raw = "__QUANTILE__"
local quantile = real("`quantile_raw'")

if missing(`quantile') | `quantile' <= 0 | `quantile' >= 1 {
    local quantile = 0.5
}

display ""
display ">>> 无条件分位数回归参数:"
display "    因变量: `depvar'"
display "    自变量: `indepvars'"
display "    分位数: `quantile'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file|msg=data_file_not_found|severity=fail"
    log close
    exit 601
}
import delimited "data.csv", clear
local n_input = _N
if `n_input' <= 0 {
    display "SS_RC|code=2000|cmd=import delimited|msg=empty_dataset|severity=fail"
    log close
    exit 2000
}
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"
* EN: Validate dependent/independent variables.
* ZH: 校验因变量与自变量存在且为数值型。
capture confirm numeric variable `depvar'
if _rc {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=depvar_not_found|var=`depvar'|severity=fail"
    log close
    exit 200
}
local valid_indep ""
foreach v of local indepvars {
    capture confirm numeric variable `v'
    if !_rc {
        local valid_indep "`valid_indep' `v'"
    }
}
if "`valid_indep'" == "" {
    display "SS_RC|code=200|cmd=confirm numeric variable|msg=no_valid_indepvars|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ RIF回归（内置实现） ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 无条件分位数回归 (RIF regression)"
display "═══════════════════════════════════════════════════════════════════════════════"

* EN: Construct RIF(y; q_tau) = q_tau + (tau - I(y<=q_tau))/f(q_tau), then run OLS on RIF.
* ZH: 构造 RIF(y; q_tau) 并对 RIF 进行 OLS 回归。

quietly _pctile `depvar', p(`=100 * `quantile'')
local q_tau = r(r1)
display "SS_METRIC|name=q_tau|value=`q_tau'"

* Density estimation at q_tau (grid + nearest point). / 分位点密度估计（网格+最近点）。
tempvar kd_x kd_f kd_dist
preserve
keep `depvar'
drop if missing(`depvar')
quietly count
local n_nonmissing_y = r(N)
if `n_nonmissing_y' < 20 {
    display "SS_RC|code=2001|cmd=kdensity|msg=too_few_nonmissing_depvar_for_density|n_nonmissing=`n_nonmissing_y'|severity=fail"
    log close
    exit 2001
}
quietly kdensity `depvar', n(400) nograph generate(`kd_x' `kd_f')
keep if !missing(`kd_x')
gen double `kd_dist' = abs(`kd_x' - `q_tau')
sort `kd_dist'
local f_q = `kd_f'[1]
restore

display "SS_METRIC|name=f_at_q_tau|value=`f_q'"
if missing(`f_q') | `f_q' <= 0 {
    display "SS_RC|code=2002|cmd=kdensity|msg=invalid_density_at_quantile|f_at_q_tau=`f_q'|severity=fail"
    log close
    exit 2002
}

tempvar rif_y rif_leq
gen byte `rif_leq' = (`depvar' <= `q_tau') if !missing(`depvar')
gen double `rif_y' = `q_tau' + (`quantile' - `rif_leq') / `f_q' if !missing(`depvar')

capture noisily regress `rif_y' `valid_indep'
local rc = _rc
if `rc' != 0 {
    display "SS_RC|code=`rc'|cmd=regress|msg=rif_regression_failed|severity=fail"
    log close
    exit `rc'
}

matrix b = e(b)
matrix V = e(V)
local n_obs = e(N)

display ""
display ">>> RIF回归结果:"
display "    样本量: `n_obs'"
display "    分位数: `quantile'"

display "SS_METRIC|name=n_obs|value=`n_obs'"
display "SS_METRIC|name=quantile|value=`quantile'"

* 导出结果
preserve
clear
local cols : colnames b
local ncols : word count `cols'
set obs `ncols'
gen str30 variable = ""
gen double coef = .
gen double se = .

forvalues i = 1/`ncols' {
    local vname : word `i' of `cols'
    replace variable = "`vname'" in `i'
    replace coef = b[1, `i'] in `i'
    replace se = sqrt(V[`i', `i']) in `i'
}

export delimited using "table_TU11_rifhdreg.csv", replace
display "SS_OUTPUT_FILE|file=table_TU11_rifhdreg.csv|type=table|desc=rif_results"
restore

drop `rif_y' `rif_leq'

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TU11_rifhdreg.dta", replace
display "SS_OUTPUT_FILE|file=data_TU11_rifhdreg.dta|type=data|desc=rif_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TU11 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  分位数:          " %10.2f `quantile'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=quantile|value=`quantile'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TU11|status=ok|elapsed_sec=`elapsed'"
log close
