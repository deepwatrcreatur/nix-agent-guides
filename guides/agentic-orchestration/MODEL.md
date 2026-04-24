# Agentic Orchestration Model: The Stateful Blackboard

This repository uses a blackboard-style coordination model for multi-agent
incident work. Do not rely on chat history for system state. Use the filesystem
as the primary memory.

## 1. The Blackboard Philosophy

Agents contribute to a shared set of files in a structured incident directory
(for example `docs/incidents/YYYY-MM-DD_name/`).

| File | Purpose | Who Writes |
| --- | --- | --- |
| `SUMMARY.md` | Single source of truth. Verified facts, current status, next action. | IC only |
| `RESEARCH_LEDGER.md` | Append-only log of every probe and its result. | Ops |
| `ACTIVE_DISCUSSION.md` | Signed positions on open questions. | All agents |
| `ADR-NNN.md` | Permanent record of a technical decision. | IC or Ops |

Rules:

- New agents must read `SUMMARY.md` first before any other action.
- `RESEARCH_LEDGER.md` is append-only. Never delete or rewrite prior entries.
- Hypotheses that are ruled out must be explicitly struck through in
  `SUMMARY.md` with a reference to the ledger entry that disproved them.
- `ACTIVE_DISCUSSION.md` may be pruned for readability, but only by synthesis.

### Canonical Incident Layout

Use this shape unless the repo has a stronger local convention:

```text
incident-name/
  SUMMARY.md
  RESEARCH_LEDGER.md
  ACTIVE_DISCUSSION.md
  ADR-001.md
  archive/
```

### Claim Discipline

Every material statement should belong to one of these classes:

| Class | Meaning | Allowed In |
| --- | --- | --- |
| Observed | Directly measured or rendered from the live/configured system | `SUMMARY.md`, `RESEARCH_LEDGER.md`, ADR evidence |
| Derived | Inference that follows tightly from observed facts | `ACTIVE_DISCUSSION.md`, ADR context, summary if labeled |
| Hypothesis | Plausible but unproven explanation | `ACTIVE_DISCUSSION.md`, `SUMMARY.md` hypothesis section |
| Decision | Chosen path forward despite uncertainty | ADRs, `SUMMARY.md` next action / constraints |

If a claim changes operational risk, it must be backed by observed evidence and
a ledger citation before acting on it.

### Evidence IDs

Use stable IDs in shared documents:

- hypotheses: `H1`, `H2`, ...
- ledger entries: `E1`, `E2`, ...
- decisions: `ADR-001`, `ADR-002`, ...

Do not renumber IDs after publication.

## 2. Agent Roles

### Incident Commander (IC)

- Owns `SUMMARY.md`.
- Keeps it pruned, accurate, and free of speculation.
- Makes the call on when a hypothesis is proven or disproven.

### Operations Lead (Ops)

- Executes probes (`strace`, `tcpdump`, `ss`, `journalctl`, etc.).
- Writes results to `RESEARCH_LEDGER.md`.
- Does not make config changes without explicit approval.

### Communications Lead (Comms)

- Manages `ACTIVE_DISCUSSION.md`.
- Synthesizes conflicting positions into a concrete question.
- De-duplicates parallel work.

### Mutation Owner

When live changes are allowed, exactly one agent session at a time is the
Mutation Owner.

- Owns deploys, rollbacks, restarts, and live experiments that change state.
- Must announce the mutation window in `SUMMARY.md` before acting.
- Must write pre-change and post-change ledger entries.

### Archivist

- Keeps `archive/` organized when discussion becomes too large.
- May move stale material out of `ACTIVE_DISCUSSION.md`, but must leave a short
  pointer behind.

## 3. Research Ledger Entry Format

Every probe gets one entry.

```markdown
### [YYYY-MM-DD HH:MM] <Agent Name> — <Tool Used>

**Command:** `<exact command run>`
**Host:** <hostname>
**Goal:** <one sentence>

**Result:**
<raw output or concise summary>

**Interpretation:**
<what this proves, disproves, or leaves open>
```

## 4. ADR Persistence

Use an ADR when a major technical pivot becomes durable:

- switching implementation strategies
- discovering a hard constraint
- accepting a workaround that future agents must not remove

ADRs are never deleted. If a decision is reversed, supersede it with a new ADR.

## 5. Change Control

Before any live mutation on a shared environment, `SUMMARY.md` should state:

- current mode: discussion-only, local build/eval only, live probe allowed, or
  live deployment allowed
- who owns mutations
- what rollback anchor exists
- what success/failure signal will end the mutation window

If this is not written down, default to discussion-only.

## 6. Handoff Protocol

When an agent stops mid-incident, update `SUMMARY.md` with:

```markdown
## Handoff Note — [YYYY-MM-DD HH:MM] <Agent Name>

**Stopping because:** <reason>
**State of work:** <what is done, what is in flight>
**Next agent must:** <explicit first action>
**Do NOT:** <anything the next agent must avoid>
```

## 7. Anti-Patterns

| Anti-Pattern | Why It Fails |
| --- | --- |
| Making a config change before checking the live system | Fixes the wrong thing |
| Treating a likely cause as a fact in `SUMMARY.md` | Future agents act on speculation |
| Running a probe but not logging it | The next agent re-runs it |
| Deleting a ruled-out hypothesis | It gets re-investigated |
| Two agents making different live changes in parallel | State divergence |
| Writing "works now" without re-running the original failing path | A mask gets mistaken for a fix |
| Treating source code as proof of runtime state | Rendered/live config may differ |
| Marking an incident resolved while fixes are only local or unpushed | Persistence and validation are separate concerns |
