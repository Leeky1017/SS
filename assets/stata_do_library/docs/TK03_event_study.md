# TK03_event_study — 事件研究

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK03 |
| **Slug** | event_study |
| **名称(中文)** | 事件研究 |
| **Name(EN)** | Event Study |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Event study methodology for abnormal returns

## 使用场景

- 关键词：event_study, car, abnormal_returns, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__EVENT_DATE__` | string | 是 | Event date variable |
| `__WINDOW_PRE__` | integer | 否 | Pre-event window |
| `__WINDOW_POST__` | integer | 否 | Post-event window |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK03_event.dta | data | Output data |
| fig_TK03_car_plot.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK03_car_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK03_daily_ar.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TK03_event_study
* Script: tasks/do/TK03_event_study.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

