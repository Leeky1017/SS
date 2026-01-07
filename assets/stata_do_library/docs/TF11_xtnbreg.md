# TF11_xtnbreg — 面板负二项

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF11 |
| **Slug** | xtnbreg |
| **名称(中文)** | 面板负二项 |
| **Name(EN)** | XTNBREG |
| **家族** | panel_data |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Panel negative binomial for overdispersed count data

## 使用场景

- 关键词：panel, negative-binomial, count

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
| table_TF11_xtnb.csv | table | Panel NegBin results |
| data_TF11_xtnb.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtnbreg command |

## 示例

```stata
* Template: TF11_xtnbreg
* Script: assets/stata_do_library/do/TF11_xtnbreg.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

