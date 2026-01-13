# SS 项目整合行动计划

## 概述

本文档将审计发现转化为可执行的行动计划，包括优先级、时间表、资源投入和里程碑。

---

## 优先级矩阵

```
高影响 / 高工作量    高影响 / 低工作量
┌─────────────────┬──────────────────┐
│ • 分布式存储    │ • 数据版本升级 ✅│
│   (16-24h)      │   (6-8h)         │
│ • 并发竞态防护 ✅│ • 类型注解       │
│   (8-10h)       │   (3-4h)         │
│ • LLM 抽象化    │ • 优雅关闭       │
│   (12-16h)      │   (4-6h)         │
├─────────────────┼──────────────────┤
│ • 多租户支持    │ • 依赖版本锁定   │
│ • 高级调度      │   (1-2h)         │
│                 │ • Python 版本政策│
低影响 / 高工作量 │   (0.5h)         │
                  │ • API 版本管理   │
                  │   (3-4h)         │
                  低影响 / 低工作量
                  └──────────────────┘
```

### 优先级划分

| 等级 | 条件 | 行动时间 | 例子 |
|-----|------|---------|------|
| **🔴 立即 (P0)** | 影响生产稳定性 / 造成数据丢失风险 | 第 1-4 周 | 数据版本、并发竞态、测试组织 |
| **🟡 短期 (P1)** | 影响扩展性 / 架构负债 | 第 5-8 周 | 分布式存储、LLM 抽象、优雅关闭 |
| **🟢 中期 (P2)** | 运维效率 / 开发体验 | 第 9-16 周 | Metrics、多租户、高级调度 |
| **🔵 可选 (P3)** | 边界优化 / 文档增强 | 按需 | 依赖版本、Python 版本政策 |

---

## 阶段计划

### 📅 阶段 0：基础准备（第 1 周，20h）

**目标**：建立评估与规划框架

| 任务 | 责任 | 时间 | 输出 |
|-----|------|------|------|
| 审计报告宣讲与讨论 | CTO + Tech Lead | 4h | 团队共识、优先级确认 |
| 创建 GitHub Issues | PM | 2h | 15 个追踪 Issues |
| 制定详细时间表 | Tech Lead | 3h | Sprint 规划文档 |
| 环境准备（mypy、测试工具） | DevOps | 2h | CI/CD 更新 |
| **小计** | | **11h** | |

### 📅 阶段 1：高优先级 MVP（第 2-4 周，30h）

**目标**：修复生产稳定性问题，完成基础改进

#### 任务 1.1：数据版本升级策略 ✅ 已完成（原 6-8h）

**负责人**：后端工程师 A  
**关键路径**：是

```python
# 交付物（已落地）
1. src/domain/models.py
   - JOB_SCHEMA_VERSION_V1/V2/V3 + JOB_SCHEMA_VERSION_CURRENT
   - SUPPORTED_JOB_SCHEMA_VERSIONS

2. src/infra/job_store_migrations.py
   - assert_supported_schema_version()
   - migrate_payload_to_current()（V1 → V2 → V3）

3. src/infra/job_store.py
   - load(): 迁移到当前版本并原子回写 job.json

4. tests/test_job_store_migration.py
   - 验证 V1 → V2 → V3 迁移链路与迁移日志
```

**验收标准**：
- [x] 可加载 V1/V2 job.json（自动迁移到 V3，并原子回写）
- [x] 新创建/保存的 job 都是 V3 版本
- [x] 迁移日志记录准确（`SS_JOB_JSON_SCHEMA_MIGRATED`）
- [x] 单元测试覆盖迁移链路（`tests/test_job_store_migration.py`）

**时间线**：
- 第 2 周：设计文档 + 实现 (4h)
- 第 3 周：测试 + 代码审查 (2-4h)

---

#### 任务 1.2：并发竞态防护 ✅ 已完成（原 8-10h）

**负责人**：后端工程师 B  
**关键路径**：是

