# TB05_group_mean_trend — 分组均值趋势图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TB05 |
| **Slug** | group_mean_trend |
| **名称(中文)** | 分组均值趋势图 |
| **Name(EN)** | Group Mean Trend |
| **家族** | descriptive_statistics |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Draw group mean trend over time

## 使用场景

- 关键词：trend, group, mean, time-series

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__YVAR__` | string | 是 | Y variable |
| `__TIMEVAR__` | string | 是 | Time variable |
| `__GROUP_VAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TB05_group_trend.png | figure | Group mean trend plot |
| data_TB05_trend.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | collapse and twoway |

## 示例

```stata
* Template: TB05_group_mean_trend
* Script: assets/stata_do_library/do/TB05_group_mean_trend.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

