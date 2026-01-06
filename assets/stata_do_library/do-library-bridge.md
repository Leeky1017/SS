# Do-Library-Bridge 实现设计与验收文档

**版本**: 1.0
**日期**: 2025-12-16
**状态**: 实施中

---

## 一、背景与问题清单

基于 `docs/do-library-bridge缺陷.md` 分析，当前系统存在以下问题：

### 1.1 架构断层
- **问题**：LLM 提示词仅包含 Family 级摘要，不含具体模板信息
- **影响**：LLM 知道有"因果推断"家族，但无法区分 TG02(PSM) 与 TG09(RDD)
- **验收标准**：LLM 输出的 `template_id` 必须属于候选模板集合

### 1.2 Token 效率问题
- **问题**：319个模板全量注入会消耗约15K tokens
- **影响**：成本增加、响应变慢、关键信息被稀释
- **验收标准**：提示词 token 数 ≤ 5K（分层策略）

### 1.3 Family 重复与规范化
- **问题**：存在重复归类（panel/panel_data, accounting/audit）
- **影响**：Family 选择模糊，无法精确定位
- **验收标准**：canonical family 映射 + aliases 向后兼容

### 1.4 关键词覆盖不足
- **问题**：缺少集中维护的 keywords/use_when 配置
- **影响**：Family 选择准确率低
- **验收标准**：每个 canonical family 有完整的 keywords/use_when

### 1.5 缺少兜底机制
- **问题**：第一阶段 Family 选择失败时无回退策略
- **影响**：请求直接失败或产生低质量结果
- **验收标准**：fallback families 自动扩展 + 结构化错误

---

## 二、设计方案：两阶段模板选择

### 2.1 流程概览

```
┌─────────────────────────────────────────────────────┐
│          第一阶段：Family 识别（~2K tokens）          │
│                                                     │
│  输入：用户需求 + 32个 Family 摘要                   │
│  输出：selected_families + maybe_families           │
│  JSON Schema 校验 + 失败分支处理                     │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│              动态模板加载 + 裁剪                      │
│                                                     │
│  selected + fallback → 候选模板详情                  │
│  应用 token 预算裁剪（topK + 相关性排序）             │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│         第二阶段：计划生成（~3K tokens）              │
│                                                     │
│  输入：用户需求 + 数据Profile + 裁剪后模板详情        │
│  输出：AnalysisPlan with template_id                │
│  template_id 必须属于候选模板集合                    │
└─────────────────────────────────────────────────────┘
```

### 2.2 Family 摘要结构

```python
@dataclass
class FamilySummaryForLLM:
    """用于 LLM 第一阶段的 Family 摘要"""
    id: str                    # canonical family id
    name: str                  # 中文名称
    count: int                 # 模板数量
    keywords: list[str]        # 关键词列表（用于匹配）
    use_when: str              # 使用场景描述
    aliases: list[str]         # 别名列表（向后兼容）
```

### 2.3 第一阶段 LLM 输出 Schema

```json
{
  "selected_families": [
    {"family_id": "causal_inference", "confidence": 0.9, "reason": "需要PSM匹配"},
    {"family_id": "panel_data", "confidence": 0.7, "reason": "数据为面板结构"}
  ],
  "maybe_families": [
    {"family_id": "regression", "confidence": 0.4, "reason": "可能需要回归分析"}
  ],
  "global_confidence": 0.85,
  "errors": []
}
```

### 2.4 Fallback 策略

```python
FALLBACK_MAP = {
    "causal_inference": ["panel_data", "regression"],
    "panel_data": ["causal_inference", "regression", "time_series"],
    "regression": ["linear_regression", "panel_data"],
    "time_series": ["panel_data", "finance"],
    # ...
}
```

### 2.5 Token 预算裁剪策略

1. **预算上限**：默认 3000 tokens for templates section
2. **裁剪方法**：
   - 按需求文本与模板 keywords/description 匹配度排序
   - 保留 topK（可配置，默认 30）
   - 输出裁剪报告（原候选数 → 裁剪后数 → 估计 token）

