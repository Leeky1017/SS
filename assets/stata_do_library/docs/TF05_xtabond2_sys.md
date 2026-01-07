# TF05_xtabond2_sys — 系统GMM

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TF05 |
| **Slug** | xtabond2_sys |
| **名称(中文)** | 系统GMM |
| **Name(EN)** | System GMM |
| **家族** | panel_data |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

System GMM estimation for dynamic panels

## 使用场景

- 关键词：panel, gmm, dynamic, blundell-bond

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
| table_TF05_sysgmm.csv | table | System GMM results |
| data_TF05_sysgmm.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| xtabond2 | ssc | System GMM estimation |

## 示例

```stata
* Template: TF05_xtabond2_sys
* Script: assets/stata_do_library/do/TF05_xtabond2_sys.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

