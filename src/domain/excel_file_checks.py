from __future__ import annotations

from pathlib import Path

_OLE_SIGNATURE = bytes.fromhex("D0CF11E0A1B11AE1")


def looks_like_encrypted_xlsx(path: Path) -> bool:
    if path.suffix.lower() != ".xlsx":
        return False
    try:
        with path.open("rb") as handle:
            header = handle.read(len(_OLE_SIGNATURE))
    except OSError:
        return False
    return header == _OLE_SIGNATURE

