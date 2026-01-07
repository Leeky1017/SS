# TN09_direct_indirect — 直接间接效应

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TN09 |
| **Slug** | direct_indirect |
| **名称(中文)** | 直接间接效应 |
| **Name(EN)** | Direct Indirect Effects |
| **家族** | spatial |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Direct and indirect effects decomposition

## 使用场景

- 关键词：direct_effect, indirect_effect, spillover, spatial

## 输入

| 文件 | 角色 | 必需 |
|------|------|------|
| data.csv | main_dataset | 是 |

## 参数与占位符

| 占位符 | 类型 | 必需 | 说明 |
|--------|------|------|------|
| `__DEPVAR__` | string | 是 | Dependent variable |
| `__INDEPVARS__` | list[string] | 是 | Independent variables |

## 输出

| 文件 | 类型 | 说明 |
|------|------|------|
| table_TN09_effects.csv | table | Effects decomposition |
| data_TN09_effects.dta | data | Output data |
| result.log | log | Execution log |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| spregress | stata | Spatial effects |

## 示例

```stata
* Template: TN09_direct_indirect
* Script: assets/stata_do_library/do/TN09_direct_indirect.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

