# TH14_rolling — 滚动窗口回归

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TH14 |
| **Slug** | rolling |
| **名称(中文)** | 滚动窗口回归 |
| **Name(EN)** | Rolling Regression |
| **家族** | time_series |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Rolling window regression

## 使用场景

- 关键词：rolling, time_varying, regression

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__WINDOW__` | number | 是 | Window size |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TH14_rolling.png | figure | Rolling plot |
| data_TH14_rolling.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| regress | built-in | Rolling regression (no SSC dependency) |

## 示例

```stata
* Template: TH14_rolling
* Script: assets/stata_do_library/do/TH14_rolling.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

