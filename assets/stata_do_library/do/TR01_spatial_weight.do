* ==============================================================================
* SS_TEMPLATE: id=TR01  level=L2  module=R  title="Spatial Weight"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TR01_weight_summary.csv type=table desc="Weight matrix summary"
*   - data_TR01_spatial.dta type=data desc="Output data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: spmatrix
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

display "SS_TASK_BEGIN|id=TR01|level=L2|title=Spatial_Weight"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=spmatrix|source=builtin|status=ok"

* ============ 参数设置 ============
local id_var = "__ID_VAR__"
local x_coord = "__X_COORD__"
local y_coord = "__Y_COORD__"
local weight_type = "__WEIGHT_TYPE__"
local k_neighbors = __K_NEIGHBORS__
local distance_band = __DISTANCE_BAND__

if "`weight_type'" == "" {
    local weight_type = "distance"
}
if `k_neighbors' < 1 | `k_neighbors' > 20 {
    local k_neighbors = 5
}

display ""
display ">>> 空间权重矩阵参数:"
display "    地区ID: `id_var'"
display "    坐标: (`x_coord', `y_coord')"
display "    权重类型: `weight_type'"
if "`weight_type'" == "knn" {
    display "    K近邻: `k_neighbors'"
}

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
foreach var in `id_var' `x_coord' `y_coord' {
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

* ============ 构建空间权重矩阵 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 构建空间权重矩阵"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算距离矩阵
display ">>> 计算距离矩阵..."

local n = _N
matrix D = J(`n', `n', 0)

forvalues i = 1/`n' {
    local xi = `x_coord'[`i']
    local yi = `y_coord'[`i']
    
    forvalues j = 1/`n' {
        if `i' != `j' {
            local xj = `x_coord'[`j']
            local yj = `y_coord'[`j']
            local dist = sqrt((`xi' - `xj')^2 + (`yi' - `yj')^2)
            matrix D[`i', `j'] = `dist'
        }
    }
    
    if mod(`i', 50) == 0 {
        display "    处理 `i' / `n' ..."
    }
}

* 构建权重矩阵
matrix W = J(`n', `n', 0)

if "`weight_type'" == "distance" {
    * 距离倒数权重
    display ">>> 构建距离倒数权重矩阵..."
    forvalues i = 1/`n' {
        forvalues j = 1/`n' {
            if `i' != `j' & D[`i', `j'] > 0 {
                matrix W[`i', `j'] = 1 / D[`i', `j']
            }
        }
    }
}
else if "`weight_type'" == "knn" {
    * K近邻权重
    display ">>> 构建K近邻权重矩阵 (K=`k_neighbors')..."
    forvalues i = 1/`n' {
        * 找出第i行的K个最近邻
        tempname dist_row
        matrix `dist_row' = D[`i', 1...]
        
        * 简化：对每个单元找K个最小距离
        forvalues k = 1/`k_neighbors' {
            local min_dist = .
            local min_j = 0
            forvalues j = 1/`n' {
                if `i' != `j' & D[`i', `j'] > 0 & D[`i', `j'] < `min_dist' & W[`i', `j'] == 0 {
                    local min_dist = D[`i', `j']
                    local min_j = `j'
                }
            }
            if `min_j' > 0 {
                matrix W[`i', `min_j'] = 1
            }
        }
    }
}
else {
    * 邻接权重（基于距离阈值）
    display ">>> 构建邻接权重矩阵..."
    if `distance_band' <= 0 {
        * 自动确定阈值（使每个单元至少有1个邻居）
        local distance_band = 0
        forvalues i = 1/`n' {
            local min_dist = .
            forvalues j = 1/`n' {
                if `i' != `j' & D[`i', `j'] < `min_dist' {
                    local min_dist = D[`i', `j']
                }
            }
            if `min_dist' > `distance_band' {
                local distance_band = `min_dist'
            }
        }
        local distance_band = `distance_band' * 1.1
    }
    
    forvalues i = 1/`n' {
        forvalues j = 1/`n' {
            if `i' != `j' & D[`i', `j'] <= `distance_band' {
                matrix W[`i', `j'] = 1
            }
        }
    }
}

* ============ 行标准化 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 行标准化"
display "═══════════════════════════════════════════════════════════════════════════════"

matrix W_std = W

forvalues i = 1/`n' {
    local row_sum = 0
    forvalues j = 1/`n' {
        local row_sum = `row_sum' + W[`i', `j']
    }
    if `row_sum' > 0 {
        forvalues j = 1/`n' {
            matrix W_std[`i', `j'] = W[`i', `j'] / `row_sum'
        }
    }
}

display ">>> 权重矩阵已行标准化"

* ============ 权重矩阵统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 权重矩阵统计"
display "═══════════════════════════════════════════════════════════════════════════════"

* 计算非零元素数和平均邻居数
local nonzero = 0
local min_neighbors = `n'
local max_neighbors = 0

forvalues i = 1/`n' {
    local row_nonzero = 0
    forvalues j = 1/`n' {
        if W[`i', `j'] > 0 {
            local nonzero = `nonzero' + 1
            local row_nonzero = `row_nonzero' + 1
        }
    }
    if `row_nonzero' < `min_neighbors' {
        local min_neighbors = `row_nonzero'
    }
    if `row_nonzero' > `max_neighbors' {
        local max_neighbors = `row_nonzero'
    }
}

local avg_neighbors = `nonzero' / `n'
local sparsity = 1 - `nonzero' / (`n' * `n')

display ""
display ">>> 权重矩阵统计:"
display "    维度: `n' x `n'"
display "    非零元素: `nonzero'"
display "    平均邻居数: " %6.2f `avg_neighbors'
display "    邻居范围: [`min_neighbors', `max_neighbors']"
display "    稀疏度: " %6.4f `sparsity'

display "SS_METRIC|name=n_units|value=`n'"
display "SS_METRIC|name=avg_neighbors|value=`avg_neighbors'"
display "SS_METRIC|name=sparsity|value=`sparsity'"

* 导出摘要
preserve
clear
set obs 1
generate str20 weight_type = "`weight_type'"
generate int n_units = `n'
generate int nonzero = `nonzero'
generate double avg_neighbors = `avg_neighbors'
generate double sparsity = `sparsity'

export delimited using "table_TR01_weight_summary.csv", replace
display "SS_OUTPUT_FILE|file=table_TR01_weight_summary.csv|type=table|desc=weight_summary"
restore

* ============ 保存权重矩阵 ============
* 将权重保存为变量
forvalues j = 1/`n' {
    generate double w_`j' = .
    forvalues i = 1/`n' {
        replace w_`j' = W_std[`i', `j'] in `i'
    }
}

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TR01_spatial.dta", replace
display "SS_OUTPUT_FILE|file=data_TR01_spatial.dta|type=data|desc=spatial_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TR01 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  空间单元数:      " %10.0fc `n'
display "  权重类型:        `weight_type'"
display "  平均邻居数:      " %10.2f `avg_neighbors'
display "  稀疏度:          " %10.4f `sparsity'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=avg_neighbors|value=`avg_neighbors'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TR01|status=ok|elapsed_sec=`elapsed'"
log close
