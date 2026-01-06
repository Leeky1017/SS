# TM11_incidence_rate — 发病率

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM11 |
| **Slug** | incidence_rate |
| **名称(中文)** | 发病率 |
| **Name(EN)** | Incidence Rate |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Incidence rate and rate ratio calculation

## 使用场景

- 关键词：incidence, rate_ratio, epidemiology, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__EVENTS__` | string | 是 | Events |
| `__PERSON_TIME__` | string | 是 | Person-time |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TM11_ir.csv | table | IR results |
| data_TM11_ir.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | ir command |

## 示例

```stata
* Template: TM11_incidence_rate
* Script: tasks/do/TM11_incidence_rate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

