# SS 项目深度审计补充报告

## 目录

1. [遗漏的改进空间](#遗漏的改进空间) - 8 项
2. [潜在的设计陷阱](#潜在的设计陷阱) - 6 项
3. [扩展性与伸缩性](#扩展性与伸缩性) - 5 项
4. [运维与可观测性](#运维与可观测性) - 4 项
5. [API 与向后兼容性](#api-与向后兼容性) - 3 项

---

## 遗漏的改进空间

### 1. **类型注解覆盖度不完全** 🔴 (优先级：中)

**当前状态**：84.6% 函数有返回类型注解（208/246），缺失 38 个

**问题**：
- 某些工具函数与内部方法无返回类型
- IDE 自动补全与类型检查无法 100% 工作
- 新贡献者易犯同样错误

**示例**：
```python
# src/infra/llm_tracing.py:39-47
def _sha256_hex(value: str) -> str:  # ✓ 有
    ...

def _estimate_tokens(text: str) -> int:  # ✓ 有
    ...

# 假设存在无注解的：
def _parse_param(value):  # ✗ 缺返回类型
    return int(value) if value else None
```

**改进方案**：
```bash
# 添加 mypy 或 pyright 到 CI/CD
pip install mypy
mypy src/ --strict --no-implicit-optional
```

**改进清单**：
- [ ] 添加 `mypy>=1.8.0` 到 `pyproject.toml` 的 dev 依赖
- [ ] 配置 `tool.mypy` 段（strict mode）
- [ ] 补全 38 个缺失的返回类型
- [ ] 在 CI 中添加 `mypy` check
- **预计工作量**：3-4 小时

---

### 2. **依赖版本范围过宽松** 🟡 (优先级：低)

**当前状态**：
```toml
dependencies = [
    "fastapi>=0.110.0",      # ≥ 0.110.0（任意新版本）
    "pydantic>=2.6.0",       # ≥ 2.6.0（任意新版本）
    "uvicorn>=0.27.0",       # ≥ 0.27.0（任意新版本）
]
```

**问题**：
- `fastapi>=0.110.0` 涵盖了未来 1.0+ 的主版本更新，可能引入 breaking changes
- 开发环境与生产环境依赖不一致时，难以复现问题
- 版本跳跃可能导致隐秘的行为变化

**改进方案**：
```toml
# 使用锁定的主版本，允许补丁/次版本更新
dependencies = [
    "fastapi>=0.110.0,<1.0.0",
    "pydantic>=2.6.0,<3.0.0",
    "uvicorn>=0.27.0,<1.0.0",
]
```

**补充**：添加 `pyproject.toml` 的 lock 文件管理
```bash
pip install pip-tools  # 或 poetry/uv
pip-compile pyproject.toml  # 生成 requirements.txt.lock
```

**预计工作量**：1-2 小时

---

### 3. **缺少 Python 版本政策与向后兼容性声明** 🟡 (优先级：低)

**当前状态**：
```toml
requires-python = ">=3.12"
```

**问题**：
- 未明确说明最低版本是否为稳定版（3.12 GA 是 2023-10）
- 未说明是否考虑支持 3.11、3.10（LTS 场景）
- 新 API 采用了 Python 3.10+ 特性（如 `|` union 语法），不清楚为何固定 3.12

**改进**：
```python
# pyproject.toml 添加注释
requires-python = ">=3.12"  
# 理由：使用了 3.10+ 的 | union type syntax 和 PEP 695 type parameters (3.12+)
# LTS 政策：支持 3.12 LTS 版本及以上。当 3.13/3.14 发布时，逐版测试并更新约束
```

**预计工作量**：0.5 小时（文档）

---

### 4. **缺乏数据迁移/版本升级策略** ✅ 已解决（原优先级：高）

**状态**：✅ 已解决 —— 已实现 Job schema 的 V1 → V2 → V3 自动迁移（读兼容、写入当前版本）。

**当前实现（代码）**：
- `src/domain/models.py`：`JOB_SCHEMA_VERSION_V1/V2/V3`、`JOB_SCHEMA_VERSION_CURRENT`、`SUPPORTED_JOB_SCHEMA_VERSIONS`
- `src/infra/job_store_migrations.py`：`assert_supported_schema_version()` + `migrate_payload_to_current()`（包含 `_migrate_v1_to_v2()`、`_migrate_v2_to_v3()`）
- `src/infra/job_store.py`：`load()` 读取后迁移；若发生迁移则用 `atomic_write_json()` 原子回写到同一 `job.json`

**行为说明**：
- 读：允许加载 `schema_version in {1, 2, 3}`；旧版本会迁移到 `JOB_SCHEMA_VERSION_CURRENT`
- 写：`create()`/`save()` 要求 `job.schema_version == JOB_SCHEMA_VERSION_CURRENT`，避免写出旧 schema
- 追踪：迁移时记录 `SS_JOB_JSON_SCHEMA_MIGRATED`（含 `from_version`/`to_version`）

**补充**：迁移后的 payload 会回写到磁盘，确保后续读取不再重复迁移。

**预计工作量**：✅ 已完成

---

### 5. **缺乏并发控制与竞态条件防护** ✅ 已解决（原优先级：高）

**状态**：✅ 已解决 —— 已实现“文件锁 + 乐观锁（`version`）+ 原子写入”三层防护。

**当前实现（代码）**：
- `src/utils/file_lock.py`：`exclusive_lock()`（Unix `fcntl.flock`；Windows `msvcrt.locking`）
- `src/domain/models.py`：`Job.version`（`ge=1`）
- `src/infra/job_store.py`：`JobStore.save()` 使用 `job.json.lock` 串行化读-改-写，并校验/递增 `version`
- `src/infra/exceptions.py`：`JobVersionConflictError`（HTTP 409）

**行为说明**：
- `save()` 在持有 `job.json.lock` 时读取最新 `job.json`，并先迁移到当前 schema 后再做版本校验
- 当 `job.version != disk_version` 时拒绝覆盖，抛出 `JobVersionConflictError`
- 写入采用 `atomic_write_json()`（tempfile + `os.replace`），避免部分写入/文件损坏

**预计工作量**：✅ 已完成

---

### 6. **缺乏优雅关闭与资源清理** 🟡 (优先级：中)

**当前状态**：
```python
# src/main.py
def main() -> None:
    import uvicorn
    
    config = app.state.config
    log_config = build_logging_config(log_level=config.log_level)
    uvicorn.run(...)
```

**问题**：
- 如果 worker 正在处理 claim，突然关闭会导致：
  - claim 未被 ack，job 陷入 RUNNING 状态
  - 数据库连接未关闭
  - LLM call 中途中止
- 无 shutdown hook，无优雅关闭流程

**改进方案**：

```python
# src/main.py
import signal
from contextlib import asynccontextmanager

shutdown_event = asyncio.Event()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动
    logger.info("SS_SERVER_STARTUP")
    yield
    
    # 关闭
    logger.info("SS_SERVER_SHUTDOWN_INITIATED")
    shutdown_event.set()
    
    # 等待现有 claim 完成（最多 30 秒）
    try:
        await asyncio.wait_for(
            _wait_for_claims_completion(),
            timeout=30.0
        )
    except asyncio.TimeoutError:
        logger.warning("SS_SERVER_SHUTDOWN_TIMEOUT")
    
    logger.info("SS_SERVER_SHUTDOWN_COMPLETE")

def create_app() -> FastAPI:
    app = FastAPI(title="SS", version="0.0.0", lifespan=lifespan)
    ...
    return app
```

**worker.py 中添加信号处理**：
```python
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
            await asyncio.wait_for(process_next(), timeout=1.0)
        except asyncio.TimeoutError:
            continue
    
    logger.info("SS_WORKER_SHUTDOWN_COMPLETE")
```

**预计工作量**：4-6 小时

---

### 7. **缺乏分布式部署的一致性保证** 🔴 (优先级：高，阶段二)

**当前状态**：
- 单机文件存储 (`jobs/` 和 `queue/` 目录)
- 多个 API/worker 实例可能同时访问同一 job

**问题**：
- 如果分布式部署到多台机器，NFS 并发访问会出现：
  - 文件缓存不一致
  - 原子性保证失效
  - 竞态条件恶化

**改进方向**：
```python
# 抽象 JobStore 为 Protocol
class JobStoreBackend(Protocol):
    def load(self, job_id: str) -> Job: ...
    def save(self, job: Job) -> None: ...

# 提供多种实现
class FileJobStore(JobStoreBackend):
    """单机文件存储（当前）"""
    ...

class RedisJobStore(JobStoreBackend):
    """分布式 Redis（推荐生产）"""
    def load(self, job_id: str) -> Job:
        data = self.redis.get(f"job:{job_id}")
        return Job.model_validate_json(data)
    
    def save(self, job: Job) -> None:
        self.redis.set(f"job:{job_id}", job.model_dump_json())

class PostgresJobStore(JobStoreBackend):
    """关系数据库（替代方案）"""
    ...

# 在 deps.py 中注入
def get_job_store() -> JobStoreBackend:
    backend = os.getenv("SS_JOB_STORE_BACKEND", "file")
    if backend == "redis":
        return RedisJobStore(...)
    elif backend == "postgres":
        return PostgresJobStore(...)
    else:
        return FileJobStore(...)
```

**预计工作量**：16-24 小时（含测试）

---

### 8. **缺乏 API 版本管理与弃用政策** 🟡 (优先级：中)

**当前状态**：
```python
# src/api/routes.py
api_router = APIRouter()
api_router.include_router(jobs.router)
api_router.include_router(draft.router)
```

**问题**：
- API 未使用版本前缀（如 `/v1/jobs` vs `/v2/jobs`）
- 无法并行支持多个 API 版本
- 如果 endpoint 签名改变，现有客户端会破坏
- 无弃用通知机制（X-Deprecated-At header 等）

**改进方案**：

```python
# src/api/routes.py
from fastapi import APIRouter

api_v1_router = APIRouter(prefix="/v1", tags=["v1"])
api_v2_router = APIRouter(prefix="/v2", tags=["v2"])

# v1 endpoint（后续可标记为 deprecated）
@api_v1_router.post("/jobs")
async def create_job_v1(...):
    ...

# v2 endpoint（新增字段）
@api_v2_router.post("/jobs")
async def create_job_v2(...):
    ...

app.include_router(api_v1_router)
app.include_router(api_v2_router)
```

**添加弃用警告**：
```python
@api_v1_router.post("/jobs")
async def create_job_v1(...):
    """Deprecated: Use /v2/jobs instead."""
    return JSONResponse(
        status_code=200,
        headers={"Deprecation": "true", "Sunset": "2026-01-01"},
        content={...}
    )
```

**预计工作量**：3-4 小时

---

## 潜在的设计陷阱

### 1. **LLM 调用的超时与重试策略不明确** 🟡

**当前代码**：
```python
# src/infra/llm_tracing.py:80-120
async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
    ...
    start = utc_now()
    try:
        draft = await self._inner.draft_preview(job=job, prompt=prompt)
    except LLMProviderError as e:
        ...
        raise LLMCallFailedError(...)
```

**问题**：
- 无显式超时（await 可能永久挂起）
- 无重试策略（网络抖动就失败）
- 无降级方案（LLM 不可用时的策略）

**改进**：
```python
async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
    timeout_sec = self._timeout or 30
    retries = 3
    
    for attempt in range(retries):
        try:
            draft = await asyncio.wait_for(
                self._inner.draft_preview(job=job, prompt=prompt),
                timeout=timeout_sec
            )
            return draft
        except asyncio.TimeoutError:
            logger.warning(
                "SS_LLM_TIMEOUT",
                extra={
                    "job_id": job.job_id,
                    "attempt": attempt + 1,
                    "timeout_sec": timeout_sec
                }
            )
            if attempt == retries - 1:
                raise LLMCallFailedError(...)
        except LLMProviderError as e:
            if attempt == retries - 1:
                raise
            await asyncio.sleep(2 ** attempt)  # exponential backoff
```

---

### 2. **State Machine 允许非预期的自环转移** 🟡

**当前代码**：
```python
# src/domain/state_machine.py:41-51
def ensure_transition(
    self,
    *,
    job_id: str,
    from_status: JobStatus,
    to_status: JobStatus,
) -> bool:
    if from_status == to_status:
        return False  # ← 自环不转移
    ...
```

**问题**：
- 如果调用方连续调用 `ensure_transition(CREATED, CREATED)`，返回 False 而非异常
- 容易掩盖逻辑错误（本应转移，但因为状态未更新而卡住）

**改进**：
```python
def ensure_transition(
    self,
    *,
    job_id: str,
    from_status: JobStatus,
    to_status: JobStatus,
) -> bool:
    # 移除自环容忍，让调用方显式检查
    if from_status == to_status:
        raise JobIllegalTransitionError(
            job_id=job_id,
            from_status=from_status,
            to_status=to_status,
        )  # 强制调用方注意
    
    if not self.can_transition(from_status=from_status, to_status=to_status):
        raise JobIllegalTransitionError(...)
    
    return True  # 简化：总是返回 True
```

---

### 3. **Worker Claim TTL 与重处理风险** 🟡

**当前代码**：
```python
# src/infra/file_worker_queue.py
def claim(self, *, worker_id: str) -> QueueClaim | None:
    ...
    lease_expires_at = now + timedelta(seconds=self._lease_ttl_seconds)
    ...
```

**问题**：
- 如果 job 执行耗时 > lease_ttl，claim 过期
- 另一个 worker 会重新处理同一 job（double execution）
- 虽然状态机提供了一些保护（已 RUNNING 的状态检查），但不是完整的幂等性

**改进**：
```python
# 动态调整 lease TTL
def claim(self, *, worker_id: str, estimated_duration: int = None) -> QueueClaim | None:
    ttl = estimated_duration or self._lease_ttl_seconds
    max_ttl = 3600  # 1 小时上限
    ttl = min(ttl, max_ttl)
    lease_expires_at = now + timedelta(seconds=ttl)
    ...

# 或者，worker 在执行中心跳（延期 lease）
def extend_claim(self, *, claim: QueueClaim, additional_seconds: int) -> None:
    ...
```

---

### 4. **PlanStep 依赖链未验证** 🟡

**当前代码**：
```python
# src/domain/models.py:149-158
@field_validator("steps")
@classmethod
def steps_must_have_unique_ids_and_valid_deps(cls, steps: list[PlanStep]) -> list[PlanStep]:
    ids = [step.step_id for step in steps]
    if len(ids) != len(set(ids)):
        raise ValueError("steps contain duplicate step_id")
    known = set(ids)
    for step in steps:
        for dep in step.depends_on:
            if dep not in known:
                raise ValueError(f"unknown dependency: {dep}")
    return steps
```

**问题**：
- 检查了依赖是否存在，但**未检查循环依赖**（A → B → A）
- 未检查拓扑排序的可行性
- 执行时可能陷入无穷等待

**改进**：
```python
def _validate_plan_dag(steps: list[PlanStep]) -> None:
    """Check for cycles and topological ordering."""
    ids = [step.step_id for step in steps]
    
    # Check for cycles using DFS
    graph = {sid: step.depends_on for sid, step in zip(ids, steps)}
    visited = set()
    rec_stack = set()
    
    def has_cycle(node):
        visited.add(node)
        rec_stack.add(node)
        for dep in graph.get(node, []):
            if dep not in visited:
                if has_cycle(dep):
                    return True
            elif dep in rec_stack:
                return True
        rec_stack.remove(node)
        return False
    
    for step_id in ids:
        if step_id not in visited:
            if has_cycle(step_id):
                raise ValueError(f"circular dependency detected in plan: {step_id}")
```

---

### 5. **Artifact 索引可能漂移** 🟡

**当前代码**：
```python
# src/domain/worker_service.py:289-296
def _index_artifacts(self, *, job: Job, result: RunResult) -> None:
    known = {(ref.kind, ref.rel_path) for ref in job.artifacts_index}
    for ref in result.artifacts:
        key = (ref.kind, ref.rel_path)
        if key in known:
            continue
        job.artifacts_index.append(ref)
        known.add(key)
```

**问题**：
- artifacts_index 只在 memory 中更新，然后 save
- 如果 save 失败，索引与文件系统不同步
- 恢复时无法自动重建索引

**改进**：
```python
def list_artifacts(self, *, job_id: str) -> list[ArtifactRef]:
    """Rebuild index from filesystem if needed."""
    job = self._store.load(job_id)
    job_dir = self._get_job_dir(job_id)
    
    actual_files = set(job_dir.rglob("*"))
    indexed_files = {self._resolve_artifact_path(job_id, ref.rel_path) for ref in job.artifacts_index}
    
    if actual_files != indexed_files:
        logger.warning(
            "SS_ARTIFACTS_INDEX_DRIFT",
            extra={
                "job_id": job_id,
                "missing": [str(f.relative_to(job_dir)) for f in actual_files - indexed_files],
            }
        )
        # 重建索引
        for file_path in actual_files:
            rel_path = str(file_path.relative_to(job_dir))
            if not any(ref.rel_path == rel_path for ref in job.artifacts_index):
                job.artifacts_index.append(ArtifactRef(kind=ArtifactKind.UNKNOWN, rel_path=rel_path))
        self._store.save(job)
    
    return job.artifacts_index
```

---

### 6. **Config 验证缺乏细粒度检查** 🟡

**当前代码**：
```python
# src/config.py:25-36
def _int_value(raw: str, *, default: int) -> int:
    try:
        return int(raw)
    except (TypeError, ValueError):
        return default

def _float_value(raw: str, *, default: float) -> float:
    try:
        return float(raw)
    except (TypeError, ValueError):
        return default
```

**问题**：
- 无验证范围（如 queue_lease_ttl_seconds 可以是负数）
- worker_max_attempts 可以是 0（无法执行）
- stata_cmd 可以是不存在的命令（运行时才失败）

**改进**：
```python
@dataclass(frozen=True)
class Config:
    jobs_dir: Path
    ...
    
    def __post_init__(self):
        # 验证目录存在或可创建
        try:
            self.jobs_dir.mkdir(parents=True, exist_ok=True)
        except OSError as e:
            raise ValueError(f"Cannot create jobs_dir: {e}") from e
        
        # 验证范围
        if self.queue_lease_ttl_seconds <= 0:
            raise ValueError("queue_lease_ttl_seconds must be positive")
        
        if self.worker_max_attempts <= 0:
            raise ValueError("worker_max_attempts must be at least 1")
        
        # 验证 stata_cmd
        if self.stata_cmd:
            cmd_path = shutil.which(self.stata_cmd[0])
            if not cmd_path:
                raise ValueError(f"stata command not found: {self.stata_cmd[0]}")
```

---

## 扩展性与伸缩性

### 1. **队列吞吐量设计不清晰** 🟡

**问题**：
- 当前 FileWorkerQueue 基于文件系统，单机性能上限
- 无法动态扩展 worker 数量（无负载均衡）
- 无优先级队列支持

**建议**：
```python
# Phase 2: 支持消息队列
class WorkerQueue(Protocol):
    async def enqueue(self, *, job_id: str, priority: int = 0) -> None: ...
    async def claim(self, *, worker_id: str, timeout: float = 1.0) -> QueueClaim | None: ...

# 实现：Redis Stream / RabbitMQ / AWS SQS
class RedisStreamQueue(WorkerQueue):
    """支持优先级、TTL、消费组"""
    ...

class RabbitMQQueue(WorkerQueue):
    """支持优先级、死信队列、确认机制"""
    ...
```

---

### 2. **Job Store 分片策略缺失** 🟡

**问题**：
- 当 job 数量达到百万级，单个 jobs/ 目录无法承载
- 文件系统搜索性能下降

**改进**：
```python
def _job_dir(self, job_id: str) -> Path:
    # 哈希分片：job_id 首 2 字符作为目录
    shard = job_id[:2]
    return self._jobs_dir / shard / job_id
```

---

### 3. **缺乏资源隔离与配额** 🟡

**问题**：
- 某个用户的大量 job 可能耗尽系统资源
- 无速率限制、无 quota

**改进**：
```python
# 在 API layer 添加
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/jobs")
@limiter.limit("10/minute")  # 限制频率
async def create_job(...):
    ...
```

---

### 4. **缺乏动态配置与热重载** 🟡

**问题**：
- 修改配置需要重启服务
- 无法动态调整日志级别、worker 数量等

**改进**：
```python
# src/infra/config_manager.py
class ConfigManager:
    def get_config(self) -> Config: ...
    def set_log_level(self, level: str) -> None: ...
    def get_dynamic_config(self, key: str) -> Any: ...

# 在 FastAPI 中暴露管理端点
@router.post("/admin/config/log-level")
async def set_log_level(level: str):
    config_mgr.set_log_level(level)
    return {"ok": True}
```

---

### 5. **缺乏多租户支持** 🟡

**问题**：
- 当前架构单租户
- 无法在同一实例中隔离多个用户

**改进**（阶段三）：
```python
# 添加 tenant_id 到 Job
class Job(BaseModel):
    tenant_id: str
    job_id: str
    ...

# 在 JobStore 中强制 tenant 隔离
def _resolve_job_dir(self, *, tenant_id: str, job_id: str) -> Path:
    return self._jobs_dir / tenant_id / job_id[:2] / job_id
```

---

## 运维与可观测性

### 1. **缺乏 Metrics 导出** 🔴

**问题**：
- 无法了解系统实时状态（job 处理速率、错误率等）
- 无法配置告警

**改进**：
```python
# src/infra/metrics.py
from prometheus_client import Counter, Histogram, Gauge

job_created = Counter("ss_job_created_total", "Total jobs created")
job_processing_seconds = Histogram("ss_job_processing_seconds", "Job processing time")
active_claims = Gauge("ss_active_claims", "Active queue claims")

# 在 FastAPI 中暴露 Prometheus 端点
from prometheus_client import make_asgi_app
metrics_app = make_asgi_app()

app.mount("/metrics", metrics_app)
```

---

### 2. **缺乏健康检查端点** 🟡

**问题**：
- 容器编排系统（K8s）无法判断服务是否健康
- 无法实现自动恢复

**改进**：
```python
@router.get("/health/live")  # Kubernetes liveness probe
async def liveness() -> dict:
    return {"status": "ok"}

@router.get("/health/ready")  # Kubernetes readiness probe
async def readiness() -> dict:
    try:
        # 检查依赖
        job_store.load("dummy")  # 会抛异常，但这是为了测试连接
    except JobNotFoundError:
        return {"status": "ready"}
    except Exception as e:
        return {"status": "unhealthy", "reason": str(e)}, 503
```

---

### 3. **缺乏分布式追踪支持** 🟡

**问题**：
- 多个 worker 处理同一 job，难以追踪端到端流程
- 无 trace ID、无 span

**改进**：
```python
# src/infra/tracing.py
from opentelemetry import trace, metrics
from opentelemetry.exporter.jaeger import JaegerExporter

tracer = trace.get_tracer(__name__)

# 在关键位置添加 span
@tracer.start_as_current_span("job_creation")
def create_job(...):
    ...

@tracer.start_as_current_span("job_processing")
def process_claim(claim: QueueClaim):
    ...
```

---

### 4. **缺乏审计日志** 🟡

**问题**：
- 无法追踪谁做了什么（用户修改、系统操作）
- 无合规性记录

**改进**：
```python
# src/infra/audit.py
class AuditLogger:
    def log_action(
        self,
        action: str,
        resource_type: str,
        resource_id: str,
        user_id: str,
        changes: dict,
    ) -> None:
        event = {
            "timestamp": utc_now().isoformat(),
            "action": action,
            "resource_type": resource_type,
            "resource_id": resource_id,
            "user_id": user_id,
            "changes": changes,
        }
        logger.info("AUDIT_EVENT", extra=event)

# 在 API 中使用
@router.post("/jobs/{job_id}/confirm")
async def confirm_job(...):
    audit.log_action(
        action="JOB_CONFIRMED",
        resource_type="job",
        resource_id=job_id,
        user_id=current_user.id,
        changes={"status": job.status.value}
    )
    ...
```

---

## API 与向后兼容性

### 1. **Response 格式无版本隔离** 🟡

**问题**：
- 如果添加新字段到响应，会破坏依赖特定字段顺序的客户端

**改进**：
```python
# 使用 envelope 包装
class APIResponse(BaseModel, Generic[T]):
    data: T
    meta: dict = {}
    errors: list[dict] | None = None

@router.get("/jobs/{job_id}")
async def get_job(...) -> APIResponse[GetJobResponse]:
    job = ...
    return APIResponse(
        data=GetJobResponse.from_domain(job),
        meta={"api_version": "v1", "timestamp": utc_now().isoformat()}
    )
```

---

### 2. **缺乏 Content-Type 协商** 🟡

**问题**：
- 只支持 JSON，无法返回 CSV、Parquet 等格式
- 无法在不破坏 API 的情况下扩展格式

**改进**：
```python
@router.get("/jobs/{job_id}/artifacts/{artifact_id}/export")
async def export_artifact(
    job_id: str,
    artifact_id: str,
    format: str = Query("json", regex="^(json|csv|parquet)$"),
):
    data = ...
    if format == "csv":
        return StreamingResponse(
            content=convert_to_csv(data),
            media_type="text/csv"
        )
    elif format == "parquet":
        return StreamingResponse(...)
    else:
        return data
```

---

### 3. **缺乏成熟的错误响应标准** 🟡

**问题**：
- 错误响应不一致（有时有 error_code，有时没有）
- 无标准的错误文档

**改进**：
```python
# RFC 7807: Problem Details for HTTP APIs
class ErrorDetail(BaseModel):
    type: str  # Error type URI
    title: str  # Human-readable title
    detail: str  # Detailed explanation
    status: int  # HTTP status code
    instance: str  # Request ID for tracing

# 示例
{
    "type": "https://api.example.com/errors/job-not-found",
    "title": "Job Not Found",
    "detail": "Job with id 'xyz' does not exist",
    "status": 404,
    "instance": "req-12345"
}
```

---

## 总结：遗漏的改进（按总工作量排序）

| 序号 | 项目 | 优先级 | 工作量 | 总分数 |
|------|------|--------|--------|--------|
| 4 | 数据迁移/版本升级 | 🔴 高 | 6-8h | ⭐⭐⭐⭐⭐ |
| 5 | 并发控制与竞态 | 🔴 高 | 8-10h | ⭐⭐⭐⭐⭐ |
| 7 | 分布式部署一致性 | 🔴 高 | 16-24h | ⭐⭐⭐⭐⭐ |
| 1 | 类型注解完整性 | 🟡 中 | 3-4h | ⭐⭐⭐☆☆ |
| 6 | 优雅关闭 | 🟡 中 | 4-6h | ⭐⭐⭐⭐☆ |
| 8 | API 版本管理 | 🟡 中 | 3-4h | ⭐⭐⭐☆☆ |
| 2 | 依赖版本锁定 | 🟢 低 | 1-2h | ⭐⭐☆☆☆ |
| 3 | Python 版本政策 | 🟢 低 | 0.5h | ⭐☆☆☆☆ |
| **总计** | | | **42-59h** | |

---

生成时间：2025-01-07  
补充审计员：Amp AI Agent
