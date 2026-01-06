# TK01_capm_estimate — CAPM估计

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK01 |
| **Slug** | capm_estimate |
| **名称(中文)** | CAPM估计 |
| **Name(EN)** | CAPM Estimate |
| **家族** | finance |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Capital Asset Pricing Model estimation with rolling beta

## 使用场景

- 关键词：capm, beta, finance, asset_pricing

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RETURN_VAR__` | string | 是 | Return variable |
| `__MARKET_VAR__` | string | 是 | Market return |
| `__RF_VAR__` | string | 否 | Risk-free rate |
| `__STOCK_ID__` | string | 是 | Stock identifier |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__WINDOW__` | integer | 否 | Rolling window |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TK01_capm_result.csv | table | CAPM results |
| table_TK01_rolling_beta.csv | table | Rolling beta |
| fig_TK01_sml.png | graph | SML plot |
| data_TK01_capm.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | regress command |

## 示例

```stata
* Template: TK01_capm_estimate
* Script: tasks/do/TK01_capm_estimate.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

