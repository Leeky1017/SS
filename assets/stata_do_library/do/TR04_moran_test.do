* ==============================================================================
* SS_TEMPLATE: id=TR04  level=L2  module=R  title="Moran Test"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TR04_moran_global.csv type=table desc="Global Moran I"
*   - table_TR04_moran_local.csv type=table desc="Local Moran I"
*   - fig_TR04_moran_scatter.png type=figure desc="Moran scatter plot"
*   - data_TR04_moran.dta type=data desc="Output data"
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

display "SS_TASK_BEGIN|id=TR04|level=L2|title=Moran_Test"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local var = "__VAR__"
local id_var = "__ID_VAR__"
local x_coord = "__X_COORD__"
local y_coord = "__Y_COORD__"

display ""
display ">>> Moran's I检验参数:"
display "    检验变量: `var'"
display "    地区ID: `id_var'"

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
foreach v in `var' `id_var' `x_coord' `y_coord' {
    capture confirm variable `v'
    if _rc {
        display "SS_ERROR:VAR_NOT_FOUND:`v' not found"
        display "SS_ERR:VAR_NOT_FOUND:`v' not found"
        log close
        exit 200
    }
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 构建空间权重 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 构建空间权重矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

local n = _N
matrix W = J(`n', `n', 0)
local S0 = 0

forvalues i = 1/`n' {
    local xi = `x_coord'[`i']
    local yi = `y_coord'[`i']
    local row_sum = 0
    
    forvalues j = 1/`n' {
        if `i' != `j' {
            local xj = `x_coord'[`j']
            local yj = `y_coord'[`j']
            local dist = sqrt((`xi' - `xj')^2 + (`yi' - `yj')^2)
            if `dist' > 0 {
                matrix W[`i', `j'] = 1 / `dist'
                local row_sum = `row_sum' + 1 / `dist'
            }
        }
    }
    
    if `row_sum' > 0 {
        forvalues j = 1/`n' {
            matrix W[`i', `j'] = W[`i', `j'] / `row_sum'
            local S0 = `S0' + W[`i', `j']
        }
    }
}

display ">>> 权重矩阵已构建，S0 = " %10.4f `S0'

* ============ 全局Moran's I ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 全局Moran's I"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize `var'
local mean_var = r(mean)
local var_var = r(Var)

* 标准化变量
generate double z_var = (`var' - `mean_var') / sqrt(`var_var')

* 计算空间滞后
generate double Wz = 0
forvalues i = 1/`n' {
    local wz = 0
    forvalues j = 1/`n' {
        local wz = `wz' + W[`i', `j'] * z_var[`j']
    }
    replace Wz = `wz' in `i'
}

* Moran's I = (n/S0) * Σ_i Σ_j w_ij * z_i * z_j / Σ_i z_i²
local moran_num = 0
local moran_denom = 0

forvalues i = 1/`n' {
    local zi = z_var[`i']
    local moran_denom = `moran_denom' + `zi'^2
    
    forvalues j = 1/`n' {
        local zj = z_var[`j']
        local moran_num = `moran_num' + W[`i', `j'] * `zi' * `zj'
    }
}

local moran_i = (`n' / `S0') * `moran_num' / `moran_denom'

* 期望值和方差（正态近似）
local E_I = -1 / (`n' - 1)
local V_I = (`n'^2) / ((`n'-1)^2 * (`n'+1)) - `E_I'^2

local z_moran = (`moran_i' - `E_I') / sqrt(`V_I')
local p_moran = 2 * (1 - normal(abs(`z_moran')))

display ""
display ">>> 全局Moran's I:"
display "    I = " %10.4f `moran_i'
display "    E(I) = " %10.4f `E_I'
display "    z = " %10.4f `z_moran'
display "    p值 = " %10.4f `p_moran'

if `p_moran' < 0.05 {
    if `moran_i' > 0 {
        display "    结论: 存在显著正空间自相关（聚集）"
        local conclusion = "正空间自相关"
    }
    else {
        display "    结论: 存在显著负空间自相关（分散）"
        local conclusion = "负空间自相关"
    }
}
else {
    display "    结论: 无显著空间自相关"
    local conclusion = "无空间自相关"
}

display "SS_METRIC|name=moran_i|value=`moran_i'"
display "SS_METRIC|name=z_moran|value=`z_moran'"
display "SS_METRIC|name=p_moran|value=`p_moran'"

* 导出全局结果
preserve
clear
set obs 1
generate double moran_i = `moran_i'
generate double expected = `E_I'
generate double z_stat = `z_moran'
generate double p_value = `p_moran'
generate str30 conclusion = "`conclusion'"

export delimited using "table_TR04_moran_global.csv", replace
display "SS_OUTPUT_FILE|file=table_TR04_moran_global.csv|type=table|desc=moran_global"
restore

* ============ 局部Moran's I (LISA) ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 局部Moran's I (LISA)"
display "═══════════════════════════════════════════════════════════════════════════════"

generate double local_moran = .
generate double local_z = .
generate str20 cluster_type = ""

forvalues i = 1/`n' {
    local zi = z_var[`i']
    local wzi = Wz[`i']
    
    * 局部Moran's I = z_i * Σ_j w_ij * z_j
    local li = `zi' * `wzi'
    replace local_moran = `li' in `i'
    
    * 分类
    if `zi' > 0 & `wzi' > 0 {
        replace cluster_type = "HH" in `i'
    }
    else if `zi' < 0 & `wzi' < 0 {
        replace cluster_type = "LL" in `i'
    }
    else if `zi' > 0 & `wzi' < 0 {
        replace cluster_type = "HL" in `i'
    }
    else {
        replace cluster_type = "LH" in `i'
    }
}

display ""
display ">>> LISA聚类分布:"
tabulate cluster_type

* 导出局部结果
preserve
keep `id_var' `var' z_var Wz local_moran cluster_type
export delimited using "table_TR04_moran_local.csv", replace
display "SS_OUTPUT_FILE|file=table_TR04_moran_local.csv|type=table|desc=moran_local"
restore

* ============ 生成Moran散点图 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 4: 生成Moran散点图"
display "═══════════════════════════════════════════════════════════════════════════════"

twoway (scatter Wz z_var, mcolor(navy%50) msize(small)) ///
       (lfit Wz z_var, lcolor(red) lwidth(medium)), ///
       xline(0, lcolor(gray) lpattern(dash)) ///
       yline(0, lcolor(gray) lpattern(dash)) ///
       xtitle("标准化变量 z") ytitle("空间滞后 Wz") ///
       title("Moran散点图") ///
       note("Moran's I=" %6.4f `moran_i' ", p=" %6.4f `p_moran') ///
       legend(off)
graph export "fig_TR04_moran_scatter.png", replace width(1200)
display "SS_OUTPUT_FILE|file=fig_TR04_moran_scatter.png|type=figure|desc=moran_scatter"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TR04_moran.dta", replace
display "SS_OUTPUT_FILE|file=data_TR04_moran.dta|type=data|desc=moran_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TR04 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  样本量:          " %10.0fc `n_input'
display ""
display "  全局Moran's I:"
display "    I:             " %10.4f `moran_i'
display "    z值:           " %10.4f `z_moran'
display "    p值:           " %10.4f `p_moran'
display "    结论:          `conclusion'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=moran_i|value=`moran_i'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TR04|status=ok|elapsed_sec=`elapsed'"
log close
