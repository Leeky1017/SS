* ==============================================================================
* SS_TEMPLATE: id=TT05  level=L2  module=T  title="Readability"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TT05_readability.csv type=table desc="Readability stats"
*   - data_TT05_read.dta type=data desc="Readability data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

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

display "SS_TASK_BEGIN|id=TT05|level=L2|title=Readability"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local text_var = "__TEXT_VAR__"

display ""
display ">>> 可读性分析参数:"
display "    文本变量: `text_var'"

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
display "SS_METRIC|name=n_input|value=`n_input'"
display "SS_STEP_END|step=S01_load_data|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S02_validate_inputs"

* ============ 变量检查 ============
capture confirm string variable `text_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm string variable|msg=text_var_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"

* ============ 计算可读性指标 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 计算可读性指标"
display "═══════════════════════════════════════════════════════════════════════════════"

* 字符数
generate int char_count = strlen(`text_var')

* 词数（以空格分隔）
generate int word_count = wordcount(`text_var')

* 句数（以.!?计数）
generate int sentence_count = 0
replace sentence_count = sentence_count + ///
    (strlen(`text_var') - strlen(subinstr(`text_var', ".", "", .)))
replace sentence_count = sentence_count + ///
    (strlen(`text_var') - strlen(subinstr(`text_var', "!", "", .)))
replace sentence_count = sentence_count + ///
    (strlen(`text_var') - strlen(subinstr(`text_var', "?", "", .)))
replace sentence_count = max(sentence_count, 1)

* 平均词长
generate double avg_word_length = char_count / max(word_count, 1)

* 平均句长
generate double avg_sentence_length = word_count / sentence_count

* 简单可读性得分（基于平均句长和词长）
generate double readability_score = 206.835 - 1.015 * avg_sentence_length - 84.6 * (avg_word_length / 5)
replace readability_score = max(0, min(100, readability_score))

label variable char_count "字符数"
label variable word_count "词数"
label variable sentence_count "句数"
label variable avg_word_length "平均词长"
label variable avg_sentence_length "平均句长"
label variable readability_score "可读性得分"

* ============ 统计结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 可读性统计"
display "═══════════════════════════════════════════════════════════════════════════════"

display ""
display ">>> 各指标统计:"

foreach var in char_count word_count sentence_count avg_word_length avg_sentence_length readability_score {
    quietly summarize `var'
    display "    `var': 均值=" %8.2f r(mean) ", SD=" %8.2f r(sd)
}

quietly summarize readability_score
local avg_readability = r(mean)
local sd_readability = r(sd)

display ""
display ">>> 可读性解读 (Flesch简化版):"
display "    90-100: 非常容易"
display "    60-90:  标准"
display "    30-60:  较难"
display "    0-30:   非常难"
display ""
display ">>> 平均可读性得分: " %6.1f `avg_readability'

if `avg_readability' >= 60 {
    display "    解读: 文本可读性良好"
}
else if `avg_readability' >= 30 {
    display "    解读: 文本可读性中等"
}
else {
    display "    解读: 文本较难阅读"
}

display "SS_METRIC|name=avg_readability|value=`avg_readability'"

quietly summarize word_count
local avg_words = r(mean)
display "SS_METRIC|name=avg_words|value=`avg_words'"

* 导出统计
preserve
clear
set obs 6
generate str30 metric = ""
generate double mean = .
generate double sd = .

replace metric = "字符数" in 1
replace metric = "词数" in 2
replace metric = "句数" in 3
replace metric = "平均词长" in 4
replace metric = "平均句长" in 5
replace metric = "可读性得分" in 6

restore
preserve

collapse (mean) mean_char=char_count mean_word=word_count mean_sent=sentence_count ///
         mean_wlen=avg_word_length mean_slen=avg_sentence_length mean_read=readability_score ///
         (sd) sd_char=char_count sd_word=word_count sd_sent=sentence_count ///
         sd_wlen=avg_word_length sd_slen=avg_sentence_length sd_read=readability_score

export delimited using "table_TT05_readability.csv", replace
display "SS_OUTPUT_FILE|file=table_TT05_readability.csv|type=table|desc=readability_stats"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT05_read.dta", replace
display "SS_OUTPUT_FILE|file=data_TT05_read.dta|type=data|desc=readability_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT05 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  文档数:          " %10.0fc `n_input'
display ""
display "  可读性指标:"
display "    平均词数:      " %10.1f `avg_words'
display "    可读性得分:    " %10.1f `avg_readability'
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=avg_readability|value=`avg_readability'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TT05|status=ok|elapsed_sec=`elapsed'"
log close
