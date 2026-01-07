# TF04_xtscc — Driscoll-Kraay标准误

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF04 |
| **Slug** | xtscc |
| **名称(中文)** | Driscoll-Kraay标准误 |
| **Name(EN)** | XTSCC |
| **家族** | panel_data |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Driscoll-Kraay standard errors for panel data

## 使用场景

- 关键词：panel, driscoll-kraay, standard-error

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

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF04_xtscc.csv | table | XTSCC results |
| data_TF04_xtscc.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xtscc | ssc | Driscoll-Kraay SE |

## 示例

```stata
* Template: TF04_xtscc
* Script: assets/stata_do_library/do/TF04_xtscc.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

