# [DEPLOY-READY] DEPLOY-READY-R090: Docker 部署端到端验证（docker-compose up → 完整旅程 → READY）

## Metadata

- Priority: P0
- Issue: #406
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-production-e2e-audit/spec.md`
  - `openspec/specs/ss-deployment-docker-minio/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`

## Problem

生产部署就绪不能靠“理论上可行”，必须通过一次可复现的 Docker 端到端验证（E2E）确保：
- API 能正常提供服务
- worker 能消费队列并完成执行
- MinIO 可用（如启用 uploads）
- 输出产物可下载且格式满足用户指定

目标部署环境为 **Windows Server + Docker Desktop（WSL2 后端）+ Windows Stata 18 MP**。部署验证必须覆盖：
- `SS_STATA_CMD` 支持 Windows 路径（包含空格）示例：`/mnt/c/Program Files/Stata18/StataMP-64.exe`
- 在 docker-compose 拓扑中，worker 的 Stata 调用链路与证据可审计（启动日志/runner meta/artifacts）

## Goal

提供一条从 `docker-compose up` 到 “READY” 的端到端验证流程与证据，覆盖最小用户旅程：
1) 启动 services（minio + ss-api + ss-worker）
2) 验证健康检查（`/health/live` + `/health/ready`）与 MinIO 可用性
3) 创建 job 并上传数据（至少 CSV；如支持则覆盖 XLSX/XLS/DTA）
4) 触发执行并等待完成
5) 验证 artifacts 可下载，且包含 `output_formats` 请求的格式
6) 重启 `ss-api`/`ss-worker` 后验证 job 状态与 artifacts 可恢复

## In scope

- 编写/固化一份可复现的 E2E 验证步骤（命令 + 预期输出）
- （可选）提供一个自检脚本用于自动化验证

## Out of scope

- 不在本卡进行生产级压测与容量评估

## Dependencies & parallelism

- Depends on: DEPLOY-READY-R010, DEPLOY-READY-R011, DEPLOY-READY-R012, DEPLOY-READY-R031
- Can run in parallel with: none (gate task)

## Acceptance checklist

- [x] Spec/task card 已明确 Windows + Docker Desktop + WSL2 部署场景（含 `SS_STATA_CMD=/mnt/c/...` 示例）
- [x] `docker-compose up -d` 可启动并保持 `ss-api`/`ss-worker` 稳定运行
- [x] MinIO 可访问（console/API）且 bucket 初始化完成（如启用 uploads）
- [x] `ss-api` 响应 `/health/live` 与 `/health/ready`
- [x] `ss-worker` 启动成功且以 Windows 路径 `SS_STATA_CMD=/mnt/c/Program Files/Stata18/StataMP-64.exe` 完成 runner 配置（日志/runner meta 可审计）
- [x] 完整旅程可达终态（`succeeded`），且 artifacts 可下载
- [x] `output_formats` 默认 `["csv","log","do"]` 生效并产物可下载
- [x] `output_formats=["docx","pdf","xlsx","csv"]` 生效并产物可下载
- [x] `output_formats` 包含 `dta` 时（例如 `output_formats=["docx","pdf","xlsx","csv","dta"]`），`dta` 产物存在/可下载
- [x] `docker-compose restart ss-api ss-worker` 后 job 状态与 artifacts 可恢复且仍可下载；redeem 幂等
- [x] 关键命令与关键输出已记录（可回放）
- [x] Evidence: `openspec/_ops/task_runs/ISSUE-406.md`

## Completion
- PR: https://github.com/Leeky1017/SS/pull/411
- Evidence: `openspec/_ops/task_runs/ISSUE-406.md`
- Summary:
  - Documented Windows Server + Docker Desktop (WSL2) deployment notes and a Windows `SS_STATA_CMD` example (`/mnt/c/...`) with explicit bind-mount knobs.
  - Validated docker-compose E2E from health checks → job succeeded → artifacts downloadable; verified `output_formats` default + custom (+`dta`) and restart recovery.
  - Fixed `output_formats` persistence and `T07` template param mapping; pinned prod deps for docx/pdf/xlsx/dta formatting and added regression tests.
