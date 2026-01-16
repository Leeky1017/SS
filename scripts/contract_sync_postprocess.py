from __future__ import annotations


def patch_recursive_jsonvalue_schemas(text: str) -> str:
    def rewrite(key: str, replacement: str, text: str) -> str:
        lines = text.splitlines()
        out: list[str] = []
        i = 0
        while i < len(lines):
            line = lines[i]
            stripped = line.lstrip()
            if stripped.startswith(f'"{key}":'):
                indent = line[: len(line) - len(stripped)]
                out.append(f'{indent}"{key}": {replacement};')
                i += 1
                while i < len(lines):
                    if lines[i].startswith(indent) and lines[i].rstrip().endswith("};"):
                        i += 1
                        break
                    i += 1
                continue
            out.append(line)
            i += 1
        return "\n".join(out) + "\n"

    patched = rewrite("JsonValue-Input", "JsonValueInput", text)
    return rewrite("JsonValue-Output", "JsonValueOutput", patched)

