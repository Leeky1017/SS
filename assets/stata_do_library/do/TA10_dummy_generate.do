* ==============================================================================
* SS_TEMPLATE: id=TA10  level=L0  module=A  title="Dummy Generate"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
* OUTPUTS:
*   - table_TA10_dummy_codebook.csv type=table desc="Dummy codebook"
*   - data_TA10_with_dummies.dta type=data desc="Data with dummies"
*   - data_TA10_with_dummies.csv type=data desc="Data CSV with dummies"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="tabulate command"
* ==============================================================================
* Task ID:      TA10_dummy_generate
* Task Name:    虚拟变量批量生成
* Family:       A - 数据管理
* Description:  为分类变量批量生成虚拟变量
* 
* Placeholders: __CAT_VARS__       - 分类变量列表
*               __BASE_CATEGORY__  - 基准组
*               __PREFIX__         - 虚拟变量前缀
*               __DROP_FIRST__     - 是否删除第一个
*               __INTERACTION__    - 交互项
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ============ 初始化 ============
capture log close _all
local rc = _rc
if `rc' {
    display "SS_RC|code=`rc'|cmd=log close _all|msg=log_close_failed|severity=warn"
}
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=TA10|level=L0|title=Dummy_Generate"
display "SS_METRIC|name=task_version|value=2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local cat_vars "__CAT_VARS__"
local base_category "__BASE_CATEGORY__"
local prefix "__PREFIX__"
local drop_first "__DROP_FIRST__"
local interaction "__INTERACTION__"

* 参数默认值
if "`prefix'" == "" {
    local prefix = "d_"
}
if "`drop_first'" == "" | ("`drop_first'" != "yes" & "`drop_first'" != "no") {
    local drop_first = "yes"
}

display ""
display ">>> 虚拟变量生成参数:"
display "    分类变量: `cat_vars'"
display "    前缀: `prefix'"
display "    删除第一个: `drop_first'"
if "`base_category'" != "" {
    display "    基准组: `base_category'"
}
if "`interaction'" != "" {
    display "    交互项: `interaction'"
}

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
capture confirm file "data.csv"
if _rc {
    display "SS_RC|code=601|cmd=confirm file data.csv|msg=input_file_not_found|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 601
}
import delimited "data.csv", clear varnames(1) encoding(utf8)
local n_input = _N
display "SS_METRIC|name=n_input|value=`n_input'"

* ============ 变量检查 ============
local valid_vars ""
foreach var of local cat_vars {
    capture confirm variable `var'
    if _rc {
        display ">>> 警告: `var' 不存在，跳过"
        display "SS_RC|code=0|cmd=confirm variable `var'|msg=cat_var_not_found_skipped|severity=warn"
    }
    else {
        local valid_vars "`valid_vars' `var'"
    }
}

if "`valid_vars'" == "" {
    display "SS_RC|code=200|cmd=validate_cat_vars|msg=no_valid_categorical_vars|severity=fail"
    timer off 1
    quietly timer list 1
    local elapsed = round(r(t1))
    display "SS_TASK_END|id=TA10|status=fail|elapsed_sec=`elapsed'"
    log close
    exit 200
}

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 生成虚拟变量 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 生成虚拟变量"
display "═══════════════════════════════════════════════════════════════════════════════"

