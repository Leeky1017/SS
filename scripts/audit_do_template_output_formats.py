from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

WANTED_EXTS = ("csv", "xlsx", "dta", "docx", "pdf", "log", "do")


@dataclass(frozen=True)
class MetaTemplate:
    template_id: str
    module: str
    family: str
    outputs: list[dict]
    dependencies: list[dict]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Audit do-template output format capability from do/meta/*.meta.json.",
    )
    parser.add_argument(
        "--meta-dir",
        default="assets/stata_do_library/do/meta",
        help="Directory containing *.meta.json files.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit machine-readable JSON instead of text.",
    )
    return parser.parse_args()


def ext_of(filename: str) -> str:
    normalized = filename.strip()
    if "." not in normalized:
        return ""
    return normalized.rsplit(".", 1)[-1].lower()


def load_templates(meta_dir: Path) -> list[MetaTemplate]:
    meta_files = sorted(meta_dir.glob("*.meta.json"))
    templates: list[MetaTemplate] = []
    for path in meta_files:
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise json.JSONDecodeError(
                f"{exc.msg} (file={path})", exc.doc, exc.pos
            ) from exc
        templates.append(
            MetaTemplate(
                template_id=raw.get("id", path.stem),
                module=raw.get("module", ""),
                family=raw.get("family", ""),
                outputs=raw.get("outputs", []),
                dependencies=raw.get("dependencies", []),
            )
        )
    return templates


def audit_outputs(templates: list[MetaTemplate]) -> dict:
    template_count_by_ext: dict[str, int] = defaultdict(int)
    output_entry_count_by_ext: dict[str, int] = defaultdict(int)
    templates_by_ext: dict[str, list[str]] = defaultdict(list)

    module_matrix: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    family_matrix: dict[str, dict[str, int]] = defaultdict(lambda: defaultdict(int))

    for tpl in templates:
        exts = set()
        for out in tpl.outputs:
            ext = ext_of(str(out.get("file", "")))
            output_entry_count_by_ext[ext] += 1
            exts.add(ext)

        for ext in sorted(exts):
            template_count_by_ext[ext] += 1
            templates_by_ext[ext].append(tpl.template_id)
            module_matrix[tpl.module][ext] += 1
            family_matrix[tpl.family][ext] += 1

    return {
        "meta_files": len(templates),
        "template_count_by_ext": dict(sorted(template_count_by_ext.items())),
        "output_entry_count_by_ext": dict(sorted(output_entry_count_by_ext.items())),
        "templates_by_ext": {k: sorted(v) for k, v in templates_by_ext.items()},
        "module_matrix": {k: dict(v) for k, v in module_matrix.items()},
        "family_matrix": {k: dict(v) for k, v in family_matrix.items()},
    }


def audit_dependencies(templates: list[MetaTemplate]) -> dict:
    source_count = Counter()
    pkg_count = Counter()
    pkg_sources: dict[str, Counter] = defaultdict(Counter)
    pkg_by_template: dict[str, set[str]] = defaultdict(set)

    for tpl in templates:
        for dep in tpl.dependencies:
            pkg = str(dep.get("pkg", "")).strip() or "<missing>"
            source = str(dep.get("source", "")).strip() or "<missing>"
            source_count[source] += 1
            pkg_count[pkg] += 1
            pkg_sources[pkg][source] += 1
            pkg_by_template[tpl.template_id].add(pkg)

    docx_outputs_by_type: dict[str, set[str]] = defaultdict(set)
    pdf_outputs_by_type: dict[str, set[str]] = defaultdict(set)
    for tpl in templates:
        for out in tpl.outputs:
            ext = ext_of(str(out.get("file", "")))
            out_type = str(out.get("type", "")).strip() or "<missing>"
            if ext == "docx":
                docx_outputs_by_type[out_type].add(tpl.template_id)
            elif ext == "pdf":
                pdf_outputs_by_type[out_type].add(tpl.template_id)

    docx_out = set().union(*docx_outputs_by_type.values()) if docx_outputs_by_type else set()
    pdf_out = set().union(*pdf_outputs_by_type.values()) if pdf_outputs_by_type else set()

    docx_templates_with_dep_putdocx = sorted(t for t in docx_out if "putdocx" in pkg_by_template[t])
    docx_templates_missing_dep_putdocx = sorted(
        t for t in docx_out if "putdocx" not in pkg_by_template[t]
    )

    pdf_report_types = {"report", "table"}
    pdf_report_templates = set()
    pdf_figure_templates = set()
    for out_type, tpl_ids in pdf_outputs_by_type.items():
        if out_type in pdf_report_types:
            pdf_report_templates.update(tpl_ids)
        else:
            pdf_figure_templates.update(tpl_ids)

    pdf_report_templates_sorted = sorted(pdf_report_templates)
    pdf_report_missing_dep_putpdf = sorted(
        t for t in pdf_report_templates if "putpdf" not in pkg_by_template[t]
    )

    return {
        "dependency_entries": int(sum(pkg_count.values())),
        "source_count": dict(source_count),
        "pkg_count": dict(pkg_count),
        "pkg_sources": {k: dict(v) for k, v in pkg_sources.items()},
        "docx_outputs_by_type": {k: sorted(v) for k, v in docx_outputs_by_type.items()},
        "pdf_outputs_by_type": {k: sorted(v) for k, v in pdf_outputs_by_type.items()},
        "docx_outputs_templates": sorted(docx_out),
        "pdf_outputs_templates": sorted(pdf_out),
        "docx_templates_with_dep_putdocx": docx_templates_with_dep_putdocx,
        "docx_templates_missing_dep_putdocx": docx_templates_missing_dep_putdocx,
        "pdf_report_templates": pdf_report_templates_sorted,
        "pdf_figure_templates": sorted(pdf_figure_templates),
        "pdf_report_missing_dep_putpdf": pdf_report_missing_dep_putpdf,
    }


def audit_output_types(templates: list[MetaTemplate]) -> dict:
    type_count = Counter()
    type_by_ext: dict[str, Counter] = defaultdict(Counter)

    for tpl in templates:
        for out in tpl.outputs:
            out_type = str(out.get("type", "")).strip() or "<missing>"
            ext = ext_of(str(out.get("file", ""))) or "<none>"
            type_count[out_type] += 1
            type_by_ext[out_type][ext] += 1

    return {
        "type_count": dict(type_count),
        "type_by_ext": {k: dict(v) for k, v in type_by_ext.items()},
    }


def render_template_count_by_ext(outputs: dict) -> list[str]:
    lines: list[str] = []
    lines.append("TEMPLATE_COUNT_BY_EXT (templates declaring >=1 output with ext):")
    for ext, cnt in sorted(
        outputs["template_count_by_ext"].items(), key=lambda kv: (-kv[1], kv[0])
    ):
        lines.append(f"- {ext or '<none>'}: {cnt}")
    return lines


def render_output_entry_count_by_ext(outputs: dict) -> list[str]:
    lines: list[str] = []
    lines.append("OUTPUT_ENTRY_COUNT_BY_EXT (raw outputs[] entries):")
    for ext, cnt in sorted(
        outputs["output_entry_count_by_ext"].items(), key=lambda kv: (-kv[1], kv[0])
    ):
        lines.append(f"- {ext or '<none>'}: {cnt}")
    return lines


def render_wanted_exts(outputs: dict) -> list[str]:
    lines: list[str] = []
    lines.append("WANTED_EXTS:")
    for ext in WANTED_EXTS:
        templates = outputs["templates_by_ext"].get(ext, [])
        lines.append(f"- {ext}: {len(templates)}")
    return lines


def render_dependency_mismatches(deps: dict) -> list[str]:
    lines: list[str] = []
    lines.append("DOCX/PDF dependency mismatches:")
    lines.append(
        f"- docx_outputs_templates={len(deps['docx_outputs_templates'])} "
        f"docx_templates_with_dep_putdocx={len(deps['docx_templates_with_dep_putdocx'])} "
        f"docx_templates_missing_dep_putdocx={len(deps['docx_templates_missing_dep_putdocx'])}"
    )
    if deps["docx_templates_missing_dep_putdocx"]:
        lines.append(
            "  - missing putdocx: " + " ".join(deps["docx_templates_missing_dep_putdocx"])
        )
    lines.append(
        f"- pdf_outputs_templates={len(deps['pdf_outputs_templates'])} "
        f"pdf_report_templates={len(deps['pdf_report_templates'])} "
        f"pdf_figure_templates={len(deps['pdf_figure_templates'])}"
    )
    if deps["pdf_report_missing_dep_putpdf"]:
        lines.append(
            "  - report missing putpdf: " + " ".join(deps["pdf_report_missing_dep_putpdf"])
        )
    return lines


def render_dependency_summary(deps: dict) -> list[str]:
    lines: list[str] = []
    lines.append(f"dependency_entries={deps['dependency_entries']}")
    lines.append("SOURCE_COUNT:")
    for src, cnt in sorted(deps["source_count"].items(), key=lambda kv: (-kv[1], kv[0])):
        lines.append(f"- {src}: {cnt}")
    return lines


def render_output_type_count(output_types: dict) -> list[str]:
    lines: list[str] = []
    lines.append("OUTPUTS_TYPE_COUNT:")
    for out_type, cnt in sorted(
        output_types["type_count"].items(), key=lambda kv: (-kv[1], kv[0])
    ):
        lines.append(f"- {out_type}: {cnt}")
    return lines


def render_text(summary: dict) -> str:
    outputs = summary["outputs"]
    deps = summary["dependencies"]
    output_types = summary["output_types"]

    blocks: list[list[str]] = [
        [f"meta_files={outputs['meta_files']}"],
        render_template_count_by_ext(outputs),
        render_output_entry_count_by_ext(outputs),
        render_wanted_exts(outputs),
        render_dependency_mismatches(deps),
        render_dependency_summary(deps),
        render_output_type_count(output_types),
    ]

    lines: list[str] = []
    for block in blocks:
        if lines:
            lines.append("")
        lines.extend(block)
    return "\n".join(lines) + "\n"


def main() -> int:
    args = parse_args()
    templates = load_templates(Path(args.meta_dir))

    summary = {
        "outputs": audit_outputs(templates),
        "dependencies": audit_dependencies(templates),
        "output_types": audit_output_types(templates),
    }

    if args.json:
        print(json.dumps(summary, indent=2, sort_keys=True))
        return 0

    print(render_text(summary), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
