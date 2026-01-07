from __future__ import annotations

from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def test_do_library_templates_when_scanned_have_no_deprecated_placeholders() -> None:
    repo_root = _repo_root()
    targets = (
        repo_root / "assets/stata_do_library/do",
        repo_root / "assets/stata_do_library/do/meta",
    )
    deprecated = (b"__DEP_VAR__", b"__INDEP_VARS__", b"__TIMEVAR__")

    violations: list[str] = []
    for target in targets:
        for path in sorted(target.rglob("*")):
            if not path.is_file():
                continue
            if path.suffix not in {".do", ".json"}:
                continue
            blob = path.read_bytes()
            for token in deprecated:
                if token in blob:
                    violations.append(f"{path}: contains {token.decode('utf-8')}")

    assert not violations, "deprecated placeholders found:\n" + "\n".join(violations)

