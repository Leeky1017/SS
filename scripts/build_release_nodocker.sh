#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_dir="${root_dir}/releases"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
cd "${root_dir}"
version="$(
  python3 - <<'PY'
from __future__ import annotations

import pathlib
import tomllib

data = tomllib.loads(pathlib.Path("pyproject.toml").read_text(encoding="utf-8"))
project = data.get("project", {})
print(project.get("version", "0.0.0"))
PY
)"

name="ss-${version}-nodocker-${timestamp}"
stage_dir="${out_dir}/${name}"
tarball="${out_dir}/${name}.tar.gz"
zipball="${out_dir}/${name}.zip"

mkdir -p "${out_dir}"
rm -rf "${stage_dir}"
mkdir -p "${stage_dir}"

cp "${root_dir}/requirements.txt" "${stage_dir}/"
cp "${root_dir}/pyproject.toml" "${stage_dir}/"
cp "${root_dir}/README.md" "${stage_dir}/"
cp "${root_dir}/DEPENDENCIES.md" "${stage_dir}/"
cp "${root_dir}/.env.example" "${stage_dir}/.env.example"

rsync -a --delete --exclude "__pycache__/" --exclude "*.pyc" "${root_dir}/src/" "${stage_dir}/src/"
rsync -a --delete --exclude "__pycache__/" --exclude "*.pyc" "${root_dir}/assets/" "${stage_dir}/assets/"

if [ -d "${root_dir}/frontend/dist" ]; then
  mkdir -p "${stage_dir}/frontend"
  rsync -a --delete "${root_dir}/frontend/dist/" "${stage_dir}/frontend/dist/"
fi

mkdir -p "${stage_dir}/jobs" "${stage_dir}/queue"

mkdir -p "${stage_dir}/bin"
cat >"${stage_dir}/bin/install.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 -m venv .venv
. .venv/bin/activate
pip install -U pip
pip install -r requirements.txt
EOF

cat >"${stage_dir}/bin/install.ps1" <<'EOF'
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (Get-Command python -ErrorAction SilentlyContinue) {
  $pythonCmd = "python"
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
  $pythonCmd = "py"
} else {
  throw "Python not found in PATH (need Python >= 3.12)"
}

& $pythonCmd -m venv .venv
& .\.venv\Scripts\python.exe -m pip install -U pip
& .\.venv\Scripts\python.exe -m pip install -r requirements.txt
EOF

cat >"${stage_dir}/bin/run_api.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ ! -x ".venv/bin/python" ]; then
  echo "missing .venv; run bin/install.sh first" >&2
  exit 1
fi
if [ -f ".env" ]; then
  set -a
  . ./.env
  set +a
fi
exec .venv/bin/python -m src.main
EOF

cat >"${stage_dir}/bin/run_api.ps1" <<'EOF'
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Import-DotEnv([string]$path) {
  if (-not (Test-Path $path)) { return }
  foreach ($line in Get-Content $path) {
    $trim = $line.Trim()
    if ($trim -eq "" -or $trim.StartsWith("#")) { continue }
    if ($trim.StartsWith("export ")) { $trim = $trim.Substring(7).Trim() }
    $parts = $trim.Split("=", 2)
    if ($parts.Length -ne 2) { continue }
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    if (
      ($value.StartsWith('"') -and $value.EndsWith('"')) -or
      ($value.StartsWith("'") -and $value.EndsWith("'"))
    ) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    Set-Item -Path "Env:$key" -Value $value
  }
}

Import-DotEnv ".\\.env"

if (-not (Test-Path ".\\.venv\\Scripts\\python.exe")) {
  Write-Error "missing .venv; run bin\\install.ps1 first"
  exit 1
}

& .\.venv\Scripts\python.exe -m src.main
EOF

cat >"${stage_dir}/bin/run_worker.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ ! -x ".venv/bin/python" ]; then
  echo "missing .venv; run bin/install.sh first" >&2
  exit 1
fi
if [ -f ".env" ]; then
  set -a
  . ./.env
  set +a
fi
exec .venv/bin/python -m src.worker
EOF

chmod +x "${stage_dir}/bin/"*.sh

cat >"${stage_dir}/bin/run_worker.ps1" <<'EOF'
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Import-DotEnv([string]$path) {
  if (-not (Test-Path $path)) { return }
  foreach ($line in Get-Content $path) {
    $trim = $line.Trim()
    if ($trim -eq "" -or $trim.StartsWith("#")) { continue }
    if ($trim.StartsWith("export ")) { $trim = $trim.Substring(7).Trim() }
    $parts = $trim.Split("=", 2)
    if ($parts.Length -ne 2) { continue }
    $key = $parts[0].Trim()
    $value = $parts[1].Trim()
    if (
      ($value.StartsWith('"') -and $value.EndsWith('"')) -or
      ($value.StartsWith("'") -and $value.EndsWith("'"))
    ) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    Set-Item -Path "Env:$key" -Value $value
  }
}

Import-DotEnv ".\\.env"

if (-not (Test-Path ".\\.venv\\Scripts\\python.exe")) {
  Write-Error "missing .venv; run bin\\install.ps1 first"
  exit 1
}

& .\.venv\Scripts\python.exe -m src.worker
EOF

cat >"${stage_dir}/bin/run_api.cmd" <<'EOF'
@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0run_api.ps1"
EOF

cat >"${stage_dir}/bin/run_worker.cmd" <<'EOF'
@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0run_worker.ps1"
EOF

cat >"${stage_dir}/bin/install.cmd" <<'EOF'
@echo off
setlocal
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1"
EOF

cat >"${stage_dir}/DEPLOY_NON_DOCKER.md" <<'EOF'
# SS non-docker deployment

## Prerequisites

- Python >= 3.12
- (Worker) Stata installed and `SS_STATA_CMD` configured

## Install (Linux/macOS)

```bash
tar -xzf ss-<version>-nodocker-<timestamp>.tar.gz
cd ss-<version>-nodocker-<timestamp>
cp .env.example .env
# edit .env (set SS_LLM_PROVIDER / SS_LLM_API_KEY / SS_LLM_MODEL / SS_STATA_CMD ...)
./bin/install.sh
```

## Run (Linux/macOS)

API:

```bash
./bin/run_api.sh
```

Worker:

```bash
./bin/run_worker.sh
```

## Install (Windows)

1) Unzip `ss-<version>-nodocker-<timestamp>.zip`
2) Open PowerShell in the extracted folder:

```powershell
copy .env.example .env
# edit .env (set SS_LLM_PROVIDER / SS_LLM_API_KEY / SS_LLM_MODEL / SS_STATA_CMD ...)
powershell -ExecutionPolicy Bypass -File .\bin\install.ps1
```

## Run (Windows)

API:

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\run_api.ps1
# or: .\bin\run_api.cmd
```

Worker:

```powershell
powershell -ExecutionPolicy Bypass -File .\bin\run_worker.ps1
# or: .\bin\run_worker.cmd
```
EOF

tar -czf "${tarball}" -C "${out_dir}" "${name}"
python3 - <<PY
from __future__ import annotations

import pathlib
import shutil

out_dir = pathlib.Path(${out_dir@Q})
name = ${name@Q}
base_name = str(out_dir / name)
shutil.make_archive(base_name, "zip", root_dir=str(out_dir), base_dir=str(name))
PY

echo "built: ${tarball}"
echo "built: ${zipball}"
