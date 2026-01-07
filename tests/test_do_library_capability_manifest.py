import json
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def test_capability_manifest_has_no_hardcoded_ado_path() -> None:
    repo_root = _repo_root()
    manifest_path = repo_root / "assets/stata_do_library/CAPABILITY_MANIFEST.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    assert "ado_path" not in manifest
