# TI11_stpower — 生存分析样本量

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TI11 |
| **Slug** | stpower |
| **名称(中文)** | 生存分析样本量 |
| **Name(EN)** | Survival Power |
| **家族** | survival |
| **等级** | L1 |
| **版本** | 2.0.0 |

## 功能描述

Sample size and power calculation for survival studies

## 使用场景

- 关键词：survival, power, sample_size

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__ALPHA__` | number | 否 | Significance level |
| `__POWER__` | number | 否 | Target power |
| `__HR__` | number | 是 | Hazard ratio |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TI11_power.csv | table | Power analysis |
| data_TI11_power.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| stata | built-in | stpower command |

## 示例

```stata
* Template: TI11_stpower
* Script: tasks/do/TI11_stpower.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

