# Incident: [Short Title]

**Status:** ACTIVE | RESOLVED | STALLED
**Severity:** P0 (total outage) | P1 (degraded) | P2 (intermittent)
**Opened:** YYYY-MM-DD HH:MM
**IC:** [Agent Name]
**Ops:** [Agent Name]
**Mutation Policy:** discussion-only | local build/eval only | live probe allowed | live deployment allowed
**Current Mutation Owner:** [Agent Name] | none
**Rollback Anchor:** [generation / commit / snapshot / "unknown"]

---

## Problem Statement

> One paragraph. What is broken, on which host, observed how, since when.

---

## Confirmed Facts

> Only things directly observed or measured. No speculation. Cite the ledger entry that proves each fact.

1. [FACT] — Source: LEDGER#N
2. [FACT] — Source: LEDGER#N

---

## Active Hypotheses

> Currently being tested. Each hypothesis must have an assigned owner and a planned probe.

- [ ] **H1:** [Hypothesis] — Owner: [Agent] — Probe: [command/method]
- [ ] **H2:** [Hypothesis] — Owner: [Agent] — Probe: [command/method]

---

## Ruled-Out Hypotheses

> ~~Struck through~~ once disproven. Never deleted. Required to prevent reversion loops.

- ~~**H-X:** [Hypothesis]~~ — Disproven by LEDGER#N because [reason]

---

## Timeline

| Time | Event |
|---|---|
| YYYY-MM-DD HH:MM | Issue first observed |
| YYYY-MM-DD HH:MM | [Next event] |

---

## Constraints / Guardrails

> Things agents must not do or must preserve while the incident is active.

- [ ] [Constraint or invariant]

---

## Current Blockers

> What is preventing forward progress right now?

- [ ] [Blocker description]

---

## Next Action

**Who:** [IC / Ops / Comms]
**What:** [Specific action]
**Command/Method:** `<command if applicable>`

---

## ADR References

- [ADR-001: Title](./ADR-001.md)

---

## Handoff Notes

> Filled in when an agent session ends mid-incident. See MODEL.md §6.
