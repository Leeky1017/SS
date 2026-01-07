# TT01_text_clean — 文本清洗

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TT01 |
| **Slug** | text_clean |
| **名称(中文)** | 文本清洗 |
| **Name(EN)** | Text Cleaning |
| **家族** | text_analysis |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Clean text data including removing special characters, standardizing case, and removing stopwords

## 使用场景

- 关键词：text, cleaning, preprocessing

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TEXT_VAR__` | string | 是 | Text variable |
| `__LOWERCASE__` | string | 否 | Convert to lowercase: yes/no |
| `__REMOVE_PUNCT__` | string | 否 | Remove punctuation: yes/no |
| `__REMOVE_NUM__` | string | 否 | Remove numbers: yes/no |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TT01_clean_stats.csv | table | Cleaning statistics |
| data_TT01_clean.dta | data | Cleaned data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | String functions |

## 示例

```stata
* Template: TT01_text_clean
* Script: assets/stata_do_library/do/TT01_text_clean.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

