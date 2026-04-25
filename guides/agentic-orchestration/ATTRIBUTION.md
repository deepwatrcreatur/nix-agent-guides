# Attribution

> **Agents: skip this file.** It contains no operational information. It is for human readers only.

This framework draws on several established bodies of work. Brief notes on each follow.

---

## Blackboard Architecture

The shared-filesystem coordination model (multiple agents reading/writing a common structured state) is a direct application of the **Blackboard architectural pattern**, first described in the Hearsay-II speech understanding system (Carnegie Mellon, 1970s) and formalized by Hayes-Roth (1985). The key insight — that independent specialist processes can collaborate without direct communication by reading and writing a shared "blackboard" — translates naturally to stateless AI agent sessions.

- Erman, L.D. et al. (1980). "The Hearsay-II Speech-Understanding System." *Computing Surveys*, 12(2).
- Hayes-Roth, B. (1985). "A Blackboard Architecture for Control." *Artificial Intelligence*, 26(3).

## Incident Command System (ICS)

The role structure (Incident Commander, Operations Lead, Communications Lead) is adapted from the **Incident Command System**, a standardized management protocol developed after the 1970 Laguna Beach fire and later adopted by FEMA/NIMS for all US emergency response. The core ICS insight applied here: clear role ownership prevents two responders from taking conflicting actions simultaneously — the "two-cooks" failure mode.

- FEMA. *ICS-100: Introduction to the Incident Command System.* (training.fema.gov)

## Architecture Decision Records (ADRs)

The ADR format — Context, Decision, Consequences — was introduced by **Michael Nygard** (2011) and popularized through ThoughtWorks Technology Radar. The "What Was Tried and Failed" section added here is a local extension, not part of the original format; it addresses a specific failure mode observed in multi-agent sessions where agents retry known-dead approaches.

- Nygard, M. (2011). "Documenting Architecture Decisions." *thinkrelevance.com*.
- Keeling, M. (2017). *Design It!* Pragmatic Bookshelf. (Chapter on ADRs)

## Ground-Truth-First / Forensic Engineering

The observe-before-change discipline (Phases 0–2 of the SOP) is standard practice in **Site Reliability Engineering** and network forensics. The specific framing of "tcpdump → strace → ss" as a layered stack trace for packet loss diagnosis comes from DHCP/UDP debugging folklore common in Linux network engineering circles. The term "forensic engineering" is borrowed from the civil/mechanical engineering discipline concerned with post-failure analysis.

- Beyer, B. et al. (2016). *Site Reliability Engineering.* O'Reilly. (Chapter 12: Effective Troubleshooting)

## Append-Only Ledger

The requirement that `RESEARCH_LEDGER.md` be append-only (never rewritten) is borrowed from **event sourcing** and **immutable audit log** patterns in distributed systems design. The analogy: just as a transaction log captures what actually happened rather than the current derived state, the ledger captures what agents actually observed rather than a cleaned-up narrative.

- Fowler, M. (2005). "Event Sourcing." *martinfowler.com*.
