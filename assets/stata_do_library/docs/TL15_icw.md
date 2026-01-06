# TL15_icw — 内部控制缺陷

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TL15 |
| **Slug** | icw |
| **名称(中文)** | 内部控制缺陷 |
| **Name(EN)** | Internal Control Weakness |
| **家族** | audit |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Internal control weakness determinants

## 使用场景

- 关键词：internal_control, icw, audit

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__ICW_VAR__` | string | 是 | ICW indicator |
| `__INDEPVARS__` | list[string] | 是 | Predictors |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TL15_icw.csv | table | ICW results |
| data_TL15_icw.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | logit command |

## 示例

```stata
* Template: TL15_icw
* Script: tasks/do/TL15_icw.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

