# TF13_xtfmb — Fama-MacBeth回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF13 |
| **Slug** | xtfmb |
| **名称(中文)** | Fama-MacBeth回归 |
| **Name(EN)** | XTFMB |
| **家族** | panel_data |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Fama-MacBeth two-step regression for finance panels

## 使用场景

- 关键词：panel, fama-macbeth, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF13_fmb.csv | table | Fama-MacBeth results |
| data_TF13_fmb.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xtfmb | ssc | Fama-MacBeth regression |

## 示例

```stata
* Template: TF13_xtfmb
* Script: assets/stata_do_library/do/TF13_xtfmb.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

