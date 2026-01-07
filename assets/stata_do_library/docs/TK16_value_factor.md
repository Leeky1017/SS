# TK16_value_factor — 价值因子

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK16 |
| **Slug** | value_factor |
| **名称(中文)** | 价值因子 |
| **Name(EN)** | Value Factor |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Value factor construction (B/M, E/P)

## 使用场景

- 关键词：value, factor, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__BM_VAR__` | string | 是 | Book-to-market |
| `__EP_VAR__` | string | 否 | Earnings-to-price |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK16_value.dta | data | Output data |
| fig_TK16_value.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK16_factor.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK16_value.csv | table | Value factor results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TK16_value_factor
* Script: assets/stata_do_library/do/TK16_value_factor.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

