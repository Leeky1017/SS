from __future__ import annotations

import json
import os
import sys
import time
from dataclasses import dataclass
from pathlib import Path


def _percentile(sorted_values: list[float], pct: float) -> float:
    if not sorted_values:
        return 0.0
    if pct <= 0:
        return sorted_values[0]
    if pct >= 100:
        return sorted_values[-1]
    k = (len(sorted_values) - 1) * (pct / 100.0)
    f = int(k)
    c = min(f + 1, len(sorted_values) - 1)
    if f == c:
        return sorted_values[f]
    d0 = sorted_values[f] * (c - k)
    d1 = sorted_values[c] * (k - f)
    return d0 + d1


@dataclass(frozen=True)
class LatencySummary:
    total: int
    ok: int
    errors: int
    p50_ms: float
    p90_ms: float
    p99_ms: float

    @property
    def error_rate(self) -> float:
        if self.total == 0:
            return 0.0
        return self.errors / self.total


class LatencyRecorder:
    def __init__(self) -> None:
        self._durations_ms: list[float] = []
        self._total = 0
        self._errors = 0

    def record(self, *, duration_ms: float, ok: bool) -> None:
        self._total += 1
        if ok:
            self._durations_ms.append(duration_ms)
        else:
            self._errors += 1

    def summary(self) -> LatencySummary:
        durations = sorted(self._durations_ms)
        ok = len(durations)
        return LatencySummary(
            total=self._total,
            ok=ok,
            errors=self._errors,
            p50_ms=_percentile(durations, 50.0),
            p90_ms=_percentile(durations, 90.0),
            p99_ms=_percentile(durations, 99.0),
        )


@dataclass(frozen=True)
class ResourceSnapshot:
    timestamp: float
    rss_mb: float | None
    open_fds: int | None


def _read_proc_status_rss_mb() -> float | None:
    status_path = Path("/proc/self/status")
    if not status_path.exists():
        return None
    try:
        text = status_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None
    for line in text.splitlines():
        if not line.startswith("VmRSS:"):
            continue
        parts = line.split()
        if len(parts) < 2:
            return None
        try:
            kb = float(parts[1])
        except ValueError:
            return None
        return kb / 1024.0
    return None


def _ru_maxrss_mb() -> float | None:
    try:
        import resource
    except ModuleNotFoundError:
        return None
    usage = resource.getrusage(resource.RUSAGE_SELF)
    maxrss = float(usage.ru_maxrss)
    if sys.platform == "darwin":
        return maxrss / (1024.0 * 1024.0)
    return maxrss / 1024.0


def get_rss_mb() -> float | None:
    return _read_proc_status_rss_mb() or _ru_maxrss_mb()


def get_open_fd_count() -> int | None:
    proc_fd = Path("/proc/self/fd")
    if not proc_fd.exists():
        return None
    try:
        return len(list(proc_fd.iterdir()))
    except OSError:
        return None


def take_resource_snapshot() -> ResourceSnapshot:
    return ResourceSnapshot(
        timestamp=time.time(),
        rss_mb=get_rss_mb(),
        open_fds=get_open_fd_count(),
    )


def write_json_report(*, path: Path, payload: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def env_int(name: str, default: int) -> int:
    raw = os.getenv(name)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError:
        return default


def env_float(name: str, default: float) -> float:
    raw = os.getenv(name)
    if raw is None:
        return default
    try:
        return float(raw)
    except ValueError:
        return default

