# ISSUE-443

- Issue: #443
- Branch: task/443-archive-docker
- PR: https://github.com/Leeky1017/SS/pull/444

## Goal
- Archive Docker deployment artifacts and Docker-only OpenSpecs to avoid confusing non-Docker deployments.

## Status
- CURRENT: PR opened; enabling auto-merge and waiting for required checks.

## Next Actions
- [x] Move repo-root Docker artifacts into `legacy/docker/`
- [x] Archive Docker deployment OpenSpecs under `openspec/specs/archive/`
- [x] Run `openspec validate --specs --strict --no-interactive`
- [x] Run `scripts/agent_pr_preflight.sh` and open PR with auto-merge
- [ ] Enable auto-merge; watch checks
- [ ] Confirm merged; sync controlplane main; cleanup worktree

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

### 2026-01-13 11:12 PR preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-13 11:13 Create PR
- Command:
  - `gh pr create --title "Chore: 封存 Docker 部署资产 (#443)" --body "..."`
- Key output:
  - `https://github.com/Leeky1017/SS/pull/444`
