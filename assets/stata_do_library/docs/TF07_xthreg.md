# TF07_xthreg — 面板门槛回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF07 |
| **Slug** | xthreg |
| **名称(中文)** | 面板门槛回归 |
| **Name(EN)** | XTHREG |
| **家族** | panel_data |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Hansen panel threshold model

## 使用场景

- 关键词：panel, threshold, hansen

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__THRESHOLD_VAR__` | string | 是 | Threshold variable |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF07_threshold.csv | table | Threshold results |
| data_TF07_threshold.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xthreg | ssc | Panel threshold model |

## 示例

```stata
* Template: TF07_xthreg
* Script: tasks/do/TF07_xthreg.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

