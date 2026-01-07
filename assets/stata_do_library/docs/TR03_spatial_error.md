# TR03_spatial_error — 空间误差

## 任务元信息

| 属性 | 值 |
|------|-----|
| **模板ID** | TR03 |
| **Slug** | spatial_error |
| **名称(中文)** | 空间误差 |
| **Name(EN)** | Spatial Error |
| **家族** | spatial |
| **等级** | L2 |
| **版本** | 2.0.0 |

## 功能描述

Spatial error model (SEM)

## 使用场景

- 关键词：spatial_error, sem, spatial

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
| data_TR03_sem.dta | data | Auto-synced from SS_OUTPUT_FILE anchors |
| result.log | log | Execution log |
| table_TR03_sem_result.csv | table | Auto-synced from SS_OUTPUT_FILE anchors |

## 依赖

| 包/命令 | 来源 | 用途 |
|---------|------|------|
| spregress | stata | Spatial regression |

## 示例

```stata
* Template: TR03_spatial_error
* Script: assets/stata_do_library/do/TR03_spatial_error.do
* 将占位符替换为你的变量名/参数，然后交由执行器运行。
```

