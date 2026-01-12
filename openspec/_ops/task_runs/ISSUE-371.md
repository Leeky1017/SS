# ISSUE-371
- Issue: #371
- Branch: task/371-deploy-ready-r003
- PR: https://github.com/Leeky1017/SS/pull/378

## Plan
- Inventory current Docker/compose assets and runtime entrypoints (API/worker/Stata).
- Compare against `openspec/specs/ss-deployment-docker-readiness/spec.md` and produce a numbered gap list with priority + mapped remediation cards.
- Document minimal compose topology (MinIO + ss-api + ss-worker), key volumes, and Stata provisioning decision points/risks.

## Runs
### 2026-01-12 21:18 GitHub auth
- Command: `gh auth status`
- Key output: `Logged in to github.com account Leeky1017`
- Evidence: `gh auth status`

### 2026-01-12 21:18 Create issue
- Command: `gh issue create -t "[DEPLOY-READY] DEPLOY-READY-R003: Audit Docker deploy readiness gaps" ...`
- Key output: `https://github.com/Leeky1017/SS/issues/371`
- Evidence: `openspec/specs/ss-deployment-docker-readiness/task_cards/audit__DEPLOY-READY-R003.md`

### 2026-01-12 21:19 Worktree
- Command: `scripts/agent_worktree_setup.sh "371" "deploy-ready-r003"`
- Key output: `Worktree created: .worktrees/issue-371-deploy-ready-r003`
- Evidence: `git worktree list`

### 2026-01-12 21:19 Rulebook task
- Command: `rulebook task create issue-371-deploy-ready-r003`
- Key output: `Location: rulebook/tasks/issue-371-deploy-ready-r003/`
- Evidence: `rulebook/tasks/issue-371-deploy-ready-r003/`

### 2026-01-12 21:25 Inventory Docker assets
- Command: `find . (Dockerfile/docker-compose)`
- Key output: `./openspec/specs/ss-deployment-docker-minio/assets/docker-compose.yml` (no repo-root `Dockerfile`, no repo-root `docker-compose.yml`)
- Evidence: `openspec/specs/ss-deployment-docker-minio/assets/docker-compose.yml`

### 2026-01-12 21:25 Inventory dependency locks
- Command: `find . (requirements.txt/uv.lock/poetry.lock)`
- Key output: `none found at repo root`
- Evidence: `pyproject.toml`

### 2026-01-12 21:26 Scan for output_formats support
- Command: `rg -n "output_formats" -S src`
- Key output: `NO_MATCHES`
- Evidence: `openspec/specs/ss-deployment-docker-readiness/spec.md`

### 2026-01-12 21:26 Confirm worker Stata gate (fail fast)
- Command: `rg -n "STATA_CMD_NOT_CONFIGURED" -n src/worker.py`
- Key output: `src/worker.py:76 error_code="STATA_CMD_NOT_CONFIGURED"`
- Evidence: `src/worker.py`

### 2026-01-12 21:26 Confirm do-template capability evidence exists
- Command: `ls assets/stata_do_library | rg CAPABILITY_MANIFEST`
- Key output: `CAPABILITY_MANIFEST.json (plus DO_LIBRARY_INDEX.json, DO_INVENTORY.csv)`
- Evidence: `assets/stata_do_library/CAPABILITY_MANIFEST.json`

### 2026-01-12 21:30 Local validation environment
- Command: `python3 -m venv .venv && .venv/bin/python -m pip install -e '.[dev]'`
- Key output: `installed editable ss + dev dependencies in .venv/`
- Evidence: `.venv/` (gitignored)

### 2026-01-12 21:31 ruff
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `ruff check .`

### 2026-01-12 21:31 pytest
- Command: `.venv/bin/pytest -q`
- Key output: `184 passed, 5 skipped`
- Evidence: `pytest -q`

### 2026-01-12 21:32 PR preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`
- Evidence: `scripts/agent_pr_preflight.sh`

### 2026-01-12 21:45 PR + auto-merge
- Command: `gh pr create ...`
- Key output: `https://github.com/Leeky1017/SS/pull/378`
- Evidence: `openspec/_ops/task_runs/ISSUE-371.md`

### 2026-01-12 21:45 Enable auto-merge
- Command: `gh pr merge --auto --squash`
- Key output: `PR will be automatically merged via squash when all requirements are met`
- Evidence: `gh pr view 378 --json autoMergeRequest`

