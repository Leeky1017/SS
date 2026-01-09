# Proposal

## Summary

Enhance causal templates TG01–TG25 with best practices, stronger diagnostics/error signaling, and bilingual (ZH/EN) comments while minimizing SSC dependencies (Stata 18-native first).

## Non-goals

- No taxonomy/index changes
- No new SSC dependencies without explicit justification

## Risks / Mitigations

- Some causal best-practice tooling is SSC-only (e.g., `rdrobust`, `rddensity`, `csdid`/`drdid`, `synth`, `mtefe`). Mitigation: prefer Stata-native alternatives where feasible; otherwise add explicit install checks + clear fallbacks/warnings.

