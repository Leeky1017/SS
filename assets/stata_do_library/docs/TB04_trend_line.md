# TB04_trend_line — 时间趋势图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB04 |
| **Slug** | trend_line |
| **名称(中文)** | 时间趋势图 |
| **Name(EN)** | Trend Line |
| **家族** | descriptive_statistics |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Draw time series trend line plot

## 使用场景

- 关键词：trend, line, time-series, plot

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.dta | main_dataset | 是 |
| data.csv | main_dataset | 否 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__YVAR__` | string | 是 | Y variable |
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TB04_trend.png | figure | Trend line plot |
| data_TB04_trend.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | twoway line |

## 示例

```stata
* Template: TB04_trend_line
* Script: assets/stata_do_library/do/TB04_trend_line.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

