# TT05_readability — 可读性分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TT05 |
| **Slug** | readability |
| **名称(中文)** | 可读性分析 |
| **Name(EN)** | Readability Analysis |
| **家族** | text_analysis |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Calculate text readability metrics including word count, sentence count, and average lengths

## 使用场景

- 关键词：text, readability, analysis

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__TEXT_VAR__` | string | 是 | Text variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TT05_readability.csv | table | Readability statistics |
| data_TT05_read.dta | data | Readability data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | String functions |

## 示例

```stata
* Template: TT05_readability
* Script: assets/stata_do_library/do/TT05_readability.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

