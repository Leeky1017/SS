# TS12_gee_logit — GEE Logistic模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS12 |
| **Slug** | gee_logit |
| **名称(中文)** | GEE Logistic模型 |
| **Name(EN)** | GEE Logit |
| **家族** | gee |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

GEE for binary outcomes with logit link

## 使用场景

- 关键词：gee, logit, longitudinal, panel

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |
| `__PANELVAR__` | string | 是 | Panel variable |
| `__TIME_VAR__` | string | 是 | Time variable |
| `__CORR__` | string | 否 | Correlation structure |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TS12_geelogit.csv | table | GEE logit results |
| data_TS12_geelogit.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtgee command |

## 示例

```stata
* Template: TS12_gee_logit
* Script: assets/stata_do_library/do/TS12_gee_logit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

