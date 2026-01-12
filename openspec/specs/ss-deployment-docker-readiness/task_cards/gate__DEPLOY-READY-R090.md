# [DEPLOY-READY] DEPLOY-READY-R090: Docker 部署端到端验证（docker-compose up → 完整旅程 → READY）

## Metadata

- Priority: P0
- Issue: TBD
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

## Goal

提供一条从 `docker-compose up` 到 “READY” 的端到端验证流程与证据，覆盖最小用户旅程：
1) 启动 services（minio + ss-api + ss-worker）
2) 创建 job 并上传数据（至少 CSV；如支持则覆盖 XLSX/XLS/DTA）
3) 触发执行并等待完成
4) 验证 artifacts 可下载，且包含 `output_formats` 请求的格式

## In scope

- 编写/固化一份可复现的 E2E 验证步骤（命令 + 预期输出）
- （可选）提供一个自检脚本用于自动化验证

## Out of scope

- 不在本卡进行生产级压测与容量评估

## Dependencies & parallelism

- Depends on: DEPLOY-READY-R010, DEPLOY-READY-R011, DEPLOY-READY-R012, DEPLOY-READY-R031
- Can run in parallel with: none (gate task)

## Acceptance checklist

- [ ] `docker-compose up` 可启动并保持 ss-api/ss-worker 稳定运行
- [ ] 完整旅程可达终态（succeeded），且 artifacts 可下载
- [ ] 若指定 `output_formats`，对应格式产物存在（至少覆盖 csv/log/do + 选配 docx/pdf/xlsx/dta）
- [ ] 关键命令与关键输出已记录（可回放）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md`

