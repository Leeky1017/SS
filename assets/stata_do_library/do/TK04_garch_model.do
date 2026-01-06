* ==============================================================================
* SS_TEMPLATE: id=TK04  level=L2  module=K  title="GARCH Model"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TK04_garch_result.csv type=table desc="GARCH results"
*   - table_TK04_volatility.csv type=table desc="Volatility series"
*   - fig_TK04_volatility.png type=figure desc="Volatility plot"
*   - data_TK04_garch.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TK04|level=L2|title=GARCH_Model"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local return_var = "__RETURN_VAR__"
local model = "__MODEL__"
local p = __P__
local q = __Q__
local dist = "__DIST__"

if "`model'" == "" | ("`model'" != "garch" & "`model'" != "egarch" & "`model'" != "gjr") {
    local model = "garch"
}
if `p' < 1 | `p' > 5 {
    local p = 1
}
if `q' < 1 | `q' > 5 {
    local q = 1
}
if "`dist'" == "" | ("`dist'" != "gaussian" & "`dist'" != "t") {
    local dist = "gaussian"
}

display ""
display ">>> GARCH模型参数:"
display "    收益变量: `return_var'"
display "    模型: `model'(`p',`q')"
display "    分布: `dist'"

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
capture confirm numeric variable `return_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`return_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`return_var' not found"
    log close
    exit 200
}

* 设置时间序列
generate t = _n
tsset t
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 描述性统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 收益序列描述性统计"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize `return_var', detail
local mean_ret = r(mean)
local sd_ret = r(sd)
local skew = r(skewness)
local kurt = r(kurtosis)

display ""
display ">>> 收益序列统计:"
display "    均值: " %12.6f `mean_ret'
display "    标准差: " %12.6f `sd_ret'
display "    偏度: " %12.4f `skew'
display "    峰度: " %12.4f `kurt'

* 检验ARCH效应
quietly regress `return_var' L.`return_var'
predict resid, residuals
generate resid2 = resid^2

quietly regress resid2 L(1/5).resid2
local arch_f = e(F)
local arch_p = Ftail(5, e(df_r), `arch_f')

display ""
display ">>> ARCH效应检验:"
display "    LM统计量(5阶): " %10.4f `arch_f'
display "    p值: " %10.4f `arch_p'

if `arch_p' < 0.05 {
    display "    结论: 存在显著ARCH效应"
}
else {
    display "SS_WARNING:NO_ARCH:No significant ARCH effect detected"
}

drop resid resid2

* ============ GARCH模型估计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: GARCH模型估计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 构建模型命令
if "`model'" == "garch" {
    display ">>> 估计GARCH(`p',`q')模型..."
    if "`dist'" == "t" {
        arch `return_var', arch(`p') garch(`q') distribution(t)
    }
    else {
        arch `return_var', arch(`p') garch(`q')
    }
}
else if "`model'" == "egarch" {
    display ">>> 估计EGARCH(`p',`q')模型..."
    if "`dist'" == "t" {
        arch `return_var', earch(`p') egarch(`q') distribution(t)
    }
    else {
        arch `return_var', earch(`p') egarch(`q')
    }
}
else {
    display ">>> 估计GJR-GARCH(`p',`q')模型..."
    if "`dist'" == "t" {
        arch `return_var', arch(`p') garch(`q') tarch(`p') distribution(t)
    }
    else {
        arch `return_var', arch(`p') garch(`q') tarch(`p')
    }
}

* 提取参数
local ll = e(ll)
local aic = -2 * `ll' + 2 * e(k)
local bic = -2 * `ll' + ln(e(N)) * e(k)

display ""
display ">>> 模型拟合统计:"
display "    对数似然: " %12.4f `ll'
display "    AIC: " %12.4f `aic'
display "    BIC: " %12.4f `bic'

display "SS_METRIC|name=ll|value=`ll'"
display "SS_METRIC|name=aic|value=`aic'"
display "SS_METRIC|name=bic|value=`bic'"

