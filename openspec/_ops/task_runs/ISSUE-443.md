# ISSUE-443

- Issue: #443
- Branch: task/443-archive-docker
- PR: <fill-after-created>

## Goal
- Archive Docker deployment artifacts and Docker-only OpenSpecs to avoid confusing non-Docker deployments.

## Status
- CURRENT: Docker deployment artifacts/specs archived; validations green; preparing PR.

## Next Actions
- [x] Move repo-root Docker artifacts into `legacy/docker/`
- [x] Archive Docker deployment OpenSpecs under `openspec/specs/archive/`
- [x] Run `openspec validate --specs --strict --no-interactive`
- [ ] Run `scripts/agent_pr_preflight.sh` and open PR with auto-merge

## Decisions Made
- 2026-01-13 Archive Docker deployment path (non-Docker deployment is canonical).

## Runs
### 2026-01-13 10:58 Task start
- Command:
  - `gh issue create -t "Chore: 封存 Docker 部署资产" -b "<...>"`
  - `scripts/agent_worktree_setup.sh 443 archive-docker`
- Key output:
  - `Issue: https://github.com/Leeky1017/SS/issues/443`
  - `Worktree created: .worktrees/issue-443-archive-docker`

### 2026-01-13 11:06 Archive Docker deployment artifacts/specs
- Command:
  - `git mv Dockerfile legacy/docker/Dockerfile`
  - `git mv docker-compose.yml legacy/docker/docker-compose.yml`
  - `git mv .dockerignore legacy/docker/.dockerignore`
  - `git mv openspec/specs/ss-deployment-docker-minio openspec/specs/archive/ss-deployment-docker-minio`
  - `git mv openspec/specs/ss-deployment-docker-readiness openspec/specs/archive/ss-deployment-docker-readiness`
- Evidence:
  - `legacy/docker/`
  - `openspec/specs/archive/ss-deployment-docker-minio/`
  - `openspec/specs/archive/ss-deployment-docker-readiness/`

### 2026-01-13 11:07 Validate specs
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 29 passed, 0 failed (29 items)`

### 2026-01-13 11:08 Validate rulebook task
- Command:
  - `rulebook task validate issue-443-archive-docker`
- Key output:
  - `✅ Task issue-443-archive-docker is valid`
