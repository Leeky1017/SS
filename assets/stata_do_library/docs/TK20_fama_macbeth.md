# TK20_fama_macbeth — Fama-MacBeth回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK20 |
| **Slug** | fama_macbeth |
| **名称(中文)** | Fama-MacBeth回归 |
| **Name(EN)** | Fama-MacBeth |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Fama-MacBeth two-stage regression

## 使用场景

- 关键词：fama_macbeth, cross_section, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__INDEPVARS__` | list[string] | 是 | Characteristics |
| `__TIME_VAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK20_fm.dta | data | Output data |
| fig_TK20_gamma_ts.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK20_fm_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK20_time_series.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TK20_fama_macbeth
* Script: assets/stata_do_library/do/TK20_fama_macbeth.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

