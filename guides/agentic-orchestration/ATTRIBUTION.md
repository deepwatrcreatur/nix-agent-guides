# Attribution

This guide bundle draws on established ideas rather than inventing a new
theory from scratch.

## Blackboard Architecture

The shared-filesystem coordination model is an application of the blackboard
architectural pattern. Independent specialists coordinate through a shared
state rather than direct pairwise communication.

## Incident Command System

The role split between Incident Commander, Operations, and Communications is
adapted from the Incident Command System. The point is clear ownership during
shared incidents.

## Architecture Decision Records

The ADR structure follows the common Context, Decision, Consequences pattern,
with added emphasis on recording failed paths to prevent future reversion.

## Ground-Truth-First Troubleshooting

The observe-before-change discipline is standard SRE and network forensics
practice. The `tcpdump` -> `strace` -> `ss` sequence is a practical layered
method for locating where packets stop.

## Append-Only Ledgers

The append-only ledger requirement borrows from event sourcing and immutable
audit-log patterns: record what actually happened, then derive summaries from
that record.
