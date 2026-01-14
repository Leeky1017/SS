# ISSUE-465

- Issue: #465
- Branch: task/465-fe-cleanup-zhcn
- PR: <fill-after-created>

## Goal
- Remove unused legacy Desktop Pro frontend artifacts at repo root.
- Localize SS React Step 3 UI to Chinese-first with English term hints via `frontend/src/i18n/zh-CN.ts`.

## Status
- CURRENT: Worktree created; Rulebook task/spec delta validated; starting implementation.

## Next Actions
- [ ] Delete legacy root `index.html` and `assets/`
- [ ] Add `frontend/src/i18n/zh-CN.ts` and refactor Step 3 UI strings to reference it
- [ ] Run `npm run build` (frontend)
- [ ] Run `scripts/agent_pr_preflight.sh`, open PR, enable auto-merge, verify merged
- [ ] Sync controlplane `main`, cleanup worktree

## Decisions Made
- 2026-01-14 Use a single zh-CN term table and import it for all user-facing strings in Step 3 components.

## Runs
### 2026-01-14 14:38 Task start
- Command:
  - `gh issue create -t "[FE] Remove legacy Desktop Pro frontend + zh-CN terminology" -b "<...>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 465 fe-cleanup-zhcn`
- Key output:
  - `Issue: https://github.com/Leeky1017/SS/issues/465`
  - `Worktree created: .worktrees/issue-465-fe-cleanup-zhcn`
  - `Branch: task/465-fe-cleanup-zhcn`

### 2026-01-14 14:39 Rulebook task + spec delta
- Command:
  - `rulebook task create issue-465-fe-cleanup-zhcn`
  - `rulebook task validate issue-465-fe-cleanup-zhcn`
- Key output:
  - `✅ Task issue-465-fe-cleanup-zhcn is valid`
- Evidence:
  - `rulebook/tasks/issue-465-fe-cleanup-zhcn/`

### 2026-01-14 14:40 Remove legacy Desktop Pro root frontend
- Command:
  - `git rm -f index.html`
  - `git rm -r -f assets`
  - `git restore --staged assets/stata_do_library && git restore assets/stata_do_library`
- Key output:
  - `Removed: index.html + assets/desktop_pro_*`
  - `Preserved: assets/stata_do_library/`

### 2026-01-14 14:52 Frontend build
- Command:
  - `cd frontend && npm ci`
  - `cd frontend && npm run build`
- Key output:
  - `added 198 packages ...`
  - `✓ built ... dist/index.html`

### 2026-01-14 15:03 Verify root serves `frontend/dist/index.html`
- Command:
  - `SS_LLM_PROVIDER=local /home/leeky/work/SS/.venv/bin/uvicorn src.main:create_app --factory --host 127.0.0.1 --port 8010`
  - `curl -s -D - http://127.0.0.1:8010/ | head`
- Key output:
  - `HTTP/1.1 200 OK`
  - `content-type: text/html; charset=utf-8`

### 2026-01-14 15:03 Verify no references to removed Desktop Pro assets
- Command:
  - `rg -n "assets/desktop_pro|desktop_pro_" src frontend/src`
- Key output:
  - `<no matches>`
