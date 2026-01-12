# Proposal: issue-406-deploy-ready-r090

## Why
DEPLOY-READY-R090 是 Docker 部署就绪的 gate：必须用一次可复现的 docker-compose 端到端验证，把 “能启动 / 能执行 / 可下载产物 / 可重启恢复” 变成可审计证据，避免上线前隐藏断点（尤其是 Windows Server + Docker Desktop（WSL2）场景与 `SS_STATA_CMD` 路径/空格问题）。

## What Changes
- Update deployment readiness spec to include Windows + Docker Desktop (WSL2) scenario notes and a Windows Stata path example for `SS_STATA_CMD`.
- Update `docker-compose.yml` so `SS_STATA_CMD` can be injected explicitly (including WSL paths with spaces).
- Update the gate task card to explicitly scope the Windows deployment scenario and acceptance items.
- Produce an auditable run log with commands + key outputs + verdict.
- Fix E2E blockers discovered during the Docker readiness run:
  - Persist `output_formats` when triggering a run (ensures restart recovery + formatter determinism).
  - Add missing template params mapping for `T07` (`__NUMERIC_VARS__`) to unblock descriptive plans.
  - Regenerate `requirements.txt` so `docx`/`pdf` output formats work in production images (adds `python-docx`/`reportlab` + deps).
  - Add regression tests for the above.

## Impact
- Affected specs:
  - `openspec/specs/ss-deployment-docker-readiness/spec.md`
  - `openspec/specs/ss-deployment-docker-readiness/task_cards/gate__DEPLOY-READY-R090.md`
- Affected code:
  - `docker-compose.yml`
  - `requirements.txt`
  - `src/domain/do_template_plan_support.py`
  - `src/domain/job_service.py`
  - `src/worker.py`
  - `tests/test_job_service.py`
  - `tests/test_do_template_plan_support_template_params.py`
- Breaking change: YES (compose now requires explicit `SS_STATA_CMD` injection via env)
- User benefit: A runnable, replayable Docker E2E verification path for production go/no-go, including Windows deployment notes.
