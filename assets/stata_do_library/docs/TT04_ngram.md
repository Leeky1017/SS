# TT04_ngram — N-gram分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TT04 |
| **Slug** | ngram |
| **名称(中文)** | N-gram分析 |
| **Name(EN)** | N-gram Analysis |
| **家族** | text_analysis |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Generate and analyze N-grams (word combinations)

## 使用场景

- 关键词：text, ngram, analysis

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TEXT_VAR__` | string | 是 | Text variable |
| `__N__` | integer | 否 | N value (default 2) |
| `__TOP_N__` | integer | 否 | Top N (default 30) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TT04_ngram.csv | table | N-gram frequency table |
| data_TT04_ngram.dta | data | N-gram data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | String functions |

## 示例

```stata
* Template: TT04_ngram
* Script: assets/stata_do_library/do/TT04_ngram.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

