#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/agent_pr_automerge_and_sync.sh [--pr <number>] [--no-create] [--no-sync] [options]

Behavior:
  - Expects current branch name: task/<N>-<slug>
  - Requires file exists in HEAD: openspec/_ops/task_runs/ISSUE-N.md
  - Runs preflight: scripts/agent_pr_preflight.sh (unless --skip-preflight)
    - If preflight fails: creates/keeps PR as draft and waits by default
  - Ensures a PR exists (creates one unless --no-create)
  - Enables auto-merge (squash), waits checks, waits merge
  - Syncs local controlplane main to origin/main (unless --no-sync)

Options:
  --skip-preflight           Skip preflight entirely
  --force                   Proceed even if preflight fails
  --no-wait-preflight        Fail fast if preflight fails (still creates draft PR)
  --wait-interval <seconds>  Preflight polling interval (default: 60)
  --wait-timeout <seconds>   Preflight wait timeout, 0 means forever (default: 0)
EOF
}

PR_NUMBER=""
NO_CREATE="false"
NO_SYNC="false"
SKIP_PREFLIGHT="false"
FORCE="false"
WAIT_PREFLIGHT="true"
WAIT_INTERVAL_SECONDS="60"
WAIT_TIMEOUT_SECONDS="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pr)
      PR_NUMBER="${2:-}"
      shift 2
      ;;
    --no-create)
      NO_CREATE="true"
      shift 1
      ;;
    --no-sync)
      NO_SYNC="true"
      shift 1
      ;;
    --skip-preflight)
      SKIP_PREFLIGHT="true"
      shift 1
      ;;
    --force)
      FORCE="true"
      shift 1
      ;;
    --no-wait-preflight)
      WAIT_PREFLIGHT="false"
      shift 1
      ;;
    --wait-interval)
      WAIT_INTERVAL_SECONDS="${2:-}"
      shift 2
      ;;
    --wait-timeout)
      WAIT_TIMEOUT_SECONDS="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ ! "$BRANCH" =~ ^task/([0-9]+)-([a-z0-9-]+)$ ]]; then
  echo "ERROR: branch must be task/<N>-<slug>, got: $BRANCH" >&2
  exit 2
fi

ISSUE_NUMBER="${BASH_REMATCH[1]}"
SLUG="${BASH_REMATCH[2]}"
RUN_LOG="openspec/_ops/task_runs/ISSUE-${ISSUE_NUMBER}.md"

if ! git cat-file -e "HEAD:${RUN_LOG}" 2>/dev/null; then
  echo "ERROR: run log missing in HEAD: ${RUN_LOG}" >&2
  exit 1
fi

PREFLIGHT_RC=0
if [[ "$SKIP_PREFLIGHT" != "true" ]]; then
  set +e
  scripts/agent_pr_preflight.sh
  PREFLIGHT_RC=$?
  set -e
fi

if [[ -z "$PR_NUMBER" ]]; then
  PR_NUMBER="$(gh pr list --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null || true)"
fi

if [[ -z "$PR_NUMBER" ]]; then
  if [[ "$NO_CREATE" == "true" ]]; then
    echo "ERROR: no PR found for branch $BRANCH and --no-create set" >&2
    exit 1
  fi

  TITLE="$(git log -1 --pretty=%s)"
  BODY=$(
    cat <<EOF
Closes #${ISSUE_NUMBER}

## Summary
- (fill)

## Test plan
- \`ruff check .\`
- \`pytest -q\`

## Evidence
- \`${RUN_LOG}\`
EOF
  )

  DRAFT_FLAG=""
  if [[ $PREFLIGHT_RC -ne 0 && "$FORCE" != "true" ]]; then
    DRAFT_FLAG="--draft"
  fi

  PR_URL="$(gh pr create --base main --head "$BRANCH" $DRAFT_FLAG --title "$TITLE" --body "$BODY")"
  PR_NUMBER="${PR_URL##*/}"
fi

if [[ $PREFLIGHT_RC -ne 0 && "$FORCE" != "true" ]]; then
  if [[ "$WAIT_PREFLIGHT" != "true" ]]; then
    echo "ERROR: preflight reported issues (exit ${PREFLIGHT_RC})." >&2
    echo "       Resolve/coordinate then re-run, or use --force / --skip-preflight." >&2
    exit 1
  fi

  echo "Preflight blocked (exit ${PREFLIGHT_RC}); waiting until it becomes OK (exit 0)." >&2
  echo "Tip: Ctrl-C to stop waiting; PR stays as draft." >&2

  START_TS="$(date +%s)"
  while true; do
    set +e
    scripts/agent_pr_preflight.sh
    PREFLIGHT_RC=$?
    set -e

    if [[ $PREFLIGHT_RC -eq 0 ]]; then
      break
    fi

    if [[ "$WAIT_TIMEOUT_SECONDS" != "0" ]]; then
      NOW_TS="$(date +%s)"
      if (( NOW_TS - START_TS >= WAIT_TIMEOUT_SECONDS )); then
        echo "ERROR: preflight still failing after ${WAIT_TIMEOUT_SECONDS}s (last exit ${PREFLIGHT_RC})." >&2
        exit 1
      fi
    fi

    sleep "$WAIT_INTERVAL_SECONDS"
  done
fi

IS_DRAFT="$(gh pr view "$PR_NUMBER" --json isDraft --jq '.isDraft')"
if [[ "$IS_DRAFT" == "true" ]]; then
  gh pr ready "$PR_NUMBER"
fi

gh pr merge "$PR_NUMBER" --auto --squash
gh pr checks "$PR_NUMBER" --watch

for _ in 1 2 3 4 5 6 7 8 9 10; do
  MERGED_AT="$(gh pr view "$PR_NUMBER" --json mergedAt --jq '.mergedAt')"
  if [[ "$MERGED_AT" != "null" && -n "$MERGED_AT" ]]; then
    break
  fi
  sleep 6
done

MERGED_AT="$(gh pr view "$PR_NUMBER" --json mergedAt --jq '.mergedAt')"
if [[ "$MERGED_AT" == "null" || -z "$MERGED_AT" ]]; then
  echo "ERROR: PR not merged yet: #$PR_NUMBER" >&2
  exit 1
fi

if [[ "$NO_SYNC" == "true" ]]; then
  exit 0
fi

scripts/agent_controlplane_sync.sh

COMMON_DIR="$(git rev-parse --git-common-dir)"
CONTROLPLANE_ROOT="$(cd "$(dirname "$COMMON_DIR")" && pwd)"

LOCAL_HEAD="$(git -C "$CONTROLPLANE_ROOT" rev-parse main)"
REMOTE_HEAD="$(git -C "$CONTROLPLANE_ROOT" rev-parse origin/main)"

if [[ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]]; then
  echo "ERROR: controlplane main not in sync with origin/main" >&2
  echo "  local : $LOCAL_HEAD" >&2
  echo "  remote: $REMOTE_HEAD" >&2
  exit 1
fi

echo "OK: merged PR #${PR_NUMBER} and synced controlplane main"
