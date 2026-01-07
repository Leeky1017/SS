# TU09_qq_plot — Q-Q图

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TU09 |
| **Slug** | qq_plot |
| **名称(中文)** | Q-Q图 |
| **Name(EN)** | Q-Q Plot |
| **家族** | visualization |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Plot Q-Q diagram for normality testing

## 使用场景

- 关键词：visualization, qq, normality

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Variable to test |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| fig_TU09_qq.png | graph | Q-Q plot |
| table_TU09_normality.csv | table | Normality test results |
| data_TU09_qq.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | qnorm command |

## 示例

```stata
* Template: TU09_qq_plot
* Script: assets/stata_do_library/do/TU09_qq_plot.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