```python
# 方案：文件锁 + 乐观锁（version）+ 原子写入
# src/utils/file_lock.py
with exclusive_lock(lock_file):
    ...

# src/infra/job_store.py（简化）
disk_version = current.get("version", 1)
if job.version != disk_version:
    raise JobVersionConflictError(
        job_id=job_id,
        expected_version=job.version,
        actual_version=disk_version,
    )
new_version = disk_version + 1
atomic_write_json(path=path, payload=payload_to_write)
job.version = new_version
```

**验收标准**：
- [x] Job 模型中有 `version` 字段（`ge=1`）
- [x] `save()` 在文件锁内串行化读-改-写，并做版本冲突检查
- [x] 冲突时抛出 `JobVersionConflictError`（409）
- [x] 并发测试验证冲突场景（`tests/concurrent/test_job_concurrent_write.py`）

**时间线**：
- 第 2 周：设计 + 实现 (4h)
- 第 3 周：集成测试 + 性能测试 (4-6h)

---

#### 任务 1.3：测试组织重构 🔴 (4-6h)

**负责人**：测试工程师 / 后端工程师 C  
**关键路径**：否（非阻塞）

```bash
# 目录结构
tests/
├── conftest.py
├── unit/
│   ├── test_draft_service.py
│   ├── test_job_service.py
│   ├── test_state_machine.py
│   ├── test_job_store.py
│   └── test_llm_tracing.py
├── integration/
│   ├── test_api_jobs.py
│   ├── test_api_draft.py
│   └── test_worker_service.py
└── fixtures/
    └── sample_job.json
```

**迁移清单**：
```bash
# 第 2 周：创建目录结构 + 移动测试文件
mkdir -p tests/{unit,integration,fixtures}
# 按依赖关系将 56 个测试拆分

# 第 3 周：添加覆盖率检查
# pyproject.toml 添加
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src --cov-report=html --cov-report=term:skip-covered"

# CI 中添加
pytest --cov=src --cov-report=lcov
```

**验收标准**：
- [ ] unit/ 有 40+ 测试
- [ ] integration/ 有 10+ 测试
- [ ] `pytest --cov` 生成覆盖率报告
- [ ] 核心业务逻辑覆盖 > 80%
- [ ] CI 中添加 `--cov` check

**时间线**：
- 第 2 周：文件迁移 + 分类 (2h)
- 第 3 周：pytest 配置 + CI 更新 (2-4h)

---

#### 任务 1.4：类型注解完整性 🔴 (3-4h)

**负责人**：后端工程师 D  
**关键路径**：否

```bash
# 第 2 周：添加 mypy 到 CI
# pyproject.toml
[project.optional-dependencies]
dev = [
    ...,
    "mypy>=1.8.0",
]

# pyproject.toml 添加配置
[tool.mypy]
python_version = "3.12"
strict = true
no_implicit_optional = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true

# CI 中添加
mypy src/ --strict --no-implicit-optional
```

**迁移计划**：
```bash
# 找出所有缺注解的函数
mypy src/ --strict 2>&1 | grep "error: Function" | wc -l
# 预计 38 个

# 逐文件修复
# - src/utils/*.py (5-8 个)
# - src/infra/*.py (15-20 个)
# - src/domain/*.py (5-10 个)
# - src/api/*.py (2-5 个)
```

**验收标准**：
- [ ] `mypy src/ --strict` 无报错
- [ ] CI 中添加 mypy 检查
- [ ] 所有函数都有返回类型注解

**时间线**：
- 第 2 周：配置 + 找出缺口 (1h)
- 第 3 周：逐文件补注解 (2-3h)

---

#### 任务 1.5：优雅关闭机制 🔴 (4-6h)

**负责人**：后端工程师 E  
**关键路径**：否（但推荐立即做）

