#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

_TASK_BRANCH_RE = re.compile(r"^task/(?P<issue_number>[0-9]+)-(?P<slug>[a-z0-9-]+)$")


@dataclass(frozen=True)
class PullRequestSummary:
    number: int
    head_ref: str
    title: str
    url: str
    is_draft: bool


def _run(args: list[str], cwd: Path | None = None) -> str:
    try:
        completed = subprocess.run(
            args,
            cwd=cwd,
            text=True,
            capture_output=True,
            check=False,
        )
    except FileNotFoundError as exc:
        raise RuntimeError(f"command not found: {args[0]}") from exc

    if completed.returncode != 0:
        stderr = (completed.stderr or "").strip()
        raise RuntimeError(f"command failed ({completed.returncode}): {' '.join(args)}\n{stderr}")

    return (completed.stdout or "").strip()


def _repo_root() -> Path:
    return Path(_run(["git", "rev-parse", "--show-toplevel"]))


def _current_branch(repo_root: Path) -> str:
    return _run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=repo_root)


def _issue_number_from_branch(branch: str) -> int | None:
    match = _TASK_BRANCH_RE.match(branch)
    if not match:
        return None
    return int(match.group("issue_number"))


def _changed_files(repo_root: Path, base_ref: str) -> set[str]:
    output = _run(
        [
            "git",
            "diff",
            "--name-only",
            "--diff-filter=ACMRT",
            f"{base_ref}...HEAD",
        ],
        cwd=repo_root,
    )
    if not output:
        return set()
    return {line for line in output.splitlines() if line.strip()}


def _list_open_prs() -> list[PullRequestSummary]:
    output = _run(
        [
            "gh",
            "pr",
            "list",
            "--state",
            "open",
            "--json",
            "number,headRefName,title,url,isDraft",
        ],
    )
    items = json.loads(output)
    prs: list[PullRequestSummary] = []
    for item in items:
        prs.append(
            PullRequestSummary(
                number=int(item["number"]),
                head_ref=str(item["headRefName"]),
                title=str(item.get("title", "")),
                url=str(item.get("url", "")),
                is_draft=bool(item.get("isDraft", False)),
            )
        )
    return prs


def _pr_changed_files(pr_number: int) -> set[str]:
    output = _run(["gh", "pr", "view", str(pr_number), "--json", "files"])
    payload = json.loads(output)
    files = payload.get("files", [])

    paths: set[str] = set()
    for item in files:
        path = str(item.get("path", "")).strip()
        if path:
            paths.add(path)
    return paths


def _open_prs_by_issue_number(
    open_prs: list[PullRequestSummary],
) -> dict[int, list[PullRequestSummary]]:
    by_issue: dict[int, list[PullRequestSummary]] = {}
    for pr in open_prs:
        issue_number = _issue_number_from_branch(pr.head_ref)
        if issue_number is None:
            continue
        by_issue.setdefault(issue_number, []).append(pr)
    return by_issue


def _issue_state(issue_number: int) -> tuple[str, str, str]:
    output = _run(["gh", "issue", "view", str(issue_number), "--json", "state,title,url"])
    payload = json.loads(output)
    state = str(payload.get("state", ""))
    title = str(payload.get("title", ""))
    url = str(payload.get("url", ""))
    return state, title, url


def _load_execution_plan(repo_root: Path, path: str) -> str:
    plan_path = (repo_root / path).resolve()
    try:
        return plan_path.read_text(encoding="utf-8")
    except FileNotFoundError as exc:
        raise RuntimeError(f"execution plan not found: {plan_path}") from exc


def _deps_from_execution_plan(markdown: str) -> dict[int, set[int]]:
    repo_root = Path(__file__).resolve().parents[1]
    if str(repo_root) not in sys.path:
        sys.path.insert(0, str(repo_root))

    from src.utils.roadmap_dependencies import parse_issue_dependencies_from_execution_plan

    return parse_issue_dependencies_from_execution_plan(markdown)


def _dependencies_for_issue(markdown: str, issue_number: int) -> list[int]:
    deps = _deps_from_execution_plan(markdown).get(issue_number, set())
    return sorted(deps)


def _print_header(label: str) -> None:
    print(f"\n== {label} ==")


