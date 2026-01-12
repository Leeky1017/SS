# SS 测试战略（用户中心）

目标：把测试从“函数正确”提升到“用户链路正确”。单元测试继续作为基础，但新增用户旅程、并发、压力与混沌工程层，用真实操作序列与极端环境约束系统行为；并把生产监控反馈纳入闭环。

## 问题陈述

传统“只做单元测试”的盲区：
- **自说自话**：用例来自开发者想象的理想流程，不反映真实用户操作序列。
- **序列随机性缺失**：函数单测覆盖了分支，但缺少“用户随意点/刷新/重试”的序列验证。
- **网络与并发失明**：假设网络完美、单用户；忽视超时、重试、竞态冲突。
- **可预测性陷阱**：覆盖边界值但缺少黑天鹅场景（磁盘满、权限不足、依赖不可用）。

## 战略四层：Unit → User Journey → Concurrency → Stress/Chaos → Production

### 1) 单元层（Unit）

目标：确保模块级行为正确、快速反馈、可重复。

建议强化点：
- 参数化覆盖边界值（空字符串、极值、特殊字符）。
- 模拟外部依赖异常（LLM 超时、网络断开）并验证错误路径不 silent。

### 2) 场景层（User Journey）

目标：验证真实用户操作序列的端到端状态一致性、幂等性与可恢复性。

用户场景（A–D）：
- **A：完整分析链路（正常流）**：上传数据 → 预览 → 修改映射 → 输入分析需求 → 多次 Preview → 提交 Job → 轮询 → 下载结果。  
  验证：状态是否跨步骤保留、参数是否正确传递、失败是否可恢复。  
  位置：`tests/user_journeys/test_analysis_complete_flow.py`
- **B：快速修改-重试循环**：Preview #1 → 改参数 → Preview #2 → … → 最后提交。  
  验证：草稿状态更新、旧 preview 清理、资源泄漏风险。  
  位置：`tests/user_journeys/test_draft_modification_loop.py`
- **C：页面刷新/网络抖动恢复**：上传中刷新 → 继续上传；执行中断网 → 重新查询 → 继续等待。  
  验证：幂等、状态恢复、重复提交防护。  
  位置：`tests/user_journeys/test_resilience_page_reload.py`
- **D：快速点击（重复提交）**：网络延迟下连续点提交 3 次。  
  验证：防重复、并发安全、错误提示一致。  
  位置：`tests/user_journeys/test_duplicate_submission.py`

### 3) 并发层（Concurrency）

目标：多用户/多 worker 并发操作时的一致性与原子性，捕获竞态 bug。

并发场景（1–4）：
- **1：多用户同时修改同一 Job**：读-改-写冲突与覆盖策略（Last-Write-Wins / 冲突提示 / 乐观锁）。  
  位置：`tests/concurrent/test_job_concurrent_write.py`
- **2：Worker 执行 Job 的同时用户查询状态**：可见性与一致性（返回最新进度而非陈旧数据）。  
  位置：`tests/concurrent/test_job_state_visibility.py`
- **3：多 Worker 处理同一队列**：无重复、无遗漏、无死锁、分发公平。  
  位置：`tests/concurrent/test_multi_worker_fairness.py`
- **4：磁盘存储竞态**：`save()` 与 `load()` 并发下的原子写保证（`tempfile + os.replace`）。  
  位置：`tests/concurrent/test_atomic_file_operations.py`

### 4) 压力层（Stress）

目标：在高并发、长时间运行、边界数据量下验证性能与资源稳定性。

压力场景（1–4）：
- **1：高并发负载**：100 用户上传 + 50 Job 执行 + 200 状态查询，关注 p99/错误率/资源占用。  
  位置：`tests/stress/test_load_100_concurrent_users.py`
- **2：24h 稳定性**：周期性任务持续 24 小时，关注泄漏与日志膨胀。  
  位置：`tests/stress/test_24h_stability.py`
- **3：资源耗尽（与混沌工程联动）**：磁盘满、内存不足、权限丢失、LLM 长期不可用。  
  位置：`tests/chaos/test_disk_full_recovery.py`, `tests/chaos/test_llm_timeout_fallback.py`
- **4：边界数据量**：超大数据集/超长输入/超多列，关注处理时间、内存与错误提示。  
  位置：`tests/stress/test_large_dataset_handling.py`

### 5) 混沌工程（Chaos）

目标：在极端条件下仍能给出清晰错误、避免数据损坏、并留下可审计证据。

混沌场景（来自策略文档的资源耗尽项）：
- 磁盘满（`No space left on device`）保存失败的处理与自动清理策略
- OOM/内存不足时的降级与错误呈现
- 文件权限丢失/不可写时的恢复或明确告知
- LLM 长期不可用（超时/断网）时的 fallback 或明确失败

### 6) 生产层（Monitoring）

目标：把生产日志/指标当作测试输入源：高频失败路径优先补齐测试；同时用测试验证监控是否正确。

## 测试目录结构（建议）

```text
tests/
├── conftest.py
├── fixtures/
├── unit/
├── integration/
├── user_journeys/
├── concurrent/
├── stress/
├── chaos/
└── monitoring/
```

## 运行命令（建议）

```bash
pytest tests/unit/ -v --tb=short
pytest tests/integration/ -v
pytest tests/user_journeys/ -v --timeout=300
pytest tests/concurrent/ -v --count=10
pytest tests/stress/ -v --timeout=3600
pytest tests/chaos/ -v --timeout=1800
pytest tests/ -v --cov=src --cov-report=html
```

## 覆盖率与红绿灯标准（建议）

覆盖率目标：
- Unit（src/）≥ 85%
- Integration ≥ 70%
- User Journey ≥ 60%
- Concurrent：关键路径尽量覆盖（并通过重复运行捕获竞态）
- Stress/Chaos：以定性验证为主

CI 基线门禁：
- required checks `ci` / `merge-serial` 运行 `pytest -q --cov=src --cov-fail-under=75`，覆盖率低于 75% 直接阻塞。

红灯（阻塞）示例：
- 任何 unit/integration 失败
- 并发测试出现数据竞态（读到脏数据/部分写入）
- 压力测试出现明显泄漏或 OOM
- 混沌工程出现 silent failure（无错误记录）

## 实施路线图（建议）

- Phase 1：目录与 fixture（新增 `tests/user_journeys/`、`tests/concurrent/`、`tests/stress/`、`tests/chaos/`；补齐基础 fixture）
- Phase 2：核心旅程与竞态（A/B + 并发 1/4）
- Phase 3：压力与混沌（压力 1/4 + 资源耗尽）
- Phase 4：生产监控验证（metrics/logs 断言 + SLO/告警联动）

## 工具栈（建议）

| 用途 | 工具 |
| --- | --- |
| 并发测试 | threading / pytest-repeat（或同类重跑能力） |
| 压力测试 | locust / pytest-benchmark |
| 混沌工程 | unittest.mock / pyfakefs |
| 覆盖率 | pytest-cov / coverage |
| 性能追踪 | py-spy / memory_profiler |
| 监控验证 | 自定义 metrics fixture（或同类工具） |

## 任务卡片

- `openspec/specs/ss-testing-strategy/task_cards/user_journeys.md`
- `openspec/specs/ss-testing-strategy/task_cards/concurrent.md`
- `openspec/specs/ss-testing-strategy/task_cards/stress.md`
- `openspec/specs/ss-testing-strategy/task_cards/chaos.md`
