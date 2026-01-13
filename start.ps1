Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Enable-VenvIfPresent {
    $candidates = @(".venv", "venv")
    foreach ($venv in $candidates) {
        $activate = Join-Path $Root $venv "Scripts" "Activate.ps1"
        if (Test-Path $activate) {
            . $activate
            Write-Host "Activated venv: $venv"
            return
        }
    }
    Write-Host "No venv found (.venv/venv). Continuing with system Python."
}

function Import-DotEnvIfPresent {
    $envPath = Join-Path $Root ".env"
    if (-not (Test-Path $envPath)) {
        Write-Host "No .env file found. Continuing."
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

Enable-VenvIfPresent
Import-DotEnvIfPresent

$python = (Get-Command python -ErrorAction Stop).Source

$workerLog = Join-Path $Root "worker.log"
Write-Host "Starting worker: python -m src.worker (logs: $workerLog)"
Start-Process -FilePath $python -ArgumentList @("-m", "src.worker") -WorkingDirectory $Root -RedirectStandardOutput $workerLog -RedirectStandardError $workerLog

Write-Host "Starting API: python -m src.main"
& $python -m src.main
