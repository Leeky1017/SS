# TT02_word_freq — 词频统计

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TT02 |
| **Slug** | word_freq |
| **名称(中文)** | 词频统计 |
| **Name(EN)** | Word Frequency |
| **家族** | text_analysis |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Calculate word frequencies and generate word frequency tables

## 使用场景

- 关键词：text, word_frequency, analysis

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TEXT_VAR__` | string | 是 | Text variable |
| `__TOP_N__` | integer | 否 | Top N words (default 50) |
| `__MIN_FREQ__` | integer | 否 | Minimum frequency (default 2) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TT02_word_freq.csv | table | Word frequency table |
| data_TT02_freq.dta | data | Frequency data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | String functions |

## 示例

```stata
* Template: TT02_word_freq
* Script: tasks/do/TT02_word_freq.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

