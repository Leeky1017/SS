# TF08_xttobit — 面板Tobit

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF08 |
| **Slug** | xttobit |
| **名称(中文)** | 面板Tobit |
| **Name(EN)** | XTTOBIT |
| **家族** | panel_data |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Panel Tobit model for censored data

## 使用场景

- 关键词：panel, tobit, censored

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__LL__` | number | 是 | Lower limit |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF08_xttobit.csv | table | Panel Tobit results |
| data_TF08_xttobit.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xttobit command |

## 示例

```stata
* Template: TF08_xttobit
* Script: assets/stata_do_library/do/TF08_xttobit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

