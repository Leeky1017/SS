# Ops: Health checks (liveness + readiness)

## Background

The audit found missing health check endpoints, making orchestrated deployments (Kubernetes) and safe rollouts harder.

Sources:
- `Audit/02_Deep_Dive_Analysis.md` → “缺乏健康检查端点”

## Goal

Provide explicit liveness and readiness health checks with correct semantics and clear dependency coverage.

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: all non-conflicting tasks

## Acceptance checklist

- [ ] Add liveness and readiness endpoints with stable response schema
- [ ] Readiness reflects dependency availability and returns a failure status code when unhealthy
- [ ] Health checks do not swallow unexpected errors (fail explicitly with structured responses)
- [ ] Document how probes should be configured in deployment
- [ ] Implementation run log records `ruff check .` and `pytest -q`

## Estimate

- 2-4h

## Deployment probe configuration (Kubernetes)

Example probe configuration (tune thresholds for your environment):

```yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8000
  initialDelaySeconds: 2
  periodSeconds: 5
```
