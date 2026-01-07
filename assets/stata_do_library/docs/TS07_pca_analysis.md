# TS07_pca_analysis — 主成分分析

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TS07 |
| **Slug** | pca_analysis |
| **名称(中文)** | 主成分分析 |
| **Name(EN)** | PCA Analysis |
| **家族** | machine_learning |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Principal Component Analysis for dimensionality reduction

## 使用场景

- 关键词：pca, dimensionality_reduction, machine_learning

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VARS__` | list[string] | 是 | Analysis variables |
| `__N_COMPONENTS__` | integer | 否 | Number of components |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TS07_eigenvalues.csv | table | Eigenvalues |
| table_TS07_loadings.csv | table | Component loadings |
| fig_TS07_scree.png | graph | Scree plot |
| data_TS07_pca.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | pca command |

## 示例

```stata
* Template: TS07_pca_analysis
* Script: assets/stata_do_library/do/TS07_pca_analysis.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

