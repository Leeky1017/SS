# TH15_sspace — 状态空间模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH15 |
| **Slug** | sspace |
| **名称(中文)** | 状态空间模型 |
| **Name(EN)** | State Space Model |
| **家族** | time_series |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

State space model estimation

## 使用场景

- 关键词：state_space, kalman, time_series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TH15_sspace.csv | table | State space results |
| data_TH15_sspace.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

（无额外依赖）

## 示例

```stata
* Template: TH15_sspace
* Script: assets/stata_do_library/do/TH15_sspace.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

