# Spec Delta: issue-414-step1-method-guidance (ss-frontend-desktop-pro)

## References (canonical)
- `openspec/specs/ss-frontend-desktop-pro/spec.md`

## Delta Requirements

### Requirement: Step 1 MUST provide guided analysis method selection for requirement drafting
The Step 1 UI MUST help users draft a clear requirement by:
- offering a small set of analysis categories as clickable cards
- showing sub-method options for the selected category (except “free description”)
- generating an editable structured template into the requirement textarea when a sub-method is selected

## Scenarios

#### Scenario: Selecting a sub-method generates an editable requirement template
- **GIVEN** the user is at Step 1 and the requirement textarea is editable
- **WHEN** the user selects an analysis category and then selects a sub-method
- **THEN** Step 1 populates the requirement textarea with a structured template
- **AND** the user can freely edit the generated text before submission

#### Scenario: Free description keeps the textarea empty
- **GIVEN** the user is at Step 1
- **WHEN** the user selects “free description”
- **THEN** Step 1 does not auto-fill a template and keeps the textarea empty
