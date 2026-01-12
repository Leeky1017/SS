from __future__ import annotations

import pytest

from src.domain.output_formats import normalize_output_formats
from src.infra.exceptions import OutputFormatsInvalidError


def test_normalize_output_formats_when_none_returns_default() -> None:
    assert normalize_output_formats(None) == ("csv", "log", "do")


def test_normalize_output_formats_when_duplicates_and_case_returns_deduped_lowercase() -> None:
    assert normalize_output_formats(["CSV", "log", "csv"]) == ("csv", "log")


def test_normalize_output_formats_when_unknown_raises_output_formats_invalid_error() -> None:
    with pytest.raises(OutputFormatsInvalidError):
        normalize_output_formats(["nope"])

