from __future__ import annotations

from src.utils.json_types import JsonObject


def missing_required_template_params(*, template_contract: JsonObject) -> list[str]:
    params_contract = template_contract.get("params_contract", {})
    if not isinstance(params_contract, dict):
        return []
    missing = params_contract.get("missing_required", [])
    if not isinstance(missing, list):
        return []
    return sorted({item for item in missing if isinstance(item, str) and item.strip() != ""})