```python
# src/main.py
import signal
import asyncio

shutdown_event = asyncio.Event()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动
    logger.info("SS_SERVER_STARTUP")
    yield
    
    # 关闭
    logger.info("SS_SERVER_SHUTDOWN_INITIATED")
    shutdown_event.set()
    
    # 等待现有 claims 完成（最多 30 秒）
    try:
        await asyncio.wait_for(
            _wait_for_active_claims_completion(),
            timeout=30.0
        )
    except asyncio.TimeoutError:
        logger.warning("SS_SERVER_SHUTDOWN_TIMEOUT")
    
    logger.info("SS_SERVER_SHUTDOWN_COMPLETE")

def create_app() -> FastAPI:
    app = FastAPI(lifespan=lifespan)
    ...
    return app

# src/worker.py
async def run_worker(config: Config) -> None:
    shutdown = asyncio.Event()
    
    def handle_shutdown(*_):
        logger.info("SS_WORKER_SHUTDOWN_REQUESTED")
        shutdown.set()
    
    signal.signal(signal.SIGTERM, handle_shutdown)
    signal.signal(signal.SIGINT, handle_shutdown)
    
    while not shutdown.is_set():
        try:
            success = await asyncio.wait_for(process_next(), timeout=1.0)
            if not success:
                continue
        except asyncio.TimeoutError:
            continue
    
    logger.info("SS_WORKER_SHUTDOWN_COMPLETE")
```

**验收标准**：
- [ ] API 服务在 SIGTERM 时优雅关闭
- [ ] Worker 在 SIGTERM 时完成现有 job
- [ ] 日志记录关闭过程
- [ ] 单元测试验证关闭逻辑

**时间线**：
- 第 3 周：实现 (2-3h)
- 第 4 周：测试 + 验收 (2-3h)

---

**阶段 1 总结**：
- 周期：3-4 周
- 投入：5 人 × 30h = 150 人时
- 风险：任务 1.2 涉及状态机，需要充分测试
- 输出：5 个完整功能，0 个遗留技术债

---

### 📅 阶段 2：中优先级扩展（第 5-8 周，40h）

**目标**：提升扩展性、可观测性、LLM 集成

#### 任务 2.1：LLM 提供商抽象化 🟡 (12-16h)

**负责人**：后端工程师 A + B  
**关键路径**：是

**阶段 2.1a：接口设计 (2h)**
```python
# src/domain/llm_client.py
class LLMConfig(BaseModel):
    provider: str  # "stub" | "openai" | "claude" | "qwen"
    model: str
    temperature: float | None = None
    timeout_seconds: int = 30
    max_retries: int = 3

class LLMClient(Protocol):
    async def draft_preview(self, *, job: Job, prompt: str) -> Draft: ...

# 工厂函数
def create_llm_client(config: LLMConfig) -> LLMClient:
    if config.provider == "stub":
        inner = StubLLMClient()
    elif config.provider == "openai":
        inner = OpenAILLMClient(model=config.model, temperature=config.temperature)
    elif config.provider == "claude":
        inner = ClaudeLLMClient(model=config.model, temperature=config.temperature)
    else:
        raise ValueError(f"unsupported provider: {config.provider}")
    
    return TracedLLMClient(
        inner=inner,
        config=config,
        jobs_dir=...,
    )
```

**阶段 2.1b：实现 OpenAI 客户端 (8-10h)**
```python
# src/infra/openai_llm_client.py
import openai

class OpenAILLMClient(LLMClient):
    def __init__(self, *, model: str, temperature: float | None = None, api_key: str | None = None):
        self.model = model
        self.temperature = temperature or 0.7
        self.client = openai.AsyncOpenAI(api_key=api_key)
    
    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        try:
            response = await asyncio.wait_for(
                self.client.chat.completions.create(
                    model=self.model,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=self.temperature,
                ),
                timeout=30
            )
            text = response.choices[0].message.content
            return Draft(text=text, created_at=utc_now().isoformat())
        except openai.APIError as e:
            raise LLMProviderError(f"OpenAI error: {e}") from e
        except asyncio.TimeoutError:
            raise LLMProviderError("OpenAI timeout") from None
```

**阶段 2.1c：集成与测试 (2-4h)**
- 单元测试：OpenAI 客户端（mock API）
- 集成测试：traced wrapper
- 端到端测试：API → LLM → Draft

**验收标准**：
- [ ] 支持 OpenAI GPT-4 / GPT-3.5
- [ ] 支持超时与重试
- [ ] 支持 Claude（可选）
- [ ] TracedLLMClient 正确记录 prompt/response
- [ ] 测试覆盖 > 80%

