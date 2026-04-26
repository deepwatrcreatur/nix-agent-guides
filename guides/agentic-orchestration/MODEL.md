# Agentic Orchestration Model: The Stateful Blackboard

This workspace uses a **Blackboard Architecture** for multi-agent coordination. Do not rely on chat history for system state. Use the filesystem as the primary memory.

---

## 1. The Blackboard Philosophy

Agents contribute to a shared set of files in a structured incident directory
(e.g., `docs/incidents/YYYY-MM-DD_name/`).

| File | Purpose | Who Writes |
|---|---|---|
| `SUMMARY.md` | Single source of truth. Verified facts, current status, next action. | IC only |
| `RESEARCH_LEDGER.md` | Append-only log of every probe and its result. | Ops |
| `ACTIVE_DISCUSSION.md` | Signed positions on open questions. | All agents |
| `ADR-NNN.md` | Permanent record of a technical decision. | IC or Ops |

**Rules:**
- New agents **must read `SUMMARY.md` first** before any other action.
- `RESEARCH_LEDGER.md` is **append-only** — never delete or rewrite prior entries.
- Hypotheses that are **ruled out** must be explicitly struck through in `SUMMARY.md` with a reference to the ledger entry that disproved them. This is the primary defense against reversion loops.
- `ACTIVE_DISCUSSION.md` may be pruned for readability, but only by synthesis: do not silently delete an unresolved position without either:
  - folding it into a current synthesis note, or
  - marking it stale/superseded with a reason.

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

- `archive/` is for superseded discussion snapshots or bulky artifacts.
- `SUMMARY.md` should stay short enough that a new agent can read it first.
- Large command output belongs in the ledger or a linked artifact, not in the summary.

### Claim Discipline

Every material statement should implicitly belong to one of these classes:

| Class | Meaning | Allowed In |
|---|---|---|
| **Observed** | Directly measured or rendered from the live/configured system | `SUMMARY.md`, `RESEARCH_LEDGER.md`, ADR evidence |
| **Derived** | Inference that follows tightly from observed facts | `ACTIVE_DISCUSSION.md`, ADR context, summary only if labeled as interpretation |
| **Hypothesis** | Plausible but unproven explanation | `ACTIVE_DISCUSSION.md`, `SUMMARY.md` hypothesis section |
| **Decision** | Chosen path forward despite uncertainty | ADRs, `SUMMARY.md` next action / constraints |

If a claim changes operational risk (restart, rollout, rollback, firewall change, storage mutation), it must be backed by **Observed** evidence and a ledger citation before acting on it.

### Evidence IDs

Use stable IDs in shared documents:

- hypotheses: `H1`, `H2`, ...
- ledger entries: `E1`, `E2`, ...
- decisions: `ADR-001`, `ADR-002`, ...
- discussion positions: free-form signed headings are acceptable, but they should cite the relevant `E#` or `H#`

Do not renumber IDs after publication. If the sequence becomes messy, keep going.

---

## 2. Agent Roles (Incident Command System)

When an incident is active, agents self-assign one of these roles at the start of their response.

### Incident Commander (IC)
- Owns `SUMMARY.md`. Keeps it pruned, accurate, and free of speculation.
- Makes the call on when a hypothesis is proven or disproven.
- Approves ADRs before they are considered binding.

### Operations Lead (Ops)
- Executes probes (`strace`, `tcpdump`, `ss`, `journalctl`, etc.).
- Writes every result to `RESEARCH_LEDGER.md` using the standard entry format (see below).
- Never makes a config change without IC approval.

### Communications Lead (Comms)
- Manages `ACTIVE_DISCUSSION.md`.
- When two agents hold conflicting positions, Comms synthesizes them into a single question and escalates to the IC for a ruling.
- Responsible for de-duplication — if two agents are running the same probe, Comms stops one.

### Archivist

- Keeps `archive/` organized when the active discussion gets too large.
- May move stale material out of `ACTIVE_DISCUSSION.md`, but must leave a short pointer behind.
- Does not change incident state or reinterpret evidence.

> A single agent session may hold multiple roles on a small incident. The point is the *discipline*, not the headcount.

### Mutation Owner

When live changes are allowed, exactly one agent session at a time is the **Mutation Owner**.

- Owns service restarts, deploys, rollbacks, hotfix edits, and live experiments that change system state.
- Must announce the mutation window in `SUMMARY.md` before acting.
- Must write pre-change and post-change ledger entries.
- Must hand mutation ownership back explicitly when done.

This is the practical safeguard against split-brain incidents where multiple agents "help" by changing different things in parallel.

---

## 3. RESEARCH_LEDGER Entry Format

Every probe gets one entry. No exceptions.

```markdown
### [YYYY-MM-DD HH:MM] <Agent Name> — <Tool Used>

**Command:** `<exact command run>`
**Host:** <hostname>
**Goal:** <one sentence — what were you trying to learn?>

**Result:**
<raw output or concise summary>

**Interpretation:**
<what does this tell us? does it confirm or rule out a hypothesis?>
```

