from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class SpecViolation:
    path: Path
    message: str


def _first_nonempty_line(lines: list[str]) -> str:
    for line in lines:
        if line.strip():
            return line
    return ""


def _has_any_heading(text: str, headings: list[str]) -> bool:
    return any(h in text for h in headings)


def _contains_placeholder(text: str) -> str | None:
    scrubbed = _strip_code_spans(text)
    lowered = scrubbed.lower()
    for token in ("(fill)", "<fill", "todo", "tbd"):
        if token in lowered:
            return token
    return None


def _strip_code_spans(text: str) -> str:
    lines = text.splitlines()
    kept: list[str] = []
    in_fence = False

    for line in lines:
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        kept.append(line)

    no_fences = "\n".join(kept)
    return re.sub(r"`[^`]*`", "", no_fences)


def validate_spec(path: Path) -> list[SpecViolation]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    violations: list[SpecViolation] = []

    if len(lines) > 300:
        violations.append(SpecViolation(path, f"spec exceeds 300 lines: {len(lines)}"))

    first = _first_nonempty_line(lines)
    if not first.startswith("# Spec —"):
        violations.append(SpecViolation(path, "first heading must be '# Spec — <title>'"))

    if not _has_any_heading(text, ["## Goal", "## Goals"]):
        violations.append(
            SpecViolation(path, "missing required heading: '## Goal' (or '## Goals')")
        )

    if "## Requirements" not in text:
        violations.append(SpecViolation(path, "missing required heading: '## Requirements'"))

    if not _has_any_heading(text, ["## Scenarios", "## Scenarios (verifiable)"]):
        violations.append(
            SpecViolation(path, "missing required heading: '## Scenarios (verifiable)'")
        )

    placeholder = _contains_placeholder(text)
    if placeholder is not None:
        violations.append(SpecViolation(path, f"contains placeholder token: {placeholder!r}"))

    return violations


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    spec_paths = sorted(repo_root.glob("openspec/specs/**/spec.md"))
    if not spec_paths:
        print("ERROR: no spec files found under openspec/specs/**/spec.md", file=sys.stderr)
        return 2

    violations: list[SpecViolation] = []
    for path in spec_paths:
        violations.extend(validate_spec(path))

    if violations:
        print("OpenSpec guard failed:", file=sys.stderr)
        for v in violations:
            rel = v.path.relative_to(repo_root)
            print(f"- {rel}: {v.message}", file=sys.stderr)
        return 1

    print(f"OpenSpec guard OK ({len(spec_paths)} specs)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