### 2026-01-12 21:46 Rebase (PR was BEHIND)
- Command: `git rebase origin/main && git push --force-with-lease`
- Key output: `mergeStateStatus=BEHIND -> updated branch`
- Evidence: `gh pr view 378 --json mergeStateStatus`

### 2026-01-12 21:49 Merge verified
- Command: `gh pr view 378 --json mergedAt,state`
- Key output: `state=MERGED mergedAt=2026-01-12T05:49:13Z`
- Evidence: `gh pr view 378`

### 2026-01-12 22:00 Rulebook archive
- Command: `rulebook task archive issue-371-deploy-ready-r003`
- Key output: `moved to rulebook/tasks/archive/2026-01-12-issue-371-deploy-ready-r003/`
- Evidence: `rulebook/tasks/archive/2026-01-12-issue-371-deploy-ready-r003/`

## Findings

### Gap list (ss-deployment-docker-readiness)

Numbering note: `DR-REQ-01..09` follow the order of `openspec/specs/ss-deployment-docker-readiness/spec.md`.

- DR-REQ-01 (Production Dockerfile for API + worker): **GAP**
  - Status: missing
  - Evidence: repo root has no `Dockerfile`; API/worker entrypoints exist (`src/main.py`, `src/worker.py`)
  - Risk: cannot build a reproducible production image; no standard deploy artifact; blocks compose + E2E gate
  - Priority: P0
  - Recommended task card(s): DEPLOY-READY-R010 (Dockerfile), DEPLOY-READY-R020 (pinned deps)

- DR-REQ-02 (docker-compose: minio + ss-api + ss-worker + durable jobs/queue): **GAP**
  - Status: partial (spec asset exists, but not production-ready and not repo-root)
  - Evidence: `openspec/specs/ss-deployment-docker-minio/assets/docker-compose.yml` defines `minio` + `ss` (single process), no `ss-worker`
  - Risk: cannot reach “enqueue → worker executes → artifacts downloadable” in Docker; blocks E2E gate
  - Priority: P0
  - Recommended task card(s): DEPLOY-READY-R011 (compose topology), depends on DEPLOY-READY-R010 (image)

- DR-REQ-03 (Stata provisioning strategy explicit + configurable; worker gated on `SS_STATA_CMD`): **GAP (deployment asset)**
  - Status: code-level OK; deployment-level missing
  - Evidence: worker requires `SS_STATA_CMD` and fails fast (`src/worker.py`); no Dockerfile/compose strategy wiring yet
  - Risk: production deploy blocked by license/path/mount ambiguity; highest-risk deployment dependency
  - Priority: P0
  - Recommended task card(s): DEPLOY-READY-R012 (Stata strategy), plus DEPLOY-READY-R011 (compose inject/mount)

- DR-REQ-04 (Pinned Python deps for production builds): **GAP**
  - Status: missing (only `pyproject.toml` with `>=` constraints)
  - Evidence: no repo-root `requirements.txt` / lock file
  - Risk: production builds are not reproducible; hard to rollback/debug
  - Priority: P1
  - Recommended task card(s): DEPLOY-READY-R020 (requirements.txt lock), then wire into DEPLOY-READY-R010 Dockerfile

- DR-REQ-05 (Supported upload formats CSV/XLSX/XLS/DTA explicit + validated): **PARTIAL**
  - Status: formats supported; error message does not enumerate supported formats
  - Evidence: `src/domain/inputs_manifest.py` accepts `.csv/.xls/.xlsx/.dta`; unsupported raises `INPUT_UNSUPPORTED_FORMAT`
  - Risk: clients do not get an explicit “supported formats” list from the structured error
  - Priority: P2
  - Recommended task card(s): (not in R010/R011/R012/R020); consider follow-up under inputs/upload specs

- DR-REQ-06 (Do-template capability statement auditable: wide/long/panel): **OK**
  - Evidence: `assets/stata_do_library/CAPABILITY_MANIFEST.json`, `assets/stata_do_library/DO_LIBRARY_INDEX.json`, `assets/stata_do_library/DO_INVENTORY.csv`

- DR-REQ-07 (Raw artifacts CSV/LOG/DO preserved + indexed): **PARTIAL**
  - Status: indexing exists; baseline raw artifacts are not explicitly enforced as “always present” across templates
  - Evidence: artifacts index in `job.json` (`src/domain/models.py`); runner captures DO/LOG; template meta drives archived outputs
  - Risk: without an explicit enforcement + post-run policy, “minimum raw artifacts” can drift per-template
  - Priority: P1
  - Recommended task card(s): DEPLOY-READY-R031 (Output Formatter, unify artifact policy)

