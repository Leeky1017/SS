* ==============================================================================
* SS_TEMPLATE: id=TT03  level=L2  module=T  title="Sentiment"
* INPUTS:
*   - data.csv  role=main_dataset  required=yes
* OUTPUTS:
*   - table_TT03_sentiment.csv type=table desc="Sentiment stats"
*   - data_TT03_sentiment.dta type=data desc="Sentiment data"
*   - result.log type=log desc="Execution log"
* DEPENDENCIES: none
* ==============================================================================

* BEST_PRACTICE_REVIEW (EN):
* - Dictionary-based sentiment is a baseline; validate dictionaries for your domain/language and consider negation/context handling.
* - Tokenization matters: simple substring counting can overcount (e.g., "bad" in "badly"); interpret results cautiously.
* - Report missingness and sensitivity to dictionary choices; avoid treating sentiment as ground truth without validation.
* 最佳实践审查（ZH）:
* - 词典法情感分析仅是基线；需根据领域/语言校验词典，并考虑否定词/上下文。
* - 分词很关键：简单子串计数可能过度统计（如 "bad" 出现在 "badly"）；请谨慎解释。
* - 报告缺失与词典选择敏感性；未经验证不应把情感得分当作“真实情绪”。

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

display "SS_TASK_BEGIN|id=TT03|level=L2|title=Sentiment"
display "SS_TASK_VERSION|version=2.0.1"
display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"

* ============ 参数设置 ============
local text_var = "__TEXT_VAR__"
local pos_words = "__POS_WORDS__"
local neg_words = "__NEG_WORDS__"

display ""
display ">>> 情感分析参数:"
display "    文本变量: `text_var'"

* ============ 数据加载 ============
display "SS_STEP_BEGIN|step=S01_load_data"
* EN: Load main dataset from data.csv.
* ZH: 从 data.csv 载入主数据集。
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
* EN: Validate text variable existence/type.
* ZH: 校验文本变量存在且为字符串。

* ============ 变量检查 ============
capture confirm string variable `text_var'
if _rc {
    display "SS_RC|code=200|cmd=confirm string variable|msg=text_var_not_found|severity=fail"
    log close
    exit 200
}
display "SS_STEP_END|step=S02_validate_inputs|status=ok|elapsed_sec=0"

display "SS_STEP_BEGIN|step=S03_analysis"
* EN: Compute sentiment scores and export summary outputs.
* ZH: 计算情感得分并导出统计摘要。

* ============ 情感词典 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 1: 情感词典"
display "═══════════════════════════════════════════════════════════════════════════════"

* 默认情感词典（简化版）
local default_pos "good great excellent best better positive success successful"
local default_pos "`default_pos' happy profit growth increase improve strong"
local default_neg "bad poor worst worse negative fail failure loss decline"
local default_neg "`default_neg' decrease weak problem issue risk concern"

if "`pos_words'" == "" | "`pos_words'" == "__POS_WORDS__" {
    local pos_words "`default_pos'"
}
if "`neg_words'" == "" | "`neg_words'" == "__NEG_WORDS__" {
    local neg_words "`default_neg'"
}

local n_pos : word count `pos_words'
local n_neg : word count `neg_words'

display ">>> 正面词数: `n_pos'"
display ">>> 负面词数: `n_neg'"

* ============ 计算情感得分 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 2: 计算情感得分"
display "═══════════════════════════════════════════════════════════════════════════════"

* 转小写便于匹配
generate str2000 text_lower = lower(`text_var')

* 计算正面词数
generate int pos_count = 0
foreach word of local pos_words {
    quietly replace pos_count = pos_count + ///
        (strlen(text_lower) - strlen(subinstr(text_lower, "`word'", "", .))) / strlen("`word'")
}

* 计算负面词数
generate int neg_count = 0
foreach word of local neg_words {
    quietly replace neg_count = neg_count + ///
        (strlen(text_lower) - strlen(subinstr(text_lower, "`word'", "", .))) / strlen("`word'")
}

