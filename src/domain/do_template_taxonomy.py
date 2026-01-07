from __future__ import annotations

import re
from collections import Counter
from collections.abc import Mapping, Sequence
from dataclasses import dataclass

_FAMILY_ID_RE = re.compile(r"^[a-z0-9_]+$")


def normalize_family_label(label: str) -> str:
    value = label.strip().lower()
    value = re.sub(r"[\s\-]+", "_", value)
    value = re.sub(r"_+", "_", value)
    return value


@dataclass(frozen=True)
class CanonicalFamily:
    family_id: str
    aliases: tuple[str, ...]
    keywords: tuple[str, ...]
    use_when: str
    fallback_families: tuple[str, ...]


@dataclass(frozen=True)
class FamilyResolution:
    input_label: str
    normalized_label: str
    canonical_family_id: str
    matched_alias: str


def _string(value: object, *, field: str) -> str:
    if not isinstance(value, str):
        raise ValueError(f"family_registry.{field}_not_string")
    if value.strip() == "":
        raise ValueError(f"family_registry.{field}_empty")
    return value


def _family_id(value: object, *, field: str) -> str:
    raw = _string(value, field=field)
    normalized = normalize_family_label(raw)
    if not _FAMILY_ID_RE.match(normalized):
        raise ValueError(f"family_registry.{field}_invalid")
    return normalized


def _unique_ids(values: object, *, field: str, min_items: int) -> tuple[str, ...]:
    if not isinstance(values, Sequence) or isinstance(values, (str, bytes)):
        raise ValueError(f"family_registry.{field}_not_list")
    ids: list[str] = []
    seen: set[str] = set()
    for item in values:
        family_id = _family_id(item, field=field)
        if family_id in seen:
            raise ValueError(f"family_registry.{field}_duplicate")
        seen.add(family_id)
        ids.append(family_id)
    if len(ids) < min_items:
        raise ValueError(f"family_registry.{field}_too_short")
    return tuple(ids)


def _unique_keywords(values: object, *, field: str) -> tuple[str, ...]:
    if not isinstance(values, Sequence) or isinstance(values, (str, bytes)):
        raise ValueError(f"family_registry.{field}_not_list")
    keywords: list[str] = []
    seen: set[str] = set()
    for item in values:
        keyword = _string(item, field=field).strip()
        if keyword in seen:
            raise ValueError(f"family_registry.{field}_duplicate")
        seen.add(keyword)
        keywords.append(keyword)
    return tuple(keywords)


@dataclass(frozen=True)
class FamilyRegistry:
    registry_version: str
    families: tuple[CanonicalFamily, ...]
    _alias_to_canonical: dict[str, str]
    _alias_to_original: dict[str, str]

    def resolve(self, label: str) -> FamilyResolution | None:
        if not isinstance(label, str):
            return None
        normalized = normalize_family_label(label)
        if normalized == "":
            return None
        canonical = self._alias_to_canonical.get(normalized)
        if canonical is None:
            return None
        matched = self._alias_to_original.get(normalized, normalized)
        return FamilyResolution(
            input_label=label,
            normalized_label=normalized,
            canonical_family_id=canonical,
            matched_alias=matched,
        )


def load_family_registry(payload: Mapping[str, object]) -> FamilyRegistry:
    version = _string(payload.get("registry_version", ""), field="registry_version")
    families_raw = _families_list(payload)
    families, alias_to_canonical, alias_to_original = _parse_families(families_raw)

    registry = FamilyRegistry(
        registry_version=version,
        families=tuple(sorted(families, key=lambda family: family.family_id)),
        _alias_to_canonical=alias_to_canonical,
        _alias_to_original=alias_to_original,
    )
    _validate_fallbacks(registry)
    return registry


def _families_list(payload: Mapping[str, object]) -> list[object]:
    families_raw = payload.get("families", [])
    if not isinstance(families_raw, list):
        raise ValueError("family_registry.families_not_list")
    return families_raw