* 保存参数估计
tempname garch_params
postfile `garch_params' str20 parameter double estimate double se double z double p ///
    using "temp_garch_params.dta", replace

matrix b = e(b)
matrix V = e(V)
local varnames : colnames b
local nvars : word count `varnames'

forvalues i = 1/`nvars' {
    local vname : word `i' of `varnames'
    local coef = b[1, `i']
    local se = sqrt(V[`i', `i'])
    local z = `coef' / `se'
    local p = 2 * (1 - normal(abs(`z')))
    post `garch_params' ("`vname'") (`coef') (`se') (`z') (`p')
}

postclose `garch_params'

preserve
use "temp_garch_params.dta", clear
export delimited using "table_TK04_garch_result.csv", replace
display "SS_OUTPUT_FILE|file=table_TK04_garch_result.csv|type=table|desc=garch_results"
restore

* ============ 计算条件波动率 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 条件波动率"
display "═══════════════════════════════════════════════════════════════════════════════"

predict double cond_var, variance
generate double cond_vol = sqrt(cond_var)
label variable cond_vol "条件波动率"

quietly summarize cond_vol
local avg_vol = r(mean)
local min_vol = r(min)
local max_vol = r(max)

display ""
display ">>> 条件波动率统计:"
display "    均值: " %10.6f `avg_vol'
display "    最小: " %10.6f `min_vol'
display "    最大: " %10.6f `max_vol'

display "SS_METRIC|name=avg_vol|value=`avg_vol'"

* 导出波动率序列
preserve
keep t `return_var' cond_var cond_vol
export delimited using "table_TK04_volatility.csv", replace
display "SS_OUTPUT_FILE|file=table_TK04_volatility.csv|type=table|desc=volatility_series"
restore

* ============ 生成波动率图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成波动率图"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway (line cond_vol t, lcolor(navy) lwidth(thin)), ///
    xtitle("时间") ytitle("条件波动率") ///
    title("`model'(`p',`q')条件波动率") ///
    note("分布: `dist'")
graph export "fig_TK04_volatility.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TK04_volatility.png|type=figure|desc=volatility_plot"

* ============ 模型诊断 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 5: 模型诊断"
display "═══════════════════════════════════════════════════════════════════════════════"

* 标准化残差
predict double std_resid, residuals
replace std_resid = std_resid / cond_vol

* 检验标准化残差的ARCH效应
generate std_resid2 = std_resid^2
quietly regress std_resid2 L(1/5).std_resid2
local arch_f_post = e(F)
local arch_p_post = Ftail(5, e(df_r), `arch_f_post')

display ""
display ">>> 标准化残差ARCH检验:"
display "    LM统计量(5阶): " %10.4f `arch_f_post'
display "    p值: " %10.4f `arch_p_post'

if `arch_p_post' >= 0.05 {
    display "    结论: 模型充分捕获了ARCH效应"
}
else {
    display "SS_WARNING:RESIDUAL_ARCH:Residual ARCH effect remains"
}

drop std_resid std_resid2

* ============ 输出结果 ============
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TK04_garch.dta", replace
display "SS_OUTPUT_FILE|file=data_TK04_garch.dta|type=data|desc=garch_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

capture erase "temp_garch_params.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TK04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display "  模型:            `model'(`p',`q')"
display "  分布:            `dist'"
display ""
display "  模型拟合:"
display "    对数似然:      " %10.4f `ll'
display "    AIC:           " %10.4f `aic'
display "    BIC:           " %10.4f `bic'
display ""
display "  条件波动率:"
display "    均值:          " %10.6f `avg_vol'
display "    范围:          [" %8.6f `min_vol' ", " %8.6f `max_vol' "]"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=aic|value=`aic'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TK04|status=ok|elapsed_sec=`elapsed'"
log close
