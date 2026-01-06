# Proposal: issue-22-arch-t041-queue-claim

## Summary

- Add a minimal queue port so worker claim can be swapped (file → db/redis later).
- Implement file-based atomic claim using filesystem rename with an explicit lease TTL.
- Add tests protecting: single-claimer under contention, and reclaim after lease expiry.

## Changes

### ADDED

- Domain queue contract (claim + ack/release minimal surface).
- Infra file-based queue claimer (atomic rename + lease expiry).

### MODIFIED

- Worker queue spec to document lease/expiry behavior.

