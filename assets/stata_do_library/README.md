# tasks/ — 任务文档规范

> **版本**: 1.0  
> **更新日期**: 2024-12-16

---

## 目录用途

`tasks/` 目录用于存放：

1. **Do Library**：Stata 模板文件及其元数据
2. **一次性任务文档**：临时任务、调试记录、升级方案等
3. **门禁工具**：Lint 检查器、索引同步脚本

---

## 目录结构

```
tasks/
├── do/                        # Do 模板文件（628+）
│   ├── T01_desc_overview.do
│   ├── T02_basic_reg.do
│   └── ...
├── docs/                      # 模板文档
│   ├── T01_desc_overview.md
│   └── ...
├── fixtures/                  # 测试数据
│   ├── sample_panel.dta
│   └── ...
├── DO_LIBRARY_INDEX.json      # 机器可读索引
├── CAPABILITY_MANIFEST.json   # 能力清单
├── SS_DO_CONTRACT.md          # Do 文件硬契约（不可修改）
├── DO_LINT_RULES.py           # 门禁检查器
├── DO_AUDIT_REPORT.md         # 审计报告
└── README.md                  # 本文件
```

---

## 任务文档规范

### 文件命名

```
TASK_<简短描述>.md
```

示例：
- `TASK_upgrade_reghdfe.md`
- `TASK_fix_panel_detection.md`
- `TASK_add_survival_templates.md`

### 必需字段

每个任务文档必须包含：

```markdown
# TASK: <任务标题>

> **状态**: PENDING | IN_PROGRESS | DONE | BLOCKED  
> **创建日期**: YYYY-MM-DD  
> **完成日期**: YYYY-MM-DD（完成后填写）

## 目标

<1-3 句话描述任务目标>

## 背景

<为什么要做这个任务>

## 执行步骤

1. [ ] Step 1
2. [ ] Step 2
3. [ ] Step 3

## 验收标准

- [ ] Criterion 1
- [ ] Criterion 2

## 相关文件

- `path/to/file1.py`
- `path/to/file2.do`

## 备注

<可选：额外说明、风险、依赖等>
```

---

## 禁止写入 CLAUDE.md 的内容

以下内容 **必须** 写入 `tasks/` 目录下独立文件，**不得** 进入根目录 `CLAUDE.md`：

| 内容类型 | 示例 | 应放置位置 |
|----------|------|-----------|
| 一次性任务 | 升级某个模块 | `tasks/TASK_xxx.md` |
| 调试记录 | 某 bug 的排查过程 | `tasks/DEBUG_xxx.md` |
| 临时方案 | 紧急 hotfix | `tasks/HOTFIX_xxx.md` |
| 审计报告 | 代码审计结果 | `tasks/DO_AUDIT_REPORT.md` |
| 扩展计划 | 新模板规划 | `tasks/DO_LIBRARY_EXPANSION_PLAN.md` |

---

## Do Library 贡献指南

### 新增模板

1. **创建 do 文件**：`tasks/do/Txxx_<name>.do`
2. **满足硬契约**：参照 `SS_DO_CONTRACT.md`
3. **运行门禁**：
   ```bash
   python tasks/DO_LINT_RULES.py --file tasks/do/Txxx_<name>.do
   ```
4. **更新索引**：
   ```bash
   python scripts/sync_template_index.py
   ```
5. **添加文档**：`tasks/docs/Txxx_<name>.md`
6. **添加 fixture**（如需要）：`tasks/fixtures/`

### 模板升格流程

```
NEEDS_REWORK → PROD_READY
```

1. 修复 Lint 违规
2. 补充缺失锚点
3. 添加测试 fixture
4. 更新 `DO_LIBRARY_INDEX.json` 状态

---

## 门禁检查

```bash
# 检查单文件
python tasks/DO_LINT_RULES.py --file tasks/do/T04_merge_data.do

# 检查整个库
python tasks/DO_LINT_RULES.py --path tasks/do/

# 输出 JSON 报告
python tasks/DO_LINT_RULES.py --path tasks/do/ --output lint_report.json
```

### 退出码

| 码 | 含义 |
|----|------|
| 0 | 全部通过 |
| 1 | 存在 CRITICAL 违规（CI 必须失败） |
| 2 | 仅存在 WARNING（CI 可通过） |

---

## 索引同步

```bash
# 重建索引
python scripts/sync_template_index.py

# 生成模板文档
python scripts/generate_template_docs.py
```

---

*本目录是活跃工作区，请保持整洁。完成的任务文档可归档或删除。*
