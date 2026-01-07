# TF06_xtabond — 差分GMM

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF06 |
| **Slug** | xtabond |
| **名称(中文)** | 差分GMM |
| **Name(EN)** | Diff GMM |
| **家族** | panel_data |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Difference GMM estimation for dynamic panels

## 使用场景

- 关键词：panel, gmm, dynamic, arellano-bond

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
| `__TIMEVAR__` | string | 是 | Time variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TF06_diffgmm.csv | table | Diff GMM results |
| data_TF06_diffgmm.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | xtabond command |

## 示例

```stata
* Template: TF06_xtabond
* Script: assets/stata_do_library/do/TF06_xtabond.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

