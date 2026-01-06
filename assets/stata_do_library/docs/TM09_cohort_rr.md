# TM09_cohort_rr — 队列研究相对危险度

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TM09 |
| **Slug** | cohort_rr |
| **名称(中文)** | 队列研究相对危险度 |
| **Name(EN)** | Cohort RR |
| **家族** | medical |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Cohort study relative risk analysis

## 使用场景

- 关键词：cohort, relative_risk, epidemiology, medical

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__OUTCOME__` | string | 是 | Outcome |
| `__EXPOSURE__` | string | 是 | Exposure |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TM09_rr.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TM09_rr.csv | table | RR results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | cs command |

## 示例

```stata
* Template: TM09_cohort_rr
* Script: tasks/do/TM09_cohort_rr.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

