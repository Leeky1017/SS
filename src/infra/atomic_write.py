from __future__ import annotations

import json
import logging
import os
import tempfile
from pathlib import Path

from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


def atomic_write_json(*, path: Path, payload: JsonObject) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
    tmp: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            "w",
            encoding="utf-8",
            dir=str(path.parent),
            delete=False,
        ) as f:
            tmp = Path(f.name)
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)
    except OSError:
        if tmp is not None:
            try:
                tmp.unlink(missing_ok=True)
            except OSError:
                logger.warning(
                    "SS_ATOMIC_WRITE_TMP_CLEANUP_FAILED",
                    extra={"path": str(path), "tmp": str(tmp)},
                )
        raise
