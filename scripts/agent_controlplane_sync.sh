#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${1:-}" && "${1:-}" != "--help" ]]; then
  echo "Usage: scripts/agent_controlplane_sync.sh" >&2
  exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree is dirty; please commit or stash first." >&2
  exit 1
fi

git fetch origin main
git checkout main
git pull --ff-only origin main
