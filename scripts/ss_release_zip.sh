#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/ss_release_zip.sh [--ref <git-ref>] [--out-dir <dir>]

Creates a zip archive from git-tracked files using `git archive`.

Defaults:
  --ref     HEAD
  --out-dir release
EOF
}

REF="HEAD"
OUT_DIR="release"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      REF="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
if [[ "$(pwd -P)" != "$(cd "$REPO_ROOT" && pwd -P)" ]]; then
  echo "ERROR: run this script from the repo root: $REPO_ROOT" >&2
  exit 2
fi

if ! git rev-parse --verify "$REF" >/dev/null 2>&1; then
  echo "ERROR: invalid git ref: $REF" >&2
  exit 2
fi

SHA="$(git rev-parse --short "$REF")"
STAMP="$(date -u +%Y%m%d-%H%M%S)"
OUT_PATH="${OUT_DIR}/SS-${STAMP}-g${SHA}.zip"

mkdir -p "$OUT_DIR"
git archive --format=zip --prefix="SS/" --output "$OUT_PATH" "$REF"

echo "Wrote: $OUT_PATH"
