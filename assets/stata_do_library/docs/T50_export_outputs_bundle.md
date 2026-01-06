# T50_export_outputs_bundle — 输出文件打包（Export Outputs Bundle）

## 任务元信息

| 属性 | 值 |
|------|-----|
| **Task ID** | T50_export_outputs_bundle |
| **任务名称** | 输出文件打包 |
| **任务族** | J - 报告与打包 |
| **难度级别** | basic |
| **数据结构** | any |
| **金融场景适用** | ✓ 是 |

## 任务摘要

将当前job目录下的分析输出文件整理到`outputs/`子目录，便于Python层打包下载。**分析流程的收尾步骤**。

## 适用场景

### 场景 1：结果交付
- **目的**：整理分析结果供下载
- **方法**：文件打包
- **应用**：项目交付

### 场景 2：归档保存
- **目的**：保存分析输出
- **方法**：统一归档
- **应用**：项目归档

### 场景 3：批量任务
- **目的**：批量任务后收集输出
- **方法**：自动化打包
- **应用**：流水线末端

## 功能说明

### 处理的文件类型

| 类型 | 扩展名 | 说明 |
|------|--------|------|
| **表格数据** | `.csv` | 排除data.csv |
| **Stata数据** | `.dta` | 中间/结果数据 |
| **PNG图形** | `.png` | 主要图形格式 |
| **PDF图形** | `.pdf` | 高质量图形 |
| **EPS图形** | `.eps` | 矢量图形 |

### 输出目录结构

```
outputs/
├── manifest.txt            # 文件清单
├── table_*.csv             # 表格文件
├── fig_*.png               # 图形文件
└── *.dta                   # 数据文件
```

## 输入与占位符说明

此任务无需占位符，自动处理当前目录下的所有输出文件。

## 输出文件清单与 Schema

### 0. result.log

任务执行日志，包含文件复制过程和打包统计。

### 1. outputs/manifest.txt

文件清单（文本格式）。

包含：
- 生成时间
- Stata版本
- 按类型分类的文件列表
- 文件统计

## 上层 JSON 配置示例

```json
{
  "task_id": "T50_export_outputs_bundle",
  "description": "打包所有分析输出"
}
```

## Python层集成

```python
import shutil
import os

# 打包为ZIP
shutil.make_archive('results', 'zip', 'outputs')

# 或使用zipfile模块
import zipfile
with zipfile.ZipFile('results.zip', 'w') as zipf:
    for root, dirs, files in os.walk('outputs'):
        for file in files:
            zipf.write(os.path.join(root, file))
```

## 常见坑与建议

### 1. 文件覆盖
- **问题**：同名文件被覆盖
- **建议**：确保文件命名唯一

### 2. 大文件
- **问题**：DTA文件可能很大
- **建议**：考虑压缩或选择性打包

### 3. 权限问题
- **问题**：目录创建失败
- **建议**：检查目录权限

## 与其他任务的关系

| 相关任务 | 关系说明 |
|----------|----------|
| T49_auto_analysis_report | 生成报告后打包 |
| 所有任务 | 作为收尾步骤 |

## 技术说明

- **Stata 版本**：18.0+
- **外部依赖**：无，仅使用 Stata 官方命令
- **关键命令**：`mkdir`, `copy`, `file open`, `file write`, `file close`
- **退出码**：错误时统一返回 200
