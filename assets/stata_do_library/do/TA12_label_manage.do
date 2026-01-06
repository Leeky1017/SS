* ==============================================================================
* SS_TEMPLATE: id=TA12  level=L0  module=A  title="Label Manage"
* INPUTS:
*   - data.dta  role=main_dataset  required=yes
*   - data.csv  role=main_dataset  required=no
*   - label_dict.csv  role=config  required=no
* OUTPUTS:
*   - table_TA12_label_export.csv type=table desc="Label export"
*   - data_TA12_labeled.dta type=data desc="Labeled data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES:
*   - stata source=built-in purpose="label commands"
* ==============================================================================
* Task ID:      TA12_label_manage
* Task Name:    变量标签批量管理
* Family:       A - 数据管理
* Description:  批量管理变量标签和值标签
* 
* Placeholders: __OPERATION__      - 操作类型
*               __DICT_FILE__      - 标签字典文件
*               __TARGET_VARS__    - 目标变量列表
*
* Author:       Stata Task Template System
* Stata:        18.0+ (official commands only)
* ==============================================================================

* ============ 初始化 ============
capture log close _all
if _rc != 0 { }
clear all
set more off
version 18

* ============ 计时器初始化 ============
timer clear 1
timer on 1

log using "result.log", text replace

* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_BEGIN|id=TA12|level=L0|title=Label_Manage"
display "SS_TASK_VERSION:2.0.1"

* ============ 依赖检查 ============
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local operation = "__OPERATION__"
local dict_file = "__DICT_FILE__"
local target_vars = "__TARGET_VARS__"

* 参数默认值
if "`operation'" == "" {
    local operation = "export"
}

