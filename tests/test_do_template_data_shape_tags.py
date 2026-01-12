import json
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_do_meta_tags_when_auditing_data_shapes_include_wide_long_panel_coverage() -> None:
    # Arrange
    repo_root = _repo_root()
    meta_dir = repo_root / "assets" / "stata_do_library" / "do" / "meta"
    meta_files = sorted(meta_dir.glob("*.meta.json"))
    assert meta_files, f"no meta files found under {meta_dir}"

    counts: dict[str, int] = {"wide": 0, "long": 0, "panel": 0}
    for meta_path in meta_files:
        meta = _load_json(meta_path)
        tags = meta.get("tags", [])
        if not isinstance(tags, list):
            continue
        for tag in counts:
            if tag in tags:
                counts[tag] += 1

    # Assert
    assert counts["wide"] >= 2
    assert counts["long"] >= 2
    assert counts["panel"] >= 1


def test_do_meta_tags_when_template_is_shape_sensitive_include_expected_tags() -> None:
    # Arrange
    repo_root = _repo_root()
    meta_dir = repo_root / "assets" / "stata_do_library" / "do" / "meta"

    # Act
    t14 = _load_json(meta_dir / "T14_ttest_paired.meta.json")
    t30 = _load_json(meta_dir / "T30_panel_setup_check.meta.json")
    t31 = _load_json(meta_dir / "T31_panel_fe_basic.meta.json")

    # Assert
    assert "wide" in t14.get("tags", [])
    assert "panel" in t30.get("tags", [])
    assert "long" in t30.get("tags", [])
    assert "panel" in t31.get("tags", [])
    assert "long" in t31.get("tags", [])