- DR-REQ-08 (Unified Output Formatter + `output_formats`): **GAP**
  - Status: missing
  - Evidence: no `output_formats` parameter in `src/`; no post-run Output Formatter step
  - Risk: output behavior fragmented per-template; cannot guarantee format coverage in production deploy
  - Priority: P0
  - Recommended task card(s): DEPLOY-READY-R031

- DR-REQ-09 (Docker deployment gate: `docker-compose up` → READY end-to-end): **GAP**
  - Status: gate task exists; needs implementation/verification evidence
  - Evidence: `openspec/specs/ss-deployment-docker-readiness/task_cards/gate__DEPLOY-READY-R090.md`
  - Risk: production readiness cannot be proven; regressions likely
  - Priority: P0
  - Recommended task card(s): DEPLOY-READY-R090 (gate task)

### Minimal production docker-compose topology (MinIO + ss-api + ss-worker)

Minimum services:
- `minio`: S3-compatible object store (production upload backend baseline)
- `ss-api`: HTTP API (`python -m src.main` or equivalent entrypoint)
- `ss-worker`: background worker loop (`python -m src.worker` or equivalent entrypoint)

Minimum durable volumes:
- `minio-data`: `/data` (MinIO)
- `ss-jobs`: `/var/lib/ss/jobs` (job workspace + artifacts)
- `ss-queue`: `/var/lib/ss/queue` (file-backed queue)

Strategy-dependent volumes:
- Stata (host-mounted strategy): bind mount host Stata install path into container (read-only), then set `SS_STATA_CMD` to the mounted executable
- Do-template library (if not baked into image): bind mount `assets/stata_do_library` (read-only) and set `SS_DO_TEMPLATE_LIBRARY_DIR`

Minimal skeleton (illustrative; implemented by DEPLOY-READY-R011):
```yaml
services:
  minio: { ... }
  ss-api: { image: ss:prod, command: ["python", "-m", "src.main"], volumes: ["ss-jobs:/var/lib/ss/jobs", "ss-queue:/var/lib/ss/queue"] }
  ss-worker: { image: ss:prod, command: ["python", "-m", "src.worker"], volumes: ["ss-jobs:/var/lib/ss/jobs", "ss-queue:/var/lib/ss/queue"] }
volumes:
  minio-data: {}
  ss-jobs: {}
  ss-queue: {}
```

MinIO endpoint signing risk (from `ss-deployment-docker-minio`):
- `SS_UPLOAD_S3_ENDPOINT` must be the *same* endpoint used for presign and for SS-side S3 calls, and must be client-reachable (no internal-vs-external host mismatch).

### Stata provisioning strategy: decision points & risks

Decision points:
- Strategy choice: image-bundled vs host-mounted
- Mount + path contract: stable mount path and a single canonical `SS_STATA_CMD` contract for production
- Container user/permissions: ensure the container user can execute Stata and write to jobs/queue dirs

Risks:
- License/compliance: Stata is proprietary; shipping installers/licenses in image or repo is not acceptable
- OS/ABI mismatch: host-mounted requires the container runtime to match the host Stata binary ABI (Linux-on-Linux recommended)
- Path quoting/args: `SS_STATA_CMD` must be injected explicitly; worker fails fast when missing (`STATA_CMD_NOT_CONFIGURED`)

Recommendation (minimal-risk default):
- Prefer host-mounted Stata for production first, with a documented mount path and explicit `SS_STATA_CMD` (DEPLOY-READY-R012).

### Minimal remediation path (smallest deployable chain)

1) DEPLOY-READY-R010: repo-root `Dockerfile` builds a production image with both entrypoints (API/worker)
2) DEPLOY-READY-R020: add a pinned `requirements.txt` (or lock file) and make Dockerfile consume it
3) DEPLOY-READY-R012: decide + document Stata strategy, including mount path + `SS_STATA_CMD` injection contract
4) DEPLOY-READY-R011: repo-root `docker-compose.yml` with `minio` + `ss-api` + `ss-worker` + durable volumes + Stata/do-lib wiring
5) DEPLOY-READY-R090: run the Docker E2E gate (compose up → job journey → artifacts) and record evidence