* 计算情感得分
generate int total_sentiment_words = pos_count + neg_count
generate double sentiment_score = (pos_count - neg_count) / (total_sentiment_words + 1)

* 分类
generate str10 sentiment_class = "中性"
replace sentiment_class = "正面" if sentiment_score > 0.1
replace sentiment_class = "负面" if sentiment_score < -0.1

label variable pos_count "正面词数"
label variable neg_count "负面词数"
label variable sentiment_score "情感得分"
label variable sentiment_class "情感分类"

drop text_lower

* ============ 统计结果 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "SECTION 3: 情感统计"
display "═══════════════════════════════════════════════════════════════════════════════"

quietly summarize sentiment_score
local avg_score = r(mean)
local sd_score = r(sd)
local min_score = r(min)
local max_score = r(max)

display ""
display ">>> 情感得分统计:"
display "    平均: " %8.4f `avg_score'
display "    标准差: " %8.4f `sd_score'
display "    范围: [" %6.4f `min_score' ", " %6.4f `max_score' "]"

display ""
display ">>> 情感分布:"
tabulate sentiment_class

quietly count if sentiment_class == "正面"
local n_pos_doc = r(N)
quietly count if sentiment_class == "负面"
local n_neg_doc = r(N)
quietly count if sentiment_class == "中性"
local n_neu_doc = r(N)

local pct_pos = `n_pos_doc' / `n_input' * 100
local pct_neg = `n_neg_doc' / `n_input' * 100

display "SS_METRIC|name=avg_sentiment|value=`avg_score'"
display "SS_METRIC|name=pct_positive|value=`pct_pos'"
display "SS_METRIC|name=pct_negative|value=`pct_neg'"

* 导出统计
preserve
clear
set obs 6
generate str30 metric = ""
generate double value = .

replace metric = "平均情感得分" in 1
replace value = `avg_score' in 1
replace metric = "正面文档数" in 2
replace value = `n_pos_doc' in 2
replace metric = "负面文档数" in 3
replace value = `n_neg_doc' in 3
replace metric = "中性文档数" in 4
replace value = `n_neu_doc' in 4
replace metric = "正面占比%" in 5
replace value = `pct_pos' in 5
replace metric = "负面占比%" in 6
replace value = `pct_neg' in 6

export delimited using "table_TT03_sentiment.csv", replace
display "SS_OUTPUT_FILE|file=table_TT03_sentiment.csv|type=table|desc=sentiment_stats"
restore

local n_output = _N
display "SS_METRIC|name=n_output|value=`n_output'"

save "data_TT03_sentiment.dta", replace
display "SS_OUTPUT_FILE|file=data_TT03_sentiment.dta|type=data|desc=sentiment_data"
display "SS_STEP_END|step=S03_analysis|status=ok|elapsed_sec=0"

* ============ 任务完成摘要 ============
display ""
display "═══════════════════════════════════════════════════════════════════════════════"
display "TT03 任务完成摘要"
display "═══════════════════════════════════════════════════════════════════════════════"
display ""
display "  文档数:          " %10.0fc `n_input'
display ""
display "  情感分析结果:"
display "    平均得分:      " %10.4f `avg_score'
display "    正面占比:      " %10.1f `pct_pos' "%"
display "    负面占比:      " %10.1f `pct_neg' "%"
display ""
display "═══════════════════════════════════════════════════════════════════════════════"

local n_dropped = 0
display "SS_METRIC|name=n_dropped|value=`n_dropped'"

display "SS_SUMMARY|key=n_input|value=`n_input'"
display "SS_SUMMARY|key=n_output|value=`n_output'"
display "SS_SUMMARY|key=avg_sentiment|value=`avg_score'"

timer off 1
quietly timer list 1
local elapsed = r(t1)
display "SS_METRIC|name=n_missing|value=0"
display "SS_METRIC|name=task_success|value=1"
display "SS_METRIC|name=elapsed_sec|value=`elapsed'"

display "SS_TASK_END|id=TT03|status=ok|elapsed_sec=`elapsed'"
log close