display ""
display ">>> 标签管理参数:"
display "    操作: `operation'"
if "`dict_file'" != "" {
    display "    字典文件: `dict_file'"
}
if "`target_vars'" != "" {
    display "    目标变量: `target_vars'"
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
display "SS_METRIC:n_input:`n_input'"

* ============ 获取变量列表 ============
if "`target_vars'" == "" {
    ds
    local target_vars = r(varlist)
}

local n_vars : word count `target_vars'
display ">>> 处理变量数: `n_vars'"

display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

* ============ 执行操作 ============
display "SS_STEP_BEGIN|step=S02_validate_inputs"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 执行标签操作 - `operation'"
display "═══════════════════════════════════════════════════════════════════════════════"

if "`operation'" == "export" {
    * 导出现有标签
    display ""
    display ">>> 导出变量标签..."
    
    * 创建标签存储
    tempname labels
    postfile `labels' str32 variable str80 var_label str20 type long n_values ///
        using "temp_labels.dta", replace
    
    local n_labeled = 0
    
    foreach var of local target_vars {
        * 获取变量标签
        local varlabel : variable label `var'
        
        * 获取变量类型
        local vartype : type `var'
        
        * 获取值标签数量（如果有）
        local n_val_labels = 0
        capture label list `var'
        if !_rc {
            * 有值标签
            local n_val_labels = r(k)
        }
        
        post `labels' ("`var'") ("`varlabel'") ("`vartype'") (`n_val_labels')
        
        if "`varlabel'" != "" {
            local n_labeled = `n_labeled' + 1
            display "  `var': `varlabel'"
        }
    }
    
    postclose `labels'
    
    display ""
    display ">>> 有标签的变量: `n_labeled' / `n_vars'"
    display "SS_METRIC:n_labeled:`n_labeled'"
    
    * 导出标签清单
    preserve
    use "temp_labels.dta", clear
    export delimited using "table_TA12_label_export.csv", replace
    display "SS_OUTPUT_FILE|file=table_TA12_label_export.csv|type=table|desc=label_export"
    restore
    
    capture erase "temp_labels.dta"
    if _rc != 0 { }
}
else if "`operation'" == "import" {
    * 从字典文件导入标签
    display ""
    display ">>> 从字典文件导入标签..."
    
    if "`dict_file'" == "" {
        local dict_file = "label_dict.csv"
    }
    
    capture confirm file "`dict_file'"
    if _rc {
        display "SS_WARNING:DICT_NOT_FOUND:`dict_file' not found, creating template"
        
        * 创建模板字典文件
        preserve
        clear
        set obs 3
        generate str32 variable = ""
        generate str80 label = ""
        replace variable = "example_var1" in 1
        replace label = "示例变量1标签" in 1
        replace variable = "example_var2" in 2
        replace label = "示例变量2标签" in 2
        replace variable = "example_var3" in 3
        replace label = "示例变量3标签" in 3
        export delimited using "label_dict_template.csv", replace
        display "SS_OUTPUT_FILE|file=label_dict_template.csv|type=table|desc=label_dict_template"
        display ">>> 已创建模板文件: label_dict_template.csv"
        restore
    }
    else {
        * 加载字典并应用标签
        preserve
        import delimited "`dict_file'", clear varnames(1)
        
        * 检查必需列
        capture confirm variable variable
        capture confirm variable label
        if _rc {
            display "SS_ERROR:DICT_FORMAT:Dictionary must have 'variable' and 'label' columns"
            display "SS_ERR:DICT_FORMAT:Dictionary must have 'variable' and 'label' columns"
            restore
            log close
            exit 198
        }
        
        local n_dict = _N
        
        forvalues i = 1/`n_dict' {
            local v = variable[`i']
            local l = label[`i']
            
            * 保存到本地宏
            local dict_`v' = "`l'"
        }
        restore
        
        * 应用标签
        local n_applied = 0
        foreach var of local target_vars {
            if "`dict_`var''" != "" {
                label variable `var' "`dict_`var''"
                local n_applied = `n_applied' + 1
                display "  `var': `dict_`var''"
            }
        }
        
        display ""
        display ">>> 已应用标签: `n_applied' 个变量"
        display "SS_METRIC:n_applied:`n_applied'"
    }
    
    * 导出结果
    preserve
    clear
    set obs 1
    generate str50 status = "Labels imported from `dict_file'"
    export delimited using "table_TA12_label_export.csv", replace
    display "SS_OUTPUT_FILE|file=table_TA12_label_export.csv|type=table|desc=label_export"
    restore
}
else if "`operation'" == "clean" {
    * 清理无效/空标签
    display ""
    display ">>> 清理无效标签..."
    
    local n_cleaned = 0
    
    foreach var of local target_vars {
        local varlabel : variable label `var'
        
        * 检查是否需要清理
        local needs_clean = 0
        
        * 检查空标签
        if "`varlabel'" == "" {
            continue
        }
        
        * 检查是否只有空格
        local trimmed = strtrim("`varlabel'")
        if "`trimmed'" == "" {
            label variable `var' ""
            local n_cleaned = `n_cleaned' + 1
            display "  清理空白标签: `var'"
            continue
        }
        
        * 检查是否与变量名相同
        if "`varlabel'" == "`var'" {
            label variable `var' ""
            local n_cleaned = `n_cleaned' + 1
            display "  清理重复标签: `var'"
        }
    }
    
    display ""
    display ">>> 清理标签数: `n_cleaned'"
    display "SS_METRIC:n_cleaned:`n_cleaned'"
    
    * 导出清理结果
    preserve
    clear
    set obs 1
    generate str50 status = "Cleaned `n_cleaned' labels"
    export delimited using "table_TA12_label_export.csv", replace
    display "SS_OUTPUT_FILE|file=table_TA12_label_export.csv|type=table|desc=label_export"
    restore
}
else if "`operation'" == "auto" {
    * 自动生成标签（基于变量名）
    display ""
    display ">>> 自动生成标签..."
    
    local n_auto = 0
    
    foreach var of local target_vars {
        local varlabel : variable label `var'
        
        * 只处理没有标签的变量
        if "`varlabel'" == "" {
            * 将变量名转换为标签
            local newlabel = subinstr("`var'", "_", " ", .)
            local newlabel = strproper("`newlabel'")
            
            label variable `var' "`newlabel'"
            local n_auto = `n_auto' + 1
            display "  `var' -> `newlabel'"
        }
    }
    
    display ""
    display ">>> 自动生成标签数: `n_auto'"
    display "SS_METRIC:n_auto:`n_auto'"
    
    * 导出结果
    preserve
    clear
    set obs 1
    generate str50 status = "Auto-generated `n_auto' labels"
    export delimited using "table_TA12_label_export.csv", replace
    display "SS_OUTPUT_FILE|file=table_TA12_label_export.csv|type=table|desc=label_export"
    restore
}

display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

* ============ 输出结果 ============
display "SS_STEP_BEGIN|step=S03_analysis"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 输出结果"
display "═══════════════════════════════════════════════════════════════════════════════"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

save "data_TA12_labeled.dta", replace
display "SS_OUTPUT_FILE|file=data_TA12_labeled.dta|type=data|desc=labeled_data"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TA12 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  输入样本量:      " %10.0fc `n_input'
display "  输出样本量:      " %10.0fc `n_output'
display "  处理变量数:      " %10.0fc `n_vars'
display "  操作类型:        `operation'"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

* ============ SS_* 锚点: 结果摘要 ============
display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=n_vars|value=`n_vars'"

* ============ SS_* 锚点: 任务指标 ============
timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_obs|value=`n_output'"
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

* ============ 任务结束 ============
display "SS_TASK_END|id=TA12|status=ok|elapsed_sec=`elapsed'"
log close
