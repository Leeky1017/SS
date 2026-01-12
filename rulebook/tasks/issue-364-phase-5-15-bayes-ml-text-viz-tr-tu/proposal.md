# Proposal: issue-364-phase-5-15-bayes-ml-text-viz-tr-tu

## Summary

Enhance Bayes/ML/Text/Viz templates (`TR*`–`TU*`) with:

- method best practices (priors + convergence; CV + model selection; text preprocessing; visualization export standards),
- fewer SSC dependencies (replace with Stata 18-native where feasible; document exceptions),
- stronger, explicit error handling (no silent failures),
- bilingual comments (中英文注释) for key steps and interpretation notes.

## Impact

- Touches only the do-template library assets + docs/spec artifacts; no backend architecture changes.
- Keeps existing template IDs and contract anchors stable.

