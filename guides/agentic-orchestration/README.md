# Agentic Orchestration Standards

This directory is the workspace-level reference for multi-agent incident work.

## Start Order

1. Read [MODEL.md](./MODEL.md) for roles, document contracts, and change control.
2. Read [SOP_FORENSIC_ENGINEERING.md](./SOP_FORENSIC_ENGINEERING.md) before planning probes.
3. Copy from [TEMPLATES](./TEMPLATES/) when creating a new incident or ADR.

## Minimum Contract

If you join an existing incident:

1. Read `SUMMARY.md` first.
2. Check `RESEARCH_LEDGER.md` before re-running a probe.
3. Add signed reasoning to `ACTIVE_DISCUSSION.md` instead of overwriting someone else's position.
4. Do not mutate live systems unless the mutation window and owner are written down.

## What These Standards Optimize For

- fewer duplicated probes
- fewer reversion loops
- clearer distinction between observed facts and theories
- safer live work on shared systems
