# TG12_rdd_density — RDD密度检验

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TG12 |
| **Slug** | rdd_density |
| **名称(中文)** | RDD密度检验 |
| **Name(EN)** | RDD Density |
| **家族** | causal_inference |
| **等级** | L1 |
| **版本** | 2.1.0 |

## 功能描述

RDD manipulation test via density

## 使用场景

- 关键词：rdd, density, manipulation, causal

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__RUNNING_VAR__` | string | 是 | Running variable |
| `__CUTOFF__` | number | 是 | Cutoff value |
| `__METHOD__` | string | 否 | Test method |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TG12_density_test.csv | table | Density test results |
| fig_TG12_density_plot.png | figure | Density plot |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| rddensity | ssc | RDD density test |
## 示例

```stata
* Template: TG12_rdd_density
* Script: assets/stata_do_library/do/TG12_rdd_density.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

