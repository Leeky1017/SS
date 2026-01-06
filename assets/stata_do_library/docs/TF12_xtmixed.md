# TF12_xtmixed — 混合效应模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF12 |
| **Slug** | xtmixed |
| **名称(中文)** | 混合效应模型 |
| **Name(EN)** | XTMIXED |
| **家族** | panel_data |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Mixed effects model with random coefficients

## 使用场景

- 关键词：panel, mixed-effects, random-coefficients

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

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF12_mixed.csv | table | Mixed effects results |
| data_TF12_mixed.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | mixed command |

## 示例

```stata
* Template: TF12_xtmixed
* Script: tasks/do/TF12_xtmixed.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