def _print_context(repo_root: Path, branch: str, issue_number: int | None, base_ref: str) -> None:
    print("SS PR preflight")
    print(f"- Repo   : {repo_root}")
    print(f"- Branch : {branch}")
    if issue_number is not None:
        print(f"- Issue  : #{issue_number}")
    print(f"- Base   : {base_ref}")


def _print_changed_files(changed: set[str]) -> None:
    _print_header("Changed Files")
    if not changed:
        print("(none)")
        return
    for path in sorted(changed):
        print(f"- {path}")


def _print_open_pr_overlap(changed: set[str], open_prs: list[PullRequestSummary]) -> bool:
    _print_header("Open PR File Overlap")
    overlap_found = False
    for pr in open_prs:
        overlap = sorted(changed.intersection(_pr_changed_files(pr.number)))
        if not overlap:
            continue
        overlap_found = True
        draft_marker = " (draft)" if pr.is_draft else ""
        print(f"- PR #{pr.number}{draft_marker}: {pr.head_ref} — {pr.title}")
        print(f"  {pr.url}")
        for path in overlap:
            print(f"  - {path}")

    if not overlap_found:
        print("OK: no overlapping files with open PRs")
    return overlap_found


def _blocked_dependencies(
    repo_root: Path,
    execution_plan: str,
    issue_number: int,
    prs_by_issue: dict[int, list[PullRequestSummary]],
) -> list[int]:
    plan_markdown = _load_execution_plan(repo_root, execution_plan)
    deps = _dependencies_for_issue(plan_markdown, issue_number)

    _print_header("Roadmap Dependencies")
    if not deps:
        print("OK: no hard dependencies found in execution plan")
        return []

    blocked: list[int] = []
    for dep in deps:
        state, title, url = _issue_state(dep)
        pr_hint = ""
        prs = prs_by_issue.get(dep, [])
        if prs:
            pr_hint = f" (open PR: {', '.join('#' + str(p.number) for p in prs)})"
        print(f"- #{dep}{pr_hint}: {state} — {title}")
        print(f"  {url}")
        if state.upper() != "CLOSED":
            blocked.append(dep)
    return blocked


def _args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="SS agent PR preflight: deps + file overlap.")
    parser.add_argument(
        "--base-ref",
        default="origin/main",
        help="Git ref to diff against (default: origin/main).",
    )
    parser.add_argument(
        "--execution-plan",
        default="openspec/specs/ss-roadmap/execution_plan.md",
        help="Roadmap dependency plan markdown path.",
    )
    return parser.parse_args()


def _main() -> int:
    args = _args()

    repo_root = _repo_root()
    branch = _current_branch(repo_root)
    issue_number = _issue_number_from_branch(branch)

    common_path = Path(_run(["git", "rev-parse", "--git-common-dir"], cwd=repo_root))
    common_path = common_path if common_path.is_absolute() else (repo_root / common_path).resolve()
    controlplane_root = common_path.parent
    controlplane_dirty = _run(["git", "status", "--porcelain=v1"], cwd=controlplane_root)
    if controlplane_dirty:
        print(
            f"\n== Controlplane Guard ==\nERROR: controlplane dirty: {controlplane_root}\n"
            f"{controlplane_dirty}\nFix: move into task worktree; keep controlplane clean."
        )
        return 5

    _run(["git", "fetch", "origin", "main"], cwd=repo_root)
    changed = _changed_files(repo_root, args.base_ref)

    _print_context(repo_root, branch, issue_number, args.base_ref)
    _print_changed_files(changed)

    open_prs = [pr for pr in _list_open_prs() if pr.head_ref != branch]
    prs_by_issue = _open_prs_by_issue_number(open_prs)
    overlap_found = _print_open_pr_overlap(changed, open_prs)

    blocked_deps: list[int] = []
    if issue_number is not None:
        blocked_deps = _blocked_dependencies(
            repo_root,
            args.execution_plan,
            issue_number,
            prs_by_issue,
        )

    if blocked_deps:
        _print_header("Status")
        blocked_list = ", ".join(f"#{n}" for n in blocked_deps)
        print(f"BLOCKED: waiting for issues to close: {blocked_list}")
        print("Suggestion: open PR as draft or avoid enabling auto-merge until deps are merged.")

    if blocked_deps and overlap_found:
        return 4
    if blocked_deps:
        return 3
    if overlap_found:
        return 2
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(_main())
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
