# Agentic Orchestration Standards

This guide bundle is for incidents or investigations where multiple agent
sessions may read, probe, and mutate the same system.

## Start Order

1. Read [MODEL.md](./MODEL.md) for roles, document contracts, and change control.
2. Read [SOP_FORENSIC_ENGINEERING.md](./SOP_FORENSIC_ENGINEERING.md) before planning probes.
3. Copy from the repository [templates](../../templates/) when creating a new
   incident record or ADR.

## Minimum Contract

If you join an existing incident:

1. Read `SUMMARY.md` first.
2. Check `RESEARCH_LEDGER.md` before re-running a probe.
3. Add signed reasoning to `ACTIVE_DISCUSSION.md` instead of overwriting
   someone else's position.
4. Do not mutate live systems unless the mutation window and owner are written
   down.

## Why This Exists

The goal is to reduce:

- duplicated probes
- reversion loops
- speculation turning into "facts"
- unsafe live changes on shared systems

## Related Files

- [MODEL.md](./MODEL.md)
- [SOP_FORENSIC_ENGINEERING.md](./SOP_FORENSIC_ENGINEERING.md)
- [ATTRIBUTION.md](./ATTRIBUTION.md)
