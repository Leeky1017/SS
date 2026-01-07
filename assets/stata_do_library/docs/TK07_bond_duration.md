# TK07_bond_duration — 债券久期

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TK07 |
| **Slug** | bond_duration |
| **名称(中文)** | 债券久期 |
| **Name(EN)** | Bond Duration |
| **家族** | finance |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Bond duration and convexity calculation

## 使用场景

- 关键词：bond, duration, convexity, finance

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__COUPON__` | number | 是 | Coupon rate |
| `__MATURITY__` | integer | 是 | Years to maturity |
| `__YTM__` | number | 是 | Yield to maturity |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| data_TK07_bond.dta | data | Output data |
| fig_TK07_price_yield.png | graph | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TK07_duration.csv | table | Duration results |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | calculations |

## 示例

```stata
* Template: TK07_bond_duration
* Script: assets/stata_do_library/do/TK07_bond_duration.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