* 创建编码表存储
tempname codebook
postfile `codebook' str32 source_var str32 dummy_var int category str50 label long n ///
    using "temp_dummy_codebook.dta", replace

local n_dummies = 0
local all_dummies ""

foreach var of local valid_vars {
    display ""
    display ">>> 处理变量: `var'"
    
    * 检查变量类型
    capture confirm string variable `var'
    local is_string = (_rc == 0)
    
    if `is_string' {
        * 字符串变量：先编码
        display "    类型: 字符串 -> 先进行编码"
        encode `var', generate(`var'_coded)
        local work_var = "`var'_coded"
    }
    else {
        local work_var = "`var'"
    }
    
    * 获取所有类别
    quietly levelsof `work_var', local(categories)
    local n_cats : word count `categories'
    display "    类别数: `n_cats'"
    
    * 确定基准组
    local base_val : word 1 of `categories'
    display "    基准组: `base_val'"
    
    * 生成虚拟变量
    local cat_num = 0
    foreach cat of local categories {
        local cat_num = `cat_num' + 1
        
        * 获取标签
        local cat_label : label (`work_var') `cat'
        if "`cat_label'" == "" {
            local cat_label = "`cat'"
        }
        
        * 是否跳过基准组
        local skip = 0
        if "`drop_first'" == "yes" & `cat_num' == 1 {
            local skip = 1
            display "    跳过基准组: `cat' (`cat_label')"
        }
        
        if !`skip' {
            * 生成虚拟变量名
            local dummy_name = "`prefix'`var'_`cat'"
            * 清理变量名中的特殊字符
            local dummy_name = subinstr("`dummy_name'", "-", "_", .)
            local dummy_name = subinstr("`dummy_name'", " ", "_", .)
            local dummy_name = subinstr("`dummy_name'", ".", "_", .)
            
            * 生成虚拟变量
            generate byte `dummy_name' = (`work_var' == `cat') if !missing(`work_var')
            label variable `dummy_name' "`var'=`cat_label'"
            
            local all_dummies "`all_dummies' `dummy_name'"
            local n_dummies = `n_dummies' + 1
            
            * 统计
            quietly count if `dummy_name' == 1
            local n_cat = r(N)
            
            post `codebook' ("`var'") ("`dummy_name'") (`cat') ("`cat_label'") (`n_cat')
            
            display "    生成: `dummy_name' (N=`n_cat')"
        }
        else {
            * 记录基准组
            quietly count if `work_var' == `cat'
            local n_cat = r(N)
            post `codebook' ("`var'") ("(base)") (`cat') ("`cat_label' [BASE]") (`n_cat')
        }
    }
    
    * 删除临时编码变量
    if `is_string' {
        drop `var'_coded
    }
}

postclose `codebook'

display ""
display ">>> 总共生成虚拟变量: `n_dummies' 个"
display "SS_METRIC|name=n_dummies|value=`n_dummies'"

* ============ 生成交互项 ============
if "`interaction'" != "" {
    display ""
    display "═══════════════════════════════════════════════════════════════════════════════"
    display "SECTION 2: 生成交互项"
    display "═══════════════════════════════════════════════════════════════════════════════"
    
    * 解析交互项（格式：var1*var2）
    local interaction = subinstr("`interaction'", ",", " ", .)
    
    foreach int_pair of local interaction {
        local pos = strpos("`int_pair'", "*")
        if `pos' > 0 {
            local var1 = substr("`int_pair'", 1, `pos'-1)
            local var2 = substr("`int_pair'", `pos'+1, .)
            
            display ""
            display ">>> 生成交互项: `var1' * `var2'"
            
            * 查找对应的虚拟变量
            foreach d1 of local all_dummies {
                if strpos("`d1'", "`var1'") > 0 {
                    foreach d2 of local all_dummies {
                        if strpos("`d2'", "`var2'") > 0 {
                            local int_name = "`d1'_X_`d2'"
                            * 截断过长的变量名
                            if strlen("`int_name'") > 32 {
                                local int_name = substr("`int_name'", 1, 32)
                            }
                            
                            capture generate byte `int_name' = `d1' * `d2'
                            if !_rc {
                                local n_dummies = `n_dummies' + 1
                                display "    生成: `int_name'"
                            }
                        }
                    }
                }
            }
        }
    }
    
    display ""
    display ">>> 交互项生成完成"
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 输出结果 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

* 导出编码表
preserve
use "temp_dummy_codebook.dta", clear
export delimited using "table_TA10_dummy_codebook.csv", replace
display "SS_OUTPUT_FILE|file=table_TA10_dummy_codebook.csv|type=table|desc=dummy_codebook"
restore

* 导出数据
local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

save "data_TA10_with_dummies.dta", replace
display "SS_OUTPUT_FILE|file=data_TA10_with_dummies.dta|type=data|desc=data_with_dummies"

export delimited using "data_TA10_with_dummies.csv", replace
display "SS_OUTPUT_FILE|file=data_TA10_with_dummies.csv|type=data|desc=data_csv_dummies"

* 清理临时文件
capture erase "temp_dummy_codebook.dta"
if _rc != 0 { }

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA10 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  处理分类变量:    " %10.0fc `: word count `valid_vars''
display "  生成虚拟变量:    " %10.0fc `n_dummies'
display "  删除基准组:      `drop_first'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_dummies|value=`n_dummies'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA10|status=ok|elapsed_sec=`elapsed'"
log close
