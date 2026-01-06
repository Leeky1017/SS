#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${1:-}" && "${1:-}" != "--help" ]]; then
  echo "Usage: scripts/agent_controlplane_sync.sh" >&2
  exit 2
fi

COMMON_DIR="$(git rev-parse --git-common-dir)"
CONTROLPLANE_ROOT="$(cd "$(dirname "$COMMON_DIR")" && pwd)"

if [[ -n "$(git -C "$CONTROLPLANE_ROOT" status --porcelain)" ]]; then
  echo "ERROR: controlplane working tree is dirty: $CONTROLPLANE_ROOT" >&2
  exit 1
fi

git -C "$CONTROLPLANE_ROOT" fetch origin main
git -C "$CONTROLPLANE_ROOT" checkout main
git -C "$CONTROLPLANE_ROOT" pull --ff-only origin main