---

## 三、文件级改动清单

### 3.1 新增文件

| 文件 | 说明 |
|------|------|
| `config/family_config.json` | Family 配置（canonical mapping, aliases, keywords, use_when, fallbacks） |
| `tests/test_template_selector_v2.py` | TemplateSelector 测试 |
| `tests/test_planner_two_stage.py` | Planner 两阶段流程集成测试 |

### 3.2 修改文件

| 文件 | 修改内容 |
|------|----------|
| `domain/template_selector.py` | 重构：添加 FamilyRegistry, token 裁剪, 两阶段支持 |
| `domain/kernel_capability_manifest.py` | get_schema_summary() 仅输出 family summaries |
| `domain/planner.py` | 添加两阶段 LLM 流程 |
| `domain/schema_validator.py` | 添加 FamilySelectionSchema 校验 |

---

## 四、验收标准

### 4.1 功能验收

| 验收项 | 标准 | 测试方法 |
|--------|------|----------|
| Family 规范化 | alias 输入得到 canonical 结果 | `test_canonicalization` |
| Fallback 扩展 | 低置信时自动加入 fallback | `test_fallback_expansion` |
| Token 裁剪 | 候选模板 ≤ topK 且 ≤ 预算 | `test_budget_trimming` |
| 第一阶段 JSON 校验 | 输出符合 FamilySelectionSchema | `test_family_selection_schema` |
| 第二阶段 template_id | 属于候选模板集合 | `test_template_id_in_candidates` |
| 解析失败降级 | 进入 fallback 或结构化错误 | `test_parse_failure_fallback` |

### 4.2 性能验收

| 指标 | 当前值 | 目标值 |
|------|--------|--------|
| 提示词 Token 数（第一阶段） | N/A | ≤ 2K |
| 提示词 Token 数（第二阶段） | N/A | ≤ 3K |
| 总提示词 Token 数 | ~8K (无模板) / ~23K (全模板) | ≤ 5K (分层) |
| 模板选择准确率 | 无法选择 | 可精确选择 |

### 4.3 回归验收

- 现有 planner 测试全部通过
- 现有 template_summary 测试全部通过

---

## 五、风险与回滚点

### 5.1 风险

1. **LLM 第一阶段输出不稳定**：JSON 格式不一致或字段缺失
   - 缓解：严格 schema 校验 + 最多 2 次语义重试

2. **Family 选择准确率低**：关键词不足导致错选
   - 缓解：fallback 自动扩展 + 后续迭代优化 keywords

3. **Token 预算计算误差**：实际 token 超出预估
   - 缓解：保守估计（×1.5 安全系数）

### 5.2 回滚点

1. **配置回滚**：`config/family_config.json` 可独立回滚
2. **代码回滚**：保留原 `template_selector.py` 逻辑，通过 feature flag 切换
3. **流程回滚**：planner 可配置是否启用两阶段（`enable_two_stage_selection`）

---

## 六、实现步骤

### Step 1: 创建 family_config.json

定义 canonical family mapping, aliases, keywords, use_when, fallbacks

### Step 2: 重构 template_selector.py

- 添加 `FamilyRegistry` 类管理 family 配置
- 添加 `get_family_summaries()` 方法
- 添加 `get_fallback_families()` 方法
- 添加 `trim_by_budget()` 方法
- 添加 `estimate_tokens()` 方法

### Step 3: 修改 kernel_capability_manifest.py

- `get_schema_summary()` 仅返回 family summaries（不含全量模板）

### Step 4: 修改 planner.py

- 添加 `_build_family_selection_prompt()` 方法
- 添加 `_parse_family_selection_response()` 方法
- 添加 `_load_candidate_templates()` 方法
- 修改 `build_plan()` 实现两阶段流程

### Step 5: 添加测试

- `tests/test_template_selector_v2.py`
- `tests/test_planner_two_stage.py`

### Step 6: 性能基线

- 输出裁剪报告作为回归基线

---

*本文档为 do-library-bridge 实现的唯一设计与验收载体*
