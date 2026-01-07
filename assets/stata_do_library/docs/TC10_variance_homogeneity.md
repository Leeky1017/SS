# TC10_variance_homogeneity — 方差齐性检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TC10 |
| **Slug** | variance_homogeneity |
| **名称(中文)** | 方差齐性检验 |
| **Name(EN)** | Variance Homogeneity |
| **家族** | hypothesis_testing |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Variance homogeneity tests (Levene, Bartlett)

## 使用场景

- 关键词：variance, homogeneity, levene, bartlett

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__VAR__` | string | 是 | Test variable |
| `__GROUP_VAR__` | string | 是 | Group variable |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TC10_var.csv | table | Variance test results |
| data_TC10_var.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | robvar oneway |

## 示例

```stata
* Template: TC10_variance_homogeneity
* Script: assets/stata_do_library/do/TC10_variance_homogeneity.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

