# TD09_elastic_net — 弹性网络

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TD09 |
| **Slug** | elastic_net |
| **名称(中文)** | 弹性网络 |
| **Name(EN)** | Elastic Net |
| **家族** | linear_regression |
| **等级** | L0 |
| **版本** | 2.0.0 |

## 功能描述

Elastic Net regression with L1+L2 regularization

## 使用场景

- 关键词：elastic-net, regularization, lasso, ridge

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | string | 是 | Independent variables |
| `__ALPHA__` | number | 是 | Mixing parameter (0-1) |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TD09_enet.csv | table | Elastic Net results |
| data_TD09_enet.dta | data | Data file |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | elasticnet command |

## 示例

```stata
* Template: TD09_elastic_net
* Script: assets/stata_do_library/do/TD09_elastic_net.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

