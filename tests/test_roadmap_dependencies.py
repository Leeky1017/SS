from __future__ import annotations

from src.utils.roadmap_dependencies import parse_issue_dependencies_from_execution_plan


def test_parse_issue_dependencies_from_execution_plan_with_supported_patterns_returns_mapping():
    markdown = """
## 0) Foundation

- #17（状态机 + 幂等）依赖 #16
- #19（Artifacts API + Run trigger）hard depends on：#16 + #17
结论：
- #36 MUST after #24 + #16
""".strip()

    deps = parse_issue_dependencies_from_execution_plan(markdown)

    assert deps[17] == {16}
    assert deps[19] == {16, 17}
    assert deps[36] == {16, 24}
