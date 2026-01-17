from __future__ import annotations

import contextlib
import dataclasses
import socket
import subprocess
import time

from ss_ssh_e2e.errors import E2EError


def ssh_base_args(*, identity_file: str, port: int) -> list[str]:
    return [
        "-i",
        identity_file,
        "-p",
        str(port),
        "-o",
        "StrictHostKeyChecking=no",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "ConnectTimeout=10",
        "-o",
        "ServerAliveInterval=15",
        "-o",
        "ServerAliveCountMax=4",
    ]


def pick_free_port() -> int:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.bind(("127.0.0.1", 0))
        return int(s.getsockname()[1])
    finally:
        s.close()


@dataclasses.dataclass(frozen=True)
class Tunnel:
    local_port: int
    proc: subprocess.Popen[str]

    def close(self) -> None:
        if self.proc.poll() is not None:
            return
        try:
            self.proc.terminate()
        except (ProcessLookupError, OSError):
            return
        try:
            self.proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            try:
                self.proc.kill()
            except (ProcessLookupError, OSError):
                return
            with contextlib.suppress(subprocess.TimeoutExpired):
                self.proc.wait(timeout=5)


@contextlib.contextmanager
def ssh_tunnel(
    *,
    user: str,
    host: str,
    port: int,
    identity_file: str,
    local_port: int,
    remote_host: str,
    remote_port: int,
    ready_timeout_seconds: float,
) -> Tunnel:
    forward = f"{local_port}:{remote_host}:{remote_port}"
    cmd = [
        "ssh",
        *ssh_base_args(identity_file=identity_file, port=port),
        "-o",
        "ExitOnForwardFailure=yes",
        "-N",
        "-L",
        forward,
        f"{user}@{host}",
    ]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    tunnel = Tunnel(local_port=local_port, proc=proc)
    try:
        wait_local_port_open(port=local_port, timeout_seconds=ready_timeout_seconds, proc=proc)
        yield tunnel
    finally:
        tunnel.close()


def wait_local_port_open(*, port: int, timeout_seconds: float, proc: subprocess.Popen[str]) -> None:
    deadline = time.time() + timeout_seconds
    while time.time() < deadline:
        if proc.poll() is not None:
            stderr = (proc.stderr.read() if proc.stderr else "")[:2000]
            raise E2EError(
                event_code="SSE2E_SSH_TUNNEL_FAILED",
                message=f"ssh tunnel exited early (exit={proc.returncode})",
                details={"stderr": stderr},
            )
        with contextlib.suppress(OSError):
            s = socket.create_connection(("127.0.0.1", port), timeout=1.0)
            s.close()
            return
        time.sleep(0.2)
    raise E2EError(
        event_code="SSE2E_SSH_TUNNEL_TIMEOUT",
        message=f"tunnel local port did not open within {timeout_seconds}s",
    )

