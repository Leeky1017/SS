from __future__ import annotations

import re
from collections import defaultdict

_ISSUE_RE = re.compile(r"#(?P<number>[0-9]+)")
_HARD_DEPENDS_RE = re.compile(r"hard depends on[:：]\s*(?P<deps>.+)$", re.IGNORECASE)
_MUST_AFTER_RE = re.compile(r"MUST\s+after\s+(?P<deps>.+)$", re.IGNORECASE)
_DEPENDS_CN_RE = re.compile(r"依赖\s*(?P<deps>.+)$")


def _extract_issue_numbers(text: str) -> set[int]:
    return {int(match.group("number")) for match in _ISSUE_RE.finditer(text)}


def parse_issue_dependencies_from_execution_plan(markdown: str) -> dict[int, set[int]]:
    deps_by_issue: dict[int, set[int]] = defaultdict(set)

    for raw_line in markdown.splitlines():
        line = raw_line.strip()
        if "#" not in line:
            continue

        subject_match = _ISSUE_RE.search(line)
        if not subject_match:
            continue

        subject = int(subject_match.group("number"))
        deps: set[int] = set()

        if match := _HARD_DEPENDS_RE.search(line):
            deps |= _extract_issue_numbers(match.group("deps"))

        if match := _MUST_AFTER_RE.search(line):
            deps |= _extract_issue_numbers(match.group("deps"))

        if match := _DEPENDS_CN_RE.search(line):
            deps |= _extract_issue_numbers(match.group("deps"))

        deps.discard(subject)
        if deps:
            deps_by_issue[subject].update(deps)

    return dict(deps_by_issue)
