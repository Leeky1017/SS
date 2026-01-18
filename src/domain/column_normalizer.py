from __future__ import annotations

import re
from collections.abc import Sequence

from pydantic import BaseModel, ConfigDict

from src.domain.draft_column_candidate_models import DraftColumnCandidateV2

_STATA_NAME_MAX_LEN = 32
_VALID_STATA_NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")


class DraftColumnNameNormalization(BaseModel):
    model_config = ConfigDict(extra="forbid")

    dataset_key: str
    role: str
    original_name: str
    normalized_name: str


def _char_token(ch: str) -> str:
    lower = ch.lower()
    if "a" <= lower <= "z" or "0" <= lower <= "9" or lower == "_":
        return lower
    if ch.isspace():
        return "_"
    code = ord(ch)
    if code <= 0xFFFF:
        return f"_u{code:04x}"
    return f"_u{code:x}"


def _normalize_base(name: str) -> str:
    raw = name.strip()
    if raw == "":
        return "v"
    tokens = [_char_token(ch) for ch in raw]
    candidate = re.sub(r"_+", "_", "".join(tokens)).strip("_")
    if candidate == "":
        candidate = "v"
    if not ("a" <= candidate[0] <= "z"):
        candidate = f"v_{candidate}"
    return candidate[:_STATA_NAME_MAX_LEN]


def _apply_suffix(base: str, *, suffix: str) -> str:
    if len(base) + len(suffix) <= _STATA_NAME_MAX_LEN:
        return base + suffix
    head = base[: _STATA_NAME_MAX_LEN - len(suffix)]
    return head + suffix


def _stata_safe_unique_names(
    originals: Sequence[str],
) -> list[str]:
    out: list[str] = []
    used: set[str] = set()
    counts: dict[str, int] = {}
    for idx, original in enumerate(originals, start=1):
        base = _normalize_base(original)
        if not _VALID_STATA_NAME_RE.match(base):
            base = f"v_{idx}"
        count = counts.get(base, 0) + 1
        counts[base] = count
        candidate = base if count == 1 else _apply_suffix(base, suffix=f"_{count}")
        while candidate in used:
            count += 1
            counts[base] = count
            candidate = _apply_suffix(base, suffix=f"_{count}")
        used.add(candidate)
        out.append(candidate)
    return out


def build_draft_column_name_normalizations(
    candidates_v2: Sequence[DraftColumnCandidateV2],
) -> list[DraftColumnNameNormalization]:
    per_dataset: dict[str, list[DraftColumnCandidateV2]] = {}
    for item in candidates_v2:
        per_dataset.setdefault(item.dataset_key, []).append(item)

    out: list[DraftColumnNameNormalization] = []
    for dataset_key, items in per_dataset.items():
        originals = [item.name for item in items]
        normalized = _stata_safe_unique_names(originals)
        for item, normalized_name in zip(items, normalized, strict=True):
            out.append(
                DraftColumnNameNormalization(
                    dataset_key=dataset_key,
                    role=item.role,
                    original_name=item.name,
                    normalized_name=normalized_name,
                )
            )
    return out