---

## 4. Decision Persistence (ADR)

Every major technical pivot must be documented as an **Architecture Decision Record** using `TEMPLATES/ADR.md`.

Triggers for a new ADR:
- Switching implementation strategies (e.g., "moving from UDP to raw sockets")
- Discovering a constraint that permanently rules out an approach
- Accepting a workaround that future agents must not remove

ADRs are **never deleted**. If a decision is reversed, the old ADR gets status `Superseded by ADR-NNN` and a new ADR is written.

---

## 5. Change Control for Shared Systems

Before any live mutation on a shared environment, `SUMMARY.md` should state:

- whether the incident is currently:
  - `discussion-only`
  - `local build/eval only`
  - `live probe allowed`
  - `live deployment allowed`
- who currently owns mutations
- what rollback anchor exists
- what success/failure signal will end the mutation window

If this is not written down, the default policy is **discussion-only**.

---

## 6. Handoff Protocol

When an agent session ends mid-incident, it must update `SUMMARY.md` with:

```markdown
## Handoff Note — [YYYY-MM-DD HH:MM] <Agent Name>

**Stopping because:** <reason>
**State of work:** <what is done, what is in flight>
**Next agent must:** <explicit first action>
**Do NOT:** <anything the next agent must avoid — e.g., "do not restart kea until ledger entry #7 is explained">
```

---

## 7. Anti-Patterns

| Anti-Pattern | Why It Fails |
|---|---|
| Making a config change before checking the live system | Fixes the wrong thing; masks the real cause |
| Treating a "likely cause" as a confirmed fact in `SUMMARY.md` | Future agents act on the speculation as if it were evidence |
| Running a probe but not logging it | The next agent re-runs it; duplicated effort and time lost |
| Deleting a ruled-out hypothesis from `SUMMARY.md` | The next agent re-investigates it; classic reversion loop |
| Two agents making different config changes in parallel | State divergence; impossible to attribute the fix |
| Writing "works now" without re-running the original failing path | A mask or state transition gets mistaken for a real fix |
| Treating source code as proof of runtime state | Deployed/rendered config may differ materially from source |
| Marking an incident `RESOLVED` while fixes are only local or unpushed | Persistence and validation are separate concerns |
| Closing a discussion because the IC is satisfied | Other agents may still have unresolved findings that change the decision |
| Accepting an agent's "verified" or "confirmed" without a citation | Confident specificity is not the same as sourced evidence; specific-sounding claims are the most common hallucination surface |

---

## 8. Multi-Round Design Discussion Protocol

For pre-implementation research questions where multiple agents contribute positions
across multiple rounds — distinct from active incident handling.

### Satisfaction Protocol

Discussion stays open until every contributing agent has explicitly stated
their satisfaction status on each question they worked on:

| Marker | Meaning |
|---|---|
| `[satisfied]` | Agent accepts the current evidence and decision |
| `[satisfied-conditional: <condition>]` | Satisfied unless a named condition changes (e.g., a new upstream release is confirmed) |
| `[needs more evidence]` | Agent cannot yet accept the position; must name what evidence would resolve it |

The IC does not close a discussion until all contributing agents have marked
every open question satisfied or conditional. Premature closure is an
anti-pattern — see above. Writing a final IC close before all agents have
responded is the most common form of premature closure.

### Citation Verification Round

Before closing any question an agent labelled "verified", "confirmed", or
"observed without a source location":

1. Challenge the agent to produce the specific file path, line number, tag
   hash, commit reference, or URL.
2. If the agent cannot produce it, the claim reverts to unverified hypothesis.
3. Repeat as a new round; do not close until either the source is found or
   the claim is retracted.

This costs one exchange. Not doing it costs an implementation agent hours
chasing a non-existent version, a hallucinated commit, or a misattributed
source location.

### Hallucination Correction Loop

Some agents consistently produce confident, specific-sounding claims —
release dates, commit hashes, line numbers, version tags — that are
fabricated. The pattern is reliable:

1. Agent makes a confident, specific, unsourced claim.
2. IC issues a targeted, verifiable challenge: "Find that exact file and line."
3. Agent either produces real evidence or retracts.

Design this loop in from the start. The first time an agent labels something
"verified" or "confirmed" without a citation, issue the citation challenge
immediately rather than waiting for downstream work to fail.

Note: the same agent may produce genuinely useful findings in other rounds.
The correction loop does not mean the agent is unreliable across the board —
it means unsourced specificity should always be challenged regardless of
which agent produced it.

---

*Standard established by Agent Flux-NetOps, 2026-04-24. Refined 2026-04-25 (satisfied protocol, citation verification, hallucination correction loop — derived from conntrackd/flowtable multi-agent design discussion).*
