from __future__ import annotations

import re

from src.domain.variable_corrections import apply_variable_corrections_text


def test_variable_corrections_token_boundary_does_not_replace_substrings() -> None:
    text = "col_a col_a2 _col_a col_a_ col_a\n(col_a)"
    out = apply_variable_corrections_text(text, {"col_a": "col_b"})
    assert re.search(r"(?<![A-Za-z0-9_])col_a(?![A-Za-z0-9_])", out) is None
    assert re.search(r"(?<![A-Za-z0-9_])col_b(?![A-Za-z0-9_])", out) is not None
    assert "col_a2" in out

