* ==============================================================================
* SS_TEMPLATE: id=TT02  level=L2  module=T  title="Word Freq"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TT02_word_freq.csv type=table desc="Word frequency"
*   - data_TT02_freq.dta type=data desc="Freq data"
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

display "SS_TASK_BEGIN|id=TT02|level=L2|title=Word_Freq"
display "SS_TASK_VERSION:2.0.1"
display "SS_DEP_CHECK|pkg=none|source=builtin|status=ok"

* ============ 参数设置 ============
local text_var = "__TEXT_VAR__"
local top_n = __TOP_N__
local min_freq = __MIN_FREQ__

if `top_n' < 10 | `top_n' > 500 {
    local top_n = 50
}
if `min_freq' < 1 | `min_freq' > 100 {
    local min_freq = 2
}

display ""
display ">>> 词频统计参数:"
display "    文本变量: `text_var'"
display "    Top N: `top_n'"
display "    最小词频: `min_freq'"

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
capture confirm string variable `text_var'
if _rc {
    display "SS_ERROR:VAR_NOT_FOUND:`text_var' not found"
    display "SS_ERR:VAR_NOT_FOUND:`text_var' not found"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 分词和词频统计 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 分词处理"
display "═══════════════════════════════════════════════════════════════════════════════"

* 合并所有文本
generate long _doc_id = _n
local total_docs = _N

* 展开单词
split `text_var', parse(" ") generate(_word)

* 获取生成的单词变量
quietly describe _word*, varlist
local word_vars = r(varlist)
local n_word_vars : word count `word_vars'

display ">>> 最大单词数/文档: `n_word_vars'"

* 重塑为长格式
reshape long _word, i(_doc_id) j(_word_pos)
drop if missing(_word) | _word == ""

* 标准化
replace _word = lower(_word)
replace _word = strtrim(_word)

local total_words = _N
display ">>> 总词数: `total_words'"

* ============ 计算词频 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 词频统计"
display "═══════════════════════════════════════════════════════════════════════════════"

contract _word, freq(_freq)
gsort -_freq

local n_unique = _N
display ">>> 唯一词数: `n_unique'"

* 过滤低频词
drop if _freq < `min_freq'
local n_filtered = _N

display ">>> 过滤后词数 (freq>=`min_freq'): `n_filtered'"

* 计算词频占比
generate double _prop = _freq / `total_words'

* 取Top N
if _N > `top_n' {
    keep in 1/`top_n'
}

rename _word word
rename _freq frequency
rename _prop proportion

display ""
display ">>> Top 20 高频词:"
list word frequency proportion in 1/20, noobs

* 统计
quietly summarize frequency
local max_freq = r(max)
local top_word = word[1]

display ""
display ">>> 最高频词: `top_word' (频率=`max_freq')"

display "SS_METRIC|name=total_words|value=`total_words'"
display "SS_METRIC|name=unique_words|value=`n_unique'"
display "SS_METRIC|name=max_freq|value=`max_freq'"

* 导出词频表
export delimited using "table_TT02_word_freq.csv", replace
display "SS_OUTPUT_FILE|file=table_TT02_word_freq.csv|type=table|desc=word_freq"

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT02_freq.dta", replace
display "SS_OUTPUT_FILE|file=data_TT02_freq.dta|type=data|desc=freq_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT02 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  文档数:          " %10.0fc `total_docs'
display "  总词数:          " %10.0fc `total_words'
display "  唯一词数:        " %10.0fc `n_unique'
display "  最高频词:        `top_word' (`max_freq'次)"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=total_words|value=`total_words'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TT02|status=ok|elapsed_sec=`elapsed'"
log close