---

#### 任务 2.2：API 版本管理 🟡 (3-4h)

**负责人**：后端工程师 C

```python
# src/api/routes.py
from fastapi import APIRouter

# V1 endpoints（标记为 deprecated）
api_v1_router = APIRouter(prefix="/v1", tags=["v1"])

@api_v1_router.post(
    "/jobs",
    response_model=CreateJobResponse,
    deprecated=True,  # 在 Swagger 中标记
)
async def create_job_v1(...):
    """Deprecated: Use /v2/jobs instead.
    
    Sunset date: 2026-06-01
    """
    ...

# V2 endpoints（新特性）
api_v2_router = APIRouter(prefix="/v2", tags=["v2"])

@api_v2_router.post("/jobs", response_model=CreateJobResponseV2)
async def create_job_v2(...):
    """Create a job with support for additional parameters.
    
    New fields:
    - priority: int
    - callback_url: str
    """
    ...

# 同时注册两个版本
app.include_router(api_v1_router)
app.include_router(api_v2_router)
```

**验收标准**：
- [ ] `/v1/` 和 `/v2/` 并行支持
- [ ] 弃用标记在 OpenAPI Spec 中可见
- [ ] V1 → V2 迁移文档

---

#### 任务 2.3：分布式存储方案评估 🟡 (8-10h)

**负责人**：架构师 + 后端工程师 D

**选项评估**：

| 方案 | 优点 | 缺点 | 成本 | 推荐 |
|-----|------|------|------|------|
| **文件存储 (NFS)** | 简单 | 并发差、性能低 | 低 | ❌ 不推荐 |
| **Redis** | 快速、分布式 | 内存有限 | 中等 | ✅ 推荐 (MVP) |
| **PostgreSQL** | 持久、成熟 | 复杂度高 | 中等 | ⭐ 生产推荐 |
| **S3 + DynamoDB** | 云原生 | AWS 锁定 | 高 | 可选 |

**推荐方案**：Redis（3 个月内）+ PostgreSQL（12 个月后）

```python
# src/infra/job_store_backend.py
class JobStoreBackend(Protocol):
    def load(self, job_id: str) -> Job: ...
    def save(self, job: Job) -> None: ...

# 实现：Redis
class RedisJobStore(JobStoreBackend):
    def __init__(self, redis_url: str):
        self.redis = redis.Redis.from_url(redis_url)
    
    def load(self, job_id: str) -> Job:
        data = self.redis.get(f"job:{job_id}")
        if data is None:
            raise JobNotFoundError(job_id=job_id)
        return Job.model_validate_json(data)
    
    def save(self, job: Job) -> None:
        self.redis.set(f"job:{job_id}", job.model_dump_json())

# 在 deps.py 中根据配置选择
def get_job_store() -> JobStoreBackend:
    backend_type = os.getenv("SS_JOB_STORE_BACKEND", "file")
    if backend_type == "redis":
        return RedisJobStore(redis_url=os.getenv("SS_REDIS_URL"))
    else:
        return FileJobStore(jobs_dir=config.jobs_dir)
```

**验收标准**：
- [ ] 对比文档（性能、成本、易用性）
- [ ] Redis 原型实现（可选）
- [ ] 迁移路径文档（如何从文件存储迁移到 Redis）

---

**阶段 2 总结**：
- 周期：4 周
- 投入：4 人 × 40h = 160 人时
- 关键路径：任务 2.1（LLM 集成）
- 输出：3 大功能，支持多 LLM 和 API 版本管理

---

### 📅 阶段 3：高级功能与运维（第 9-16 周，30h）

**目标**：生产级运维、多租户、高级调度

#### 任务 3.1：Metrics、Health Check、Tracing

**工作量**：8-12h  
**包括**：Prometheus metrics、K8s health endpoint、Jaeger tracing 集成

#### 任务 3.2：多租户支持

**工作量**：12-16h  
**包括**：Job 模型加 tenant_id、JobStore 隔离、RBAC 初探

#### 任务 3.3：高级调度与优先级队列

