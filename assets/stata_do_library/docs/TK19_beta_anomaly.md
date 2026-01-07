# TK19_beta_anomaly — Beta异象

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK19 |
| **Slug** | beta_anomaly |
| **名称(中文)** | Beta异象 |
| **Name(EN)** | Beta Anomaly |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Low beta anomaly analysis

## 使用场景

- 关键词：beta, anomaly, low_beta, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__MARKET_VAR__` | string | 是 | Market return |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK19_beta.dta | data | Output data |
| fig_TK19_beta_anomaly.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK19_bab_factor.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK19_beta_sort.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TK19_beta_anomaly
* Script: assets/stata_do_library/do/TK19_beta_anomaly.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

