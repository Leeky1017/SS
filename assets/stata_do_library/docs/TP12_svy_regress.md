# TP12_svy_regress — 调查回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TP12 |
| **Slug** | svy_regress |
| **名称(中文)** | 调查回归 |
| **Name(EN)** | Survey Regression |
| **家族** | survey |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Survey-weighted regression

## 使用场景

- 关键词：survey, regression, weighted

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__WEIGHT__` | string | 是 | Survey weight |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TP12_svy.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TP12_svyreg.csv | table | Survey regression results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | svy regress command |

## 示例

```stata
* Template: TP12_svy_regress
* Script: assets/stata_do_library/do/TP12_svy_regress.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

