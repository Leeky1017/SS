# TE03_tobit — Tobit模型

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TE03 |
| **Slug** | tobit |
| **名称(中文)** | Tobit模型 |
| **Name(EN)** | Tobit |
| **家族** | limited_dependent |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Tobit model for censored/truncated data

## 使用场景

- 关键词：tobit, censored, truncated

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__LL__` | number | 是 | Lower limit |
| `__UL__` | number | 是 | Upper limit |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TE03_tobit.csv | table | Tobit results |
| data_TE03_tobit.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | tobit command |

## 示例

```stata
* Template: TE03_tobit
* Script: assets/stata_do_library/do/TE03_tobit.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