def _parse_families(
    families_raw: list[object],
) -> tuple[list[CanonicalFamily], dict[str, str], dict[str, str]]:
    families: list[CanonicalFamily] = []
    seen_family_ids: set[str] = set()
    alias_to_canonical: dict[str, str] = {}
    alias_to_original: dict[str, str] = {}

    for item in families_raw:
        family = _parse_family_item(item)
        if family.family_id in seen_family_ids:
            raise ValueError("family_registry.id_duplicate")
        seen_family_ids.add(family.family_id)
        _index_aliases(
            family=family,
            alias_to_canonical=alias_to_canonical,
            alias_to_original=alias_to_original,
        )
        families.append(family)

    return families, alias_to_canonical, alias_to_original


def _parse_family_item(item: object) -> CanonicalFamily:
    if not isinstance(item, dict):
        raise ValueError("family_registry.family_not_object")

    family_id = _family_id(item.get("id", ""), field="id")
    aliases = _unique_ids(item.get("aliases", []), field="aliases", min_items=1)
    if family_id not in aliases:
        raise ValueError("family_registry.id_not_in_aliases")
    keywords = _unique_keywords(item.get("keywords", []), field="keywords")
    use_when = _string(item.get("use_when", ""), field="use_when").strip()
    fallback = _unique_ids(
        item.get("fallback_families", []),
        field="fallback_families",
        min_items=0,
    )
    return CanonicalFamily(
        family_id=family_id,
        aliases=aliases,
        keywords=keywords,
        use_when=use_when,
        fallback_families=fallback,
    )


def _index_aliases(
    *,
    family: CanonicalFamily,
    alias_to_canonical: dict[str, str],
    alias_to_original: dict[str, str],
) -> None:
    for alias in family.aliases:
        normalized_alias = normalize_family_label(alias)
        previous = alias_to_canonical.get(normalized_alias)
        if previous is not None:
            raise ValueError("family_registry.alias_conflict")
        alias_to_canonical[normalized_alias] = family.family_id
        alias_to_original[normalized_alias] = alias


def _validate_fallbacks(registry: FamilyRegistry) -> None:
    known = {family.family_id for family in registry.families}
    for family in registry.families:
        for fallback in family.fallback_families:
            if fallback not in known:
                raise ValueError("family_registry.fallback_unknown")
            if fallback == family.family_id:
                raise ValueError("family_registry.fallback_self")


def canonical_family_by_template_id(
    *, index_payload: Mapping[str, object], registry: FamilyRegistry
) -> dict[str, str]:
    tasks = index_payload.get("tasks", {})
    if not isinstance(tasks, dict):
        raise ValueError("do_library_index.tasks_not_object")
    mapping: dict[str, str] = {}
    for template_id, record in tasks.items():
        if not isinstance(template_id, str) or template_id.strip() == "":
            raise ValueError("do_library_index.template_id_invalid")
        if not isinstance(record, dict):
            raise ValueError("do_library_index.task_record_invalid")
        legacy_family = record.get("family", "")
        if not isinstance(legacy_family, str) or legacy_family.strip() == "":
            raise ValueError("do_library_index.family_invalid")
        resolution = registry.resolve(legacy_family)
        if resolution is None:
            raise ValueError("do_library_index.family_unknown")
        mapping[template_id] = resolution.canonical_family_id
    return mapping


def generate_family_summary(
    *, index_payload: Mapping[str, object], registry: FamilyRegistry
) -> list[dict[str, object]]:
    mapping = canonical_family_by_template_id(index_payload=index_payload, registry=registry)
    counts = Counter(mapping.values())

    summaries: list[dict[str, object]] = []
    for family in registry.families:
        summaries.append(
            {
                "id": family.family_id,
                "count": int(counts.get(family.family_id, 0)),
                "keywords": sorted(set(family.keywords), key=str.casefold),
                "use_when": family.use_when,
                "aliases": sorted(set(family.aliases), key=str.casefold),
                "fallback_families": sorted(set(family.fallback_families), key=str.casefold),
            }
        )

    summaries.sort(key=lambda item: str(item.get("id", "")))
    return summaries
