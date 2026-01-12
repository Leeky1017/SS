# [DEPLOY-READY] DEPLOY-READY-R020: 新增 requirements.txt（基于 pyproject.toml 导出并锁定）

## Metadata

- Priority: P1
- Issue: TBD
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-delivery-workflow/spec.md`

## Problem

生产镜像构建需要可复现的依赖锁定输入；仅有 `pyproject.toml` 的宽松版本约束不足以保证构建可重复与可回滚。

## Goal

为生产 Docker 构建提供明确的依赖锁定文件（优先 `requirements.txt`），并在 CI/README/部署资产中明确其使用方式。

## In scope

- 新增 `requirements.txt`（pinned，明确生成方式与更新策略）
- 明确与 `pyproject.toml` 的关系（source of truth 与导出方式）

## Out of scope

- 不要求引入新的包管理工具链，除非团队明确选择（例如 uv/poetry）

## Dependencies & parallelism

- Depends on: DEPLOY-READY-R010（Dockerfile 需要消费锁定文件）
- Can run in parallel with: DEPLOY-READY-R011

## Acceptance checklist

- [ ] 仓库根目录新增 `requirements.txt`（版本锁定）
- [ ] 记录生成命令与更新策略（可写入 run log 或 task evidence）
- [ ] Dockerfile 使用该锁定文件进行安装（或明确使用 lock file 的替代方案）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md`