**工作量**：12-16h  
**包括**：优先级队列实现、资源预留、公平调度

---

## 资源投入估算

### 人员配置

```
Phase 1 (4 周): 5 人全职
├── 后端工程师 (3-4 人) - 核心改进
├── 测试工程师 (1 人) - 测试组织 + 验收
└── DevOps (1 人) - CI/CD 配置

Phase 2 (4 周): 4 人全职
├── 后端工程师 (2-3 人) - LLM / 存储集成
├── 架构师 (1 人) - 方案评估
└── QA (1 人) - 集成测试

Phase 3 (8 周): 3 人全职
├── 后端工程师 (2 人)
├── DevOps (1 人)
└── SRE (0.5 人)

总投入: 12-16 周，约 40-50 人周（2-3 个 3-人开发团队）
```

### 时间与成本

| 阶段 | 周数 | 人周 | 预计成本 (假设 $80/小时) |
|-----|------|------|------------------------|
| Phase 1 | 4 | 20 | $64,000 |
| Phase 2 | 4 | 16 | $51,200 |
| Phase 3 | 8 | 12 | $38,400 |
| **总计** | **16** | **48** | **$153,600** |

---

## 风险评估与缓解

| 风险 | 概率 | 影响 | 缓解策略 |
|-----|------|------|---------|
| 并发竞态测试不充分 | 中 | 高 | Phase 1 增加 4-6h 集成测试 |
| 数据迁移脚本有 bug | 中 | 高 | 先在测试环境验证，添加回滚机制 |
| Redis/PostgreSQL 集成超期 | 中 | 中 | 优先用 Redis（更简单），再考虑 PostgreSQL |
| LLM 提供商 API 变更 | 低 | 中 | 使用 LangChain 等抽象层 |
| 团队人力不足 | 中 | 高 | 优先完成 Phase 1，Phase 2/3 可延后 |

---

## 验收与交付标准

### Phase 1 交付清单

- [ ] 所有 5 个任务完成并通过代码审查
- [ ] 所有新增代码通过 mypy + ruff
- [ ] 测试覆盖 > 80%（核心逻辑）
- [ ] 无新增技术债
- [ ] 性能不下降（vs baseline）
- [ ] 可以进行生产灰度发布

### Phase 2 交付清单

- [ ] OpenAI / Claude 集成完全可用
- [ ] API V1/V2 并行运行
- [ ] Redis 存储原型可运行
- [ ] 性能基准报告（吞吐量、延迟）
- [ ] 迁移指南（如何从 File 升级到 Redis）

### Phase 3 交付清单

- [ ] Prometheus metrics 可被 Grafana 消费
- [ ] K8s 健康检查端点生效
- [ ] Jaeger tracing 有样本数据
- [ ] 多租户隔离验证
- [ ] 性能测试通过（100 并发 job）

---

## KPI 与监控

### 代码质量 KPI

| 指标 | 当前 | 目标 | Phase 完成 |
|-----|------|------|-----------|
| 类型注解覆盖 | 84.6% | 100% | Phase 1 |
| 测试覆盖 | ~70%* | 80%+ | Phase 1 |
| Ruff 违规 | 0 | 0 | Phase 1 |
| Mypy 通过率 | 0% | 100% | Phase 1 |

*未执行 --cov，实际覆盖率需测量

### 系统性能 KPI

| 指标 | 当前 | 目标 | Phase 完成 |
|-----|------|------|-----------|
| Job 创建延迟 | <50ms | <30ms | Phase 2 |
| Draft 生成延迟 | 依赖 LLM | <10s (stub) | Phase 2 |
| 队列处理速率 | 20 job/min | 100 job/min | Phase 3 |
| 并发 claim 数 | 1 | 10+ | Phase 3 |

### 可观测性 KPI

| 指标 | 当前 | 目标 | Phase 完成 |
|-----|------|------|-----------|
| Structured logging | ✓ | ✓ + aggregation | Phase 2 |
| Metrics 导出 | ✗ | Prometheus | Phase 3 |
| Distributed tracing | ✗ | Jaeger | Phase 3 |
| Health check | ✗ | K8s ready/live | Phase 3 |

