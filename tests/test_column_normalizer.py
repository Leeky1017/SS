from __future__ import annotations

import re

from src.domain.column_normalizer import build_draft_column_name_normalizations
from src.domain.draft_column_candidate_models import DraftColumnCandidateV2

_STATA_NAME_RE = re.compile(r"^[a-z][a-z0-9_]{0,31}$")


def test_build_draft_column_name_normalizations_with_unicode_and_duplicates_is_stable_and_unique(
) -> None:
    candidates = [
        DraftColumnCandidateV2(dataset_key="ds_1", role="primary_dataset", name="经济发展水平"),
        DraftColumnCandidateV2(dataset_key="ds_1", role="primary_dataset", name="经济发展水平"),
        DraftColumnCandidateV2(dataset_key="ds_1", role="primary_dataset", name="X_1"),
        DraftColumnCandidateV2(dataset_key="ds_2", role="auxiliary_data", name="经济发展水平"),
    ]

    first = build_draft_column_name_normalizations(candidates)
    second = build_draft_column_name_normalizations(candidates)
    assert [item.model_dump() for item in first] == [item.model_dump() for item in second]

    by_dataset: dict[str, set[str]] = {}
    for item in first:
        by_dataset.setdefault(item.dataset_key, set()).add(item.normalized_name)
        assert _STATA_NAME_RE.match(item.normalized_name)
        if item.original_name == "经济发展水平":
            assert "u7ecf" in item.normalized_name

    assert len(by_dataset["ds_1"]) == 3
    assert len(by_dataset["ds_2"]) == 1
