# TK11_market_micro — 市场微观结构

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK11 |
| **Slug** | market_micro |
| **名称(中文)** | 市场微观结构 |
| **Name(EN)** | Market Microstructure |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Market microstructure analysis including bid-ask spread

## 使用场景

- 关键词：microstructure, spread, liquidity, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__BID_VAR__` | string | 是 | Bid price |
| `__ASK_VAR__` | string | 是 | Ask price |
| `__VOLUME_VAR__` | string | 否 | Volume |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK11_micro.dta | data | Output data |
| fig_TK11_spread_intraday.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK11_liquidity.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |
| table_TK11_spread_stats.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TK11_market_micro
* Script: assets/stata_do_library/do/TK11_market_micro.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

