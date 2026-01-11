from __future__ import annotations

from pathlib import Path

from src.config import load_config


def test_load_config_with_ss_stata_cmd_path_with_spaces_returns_single_arg(tmp_path: Path) -> None:
    stata_exe = tmp_path / "Program Files" / "Stata18" / "StataMP-64.exe"
    stata_exe.parent.mkdir(parents=True, exist_ok=True)
    stata_exe.write_text("dummy", encoding="utf-8")

    config = load_config(
        env={
            "SS_LLM_PROVIDER": "yunwu",
            "SS_LLM_API_KEY": "test-key",
            "SS_STATA_CMD": str(stata_exe),
            "SS_JOBS_DIR": str(tmp_path / "jobs"),
            "SS_QUEUE_DIR": str(tmp_path / "queue"),
        }
    )

    assert config.stata_cmd == (str(stata_exe),)
