from __future__ import annotations

from pydantic import BaseModel, Field


class InputsPreviewColumn(BaseModel):
    name: str
    inferred_type: str


class InputsPreviewDataset(BaseModel):
    dataset_key: str
    role: str
    original_name: str
    format: str
    sheet_names: list[str] = Field(default_factory=list)
    selected_sheet: str | None = None
    header_row: bool | None = None


class InputsPreviewResponse(BaseModel):
    job_id: str
    row_count: int | None = None
    column_count: int | None = None
    sheet_names: list[str] = Field(default_factory=list)
    selected_sheet: str | None = None
    header_row: bool | None = None
    columns: list[InputsPreviewColumn] = Field(default_factory=list)
    sample_rows: list[dict[str, str | int | float | bool | None]] = Field(default_factory=list)
    datasets: list[InputsPreviewDataset] = Field(default_factory=list)