---

## 决策点与里程碑

### Phase 1 末决策（第 4 周）

**决策 1：并发防护方案确认**
- [ ] 乐观锁（当前推荐）足够吗？
- [ ] 是否需要加文件锁？
- 影响：影响 Phase 2 中的分布式存储设计

**决策 2：立即上线 Phase 1 改进吗？**
- [ ] 性能无损失？
- [ ] 测试充分？
- 影响：影响 Phase 2 开始时间

### Phase 2 末决策（第 8 周）

**决策 3：Redis vs PostgreSQL for job store?**
- [ ] Redis 性能满足需求？
- [ ] 成本可接受？
- 影响：影响 Phase 3 的存储架构

**决策 4：LLM 提供商优先级**
- [ ] OpenAI 足够吗？
- [ ] 是否需要 Claude？
- 影响：影响实际部署的多 LLM 支持

### Phase 3 初决策（第 9 周）

**决策 5：是否需要 Kubernetes 部署？**
- [ ] 单机 + Docker 足够？
- [ ] 需要 K8s 的自动扩展？
- 影响：影响监控、日志、调度的复杂度

---

## 推荐执行策略

### 快速路径（16 周，中等投入）

1. **Phase 1 必做**（第 1-4 周）
   - 数据版本升级
   - 并发竞态防护
   - 测试组织
   - 优雅关闭

2. **Phase 2 优先做**（第 5-8 周）
   - LLM 提供商
   - API 版本管理

3. **Phase 3 根据需求**（第 9-16 周）
   - 分布式存储（若需要）
   - 运维工具（若上生产）

### 保守路径（24+ 周，低风险）

- 每个 Phase 拉长到 8 周
- 增加更多回归测试
- 逐个 feature 灰度发布
- 适合小团队或风险敏感的组织

### 激进路径（8 周，高效但高风险）

- 并行执行 Phase 1 + 2 的部分任务
- 需要 8-10 人团队
- 强烈建议有专业 QA 和 DevOps

**推荐**：中等投入的快速路径

---

## 与宪法的一致性维持

在执行过程中，**必须保持与 ss-constitution 的一致性**：

| 宪法要求 | 维持措施 |
|---------|---------|
| OpenSpec 权威 | 每个 task 必须更新对应 spec |
| 显式依赖注入 | 新代码必须通过 deps 注入 |
| 具体异常 | 禁止 `except Exception` |
| 无动态代理 | 代码审查检查 |
| 大小限制 | PR 审查时检查行数 |
| 结构化日志 | 所有日志必须包含事件码 + extra |
| 分层边界 | 架构审查确保无逆向依赖 |
| 交付流程 | 所有改进通过 Issue → PR → checks → merge |

---

## 下一步行动（即刻）

### 第 1 周行动项

1. **宣讲审计报告**（1 小时）
   - 项目经理邀请团队阅读本文
   - CTO 讲解重点改进方向

2. **创建 GitHub Issues**（2 小时）
   ```
   Task 001: 数据版本升级策略 [Phase 1] [6-8h]
   Task 002: 并发竞态防护 [Phase 1] [8-10h]
   Task 003: 测试组织重构 [Phase 1] [4-6h]
   Task 004: 类型注解完整性 [Phase 1] [3-4h]
   Task 005: 优雅关闭机制 [Phase 1] [4-6h]
   ... (总共 15 个 Issues)
   ```

3. **技术方案审查会议**（2 小时）
   - 讨论每个任务的实现细节
   - 确认 reviewer 和 owner
   - 分配预期完成时间

4. **Sprint 计划**（1 小时）
   - 将 Phase 1 的 5 个任务分配到 4 个 Sprint
   - 每个 Sprint 5-6 天
   - 预留 20% 缓冲

### 成功标志

- [ ] 团队理解改进方向
- [ ] 15 个 Issues 已创建并分配
- [ ] Phase 1 已在 Sprint backlog 中
- [ ] 第 1 个任务已开始编码

---

**制定日期**：2025-01-07  
**版本**：v1.0  
**维护责任**：CTO / Tech Lead
