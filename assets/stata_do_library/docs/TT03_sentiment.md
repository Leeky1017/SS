# TT03_sentiment — 情感分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TT03 |
| **Slug** | sentiment |
| **名称(中文)** | 情感分析 |
| **Name(EN)** | Sentiment Analysis |
| **家族** | text_analysis |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Dictionary-based sentiment analysis calculating text sentiment scores

## 使用场景

- 关键词：text, sentiment, analysis

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TEXT_VAR__` | string | 是 | Text variable |
| `__POS_WORDS__` | string | 否 | Positive words (comma-separated) |
| `__NEG_WORDS__` | string | 否 | Negative words (comma-separated) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TT03_sentiment.csv | table | Sentiment statistics |
| data_TT03_sentiment.dta | data | Sentiment data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | String functions |

## 示例

```stata
* Template: TT03_sentiment
* Script: tasks/do/TT03_sentiment.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

