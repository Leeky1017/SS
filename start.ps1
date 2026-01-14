[CmdletBinding()]
param(
    [string]$EnvFile = ".env",
    [switch]$NoWorker,
    [switch]$SkipInstall,
    [switch]$ForceInstall,
    [string]$VenvDir = "",
    [string]$WorkerLogPath = "worker.log"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Import-DotEnvIfPresent {
    param([string]$RootDir, [string]$EnvFilePath)

    $envPath = Join-Path $RootDir $EnvFilePath
    if (-not (Test-Path $envPath)) {
        Write-Host "No .env file found at: $envPath (continuing)"
        return
    }

    Get-Content $envPath | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        if ($line.StartsWith("export ")) { $line = $line.Substring(7).TrimStart() }
        $parts = $line.Split("=", 2)
        if ($parts.Length -ne 2) { return }

        $key = $parts[0].Trim()
        if ([string]::IsNullOrWhiteSpace($key)) { return }

        $value = $parts[1].Trim()
        if ($value.Length -ge 2) {
            $q = $value.Substring(0, 1)
            if (($q -eq "'" -or $q -eq '"') -and $value.EndsWith($q)) {
                $value = $value.Substring(1, $value.Length - 2)
            }
        }

        $existing = [System.Environment]::GetEnvironmentVariable($key)
        if ([string]::IsNullOrEmpty($existing)) {
            Set-Item -Path ("Env:" + $key) -Value $value
        }
    }

    Write-Host "Loaded .env into process environment (non-overriding)."
}

function Resolve-VenvDir {
    param([string]$RootDir, [string]$PreferredVenvDir)

    if (-not [string]::IsNullOrWhiteSpace($PreferredVenvDir)) {
        return $PreferredVenvDir
    }

    foreach ($candidate in @(".venv", "venv")) {
        if (Test-Path (Join-Path $RootDir $candidate)) {
            return $candidate
        }
    }

    return ".venv"
}

function Resolve-PythonBootstrap {
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        return @{ kind = "python"; exe = $pythonCmd.Source; args = @() }
    }

    $pyCmd = Get-Command py -ErrorAction SilentlyContinue
    if ($pyCmd) {
        return @{ kind = "py"; exe = $pyCmd.Source; args = @("-3") }
    }

    throw "Python not found. Install Python 3.x or ensure 'python'/'py' is in PATH."
}

function Ensure-VenvPython {
    param([string]$RootDir, [string]$ResolvedVenvDir, [switch]$SkipInstallDeps, [switch]$AlwaysInstallDeps)

    $venvPath = Join-Path $RootDir $ResolvedVenvDir
    $venvPython = Join-Path $venvPath "Scripts" "python.exe"
    $created = $false

    if (-not (Test-Path $venvPython)) {
        $bootstrap = Resolve-PythonBootstrap
        $bootstrapArgs = $bootstrap.args + @("-m", "venv", $venvPath)
        Write-Host "Creating venv: $venvPath"
        & $bootstrap.exe @bootstrapArgs
        $created = $true
    }

    if (-not (Test-Path $venvPython)) {
        throw "Venv python not found after creation attempt: $venvPython"
    }

    if (-not $SkipInstallDeps -and ($created -or $AlwaysInstallDeps)) {
        Write-Host "Installing runtime deps into venv (editable): pip install -e ."
        & $venvPython -m pip install -e .
    }

    return $venvPython
}

Import-DotEnvIfPresent -RootDir $Root -EnvFilePath $EnvFile

$resolvedVenvDir = Resolve-VenvDir -RootDir $Root -PreferredVenvDir $VenvDir
$python = Ensure-VenvPython -RootDir $Root -ResolvedVenvDir $resolvedVenvDir -SkipInstallDeps:$SkipInstall -AlwaysInstallDeps:$ForceInstall
Write-Host "Using python: $python"

$workerProc = $null
$workerLog = Join-Path $Root $WorkerLogPath
$workerLogDir = Split-Path -Parent $workerLog
if (-not [string]::IsNullOrWhiteSpace($workerLogDir) -and -not (Test-Path $workerLogDir)) {
    New-Item -ItemType Directory -Force -Path $workerLogDir | Out-Null
}

if (-not $NoWorker) {
    Write-Host "Starting worker: $python -m src.worker (logs: $workerLog)"
    $workerProc = Start-Process `
        -FilePath $python `
        -ArgumentList @("-m", "src.worker") `
        -WorkingDirectory $Root `
        -RedirectStandardOutput $workerLog `
        -RedirectStandardError $workerLog `
        -PassThru

    Start-Sleep -Seconds 1
    if ($workerProc.HasExited) {
        Write-Host "Worker exited early (exit code: $($workerProc.ExitCode)). Tail of log:"
        if (Test-Path $workerLog) {
            Get-Content -Path $workerLog -Tail 80
        }
        throw "Worker failed to start."
    }

    Write-Host "Worker PID: $($workerProc.Id)"
}

$apiExitCode = 0
try {
    Write-Host "Starting API: $python -m src.main (Ctrl+C to stop)"
    & $python -m src.main
    $apiExitCode = $LASTEXITCODE
} finally {
    if ($workerProc -ne $null) {
        try {
            $p = Get-Process -Id $workerProc.Id -ErrorAction Stop
            Write-Host "Stopping worker PID: $($p.Id)"
            Stop-Process -Id $p.Id -Force -ErrorAction Stop
        } catch [System.ArgumentException] {
            Write-Host "Worker already stopped."
        }
    }
}

exit $apiExitCode
