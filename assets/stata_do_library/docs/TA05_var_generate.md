# TA05_var_generate — 变量生成器

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TA05 |
| **Slug** | var_generate |
| **名称(中文)** | 变量生成器 |
| **Name(EN)** | Var Generate |
| **家族** | data_management |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Generate lag, difference, and growth rate variables for panel data

## 使用场景

- 关键词：lag, difference, growth_rate, panel, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__SOURCE_VARS__` | string | 是 | Source variables |
| `__ID_VAR__` | string | 是 | ID variable |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__LAG_PERIODS__` | string | 否 | Lag periods |
| `__DIFF_ORDER__` | integer | 否 | Difference order |
| `__GROWTH_TYPE__` | string | 否 | Growth type: pct/log |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TA05_newvar_summary.csv | table | New variable summary |
| data_TA05_generated.dta | data | Data with new variables |
| data_TA05_generated.csv | data | Data CSV with new variables |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | Panel commands |

## 示例

```stata
* Template: TA05_var_generate
* Script: assets/stata_do_library/do/TA05_var_generate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

