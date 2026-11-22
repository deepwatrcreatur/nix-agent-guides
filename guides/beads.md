# Beads work queues for agents

How agents use a [beads_rust](https://github.com/Dicklesworthstone/beads_rust)
(`br`) work queue in these repos, when several agents (Claude, Codex, agy) work
at once on more than one machine.

Repos with a queue: `nix-clan-homelab` (prefix `nch`),
`nix-router-optimized` (`router`), `unified-nix-configuration`. Each repo's
AGENTS.md has the short version and repo-specific rules; this page is the
reasoning and the full workflow.

## What upstream recommends

Read on 2026-11-21 from beads_rust's README, AGENTS.md,
`docs/AGENT_INTEGRATION.md`, `docs/VCS_INTEGRATION.md` and
`docs/SYNC_SAFETY.md`, and from the original beads
(`steveyegge/beads` `docs/core-concepts/sync-concepts.md`,
`docs/multi-agent/coordination.md`).

1. **JSONL is the truth; the database is a disposable local cache.**
   `.beads/issues.jsonl` is tracked in git. `beads.db` (SQLite, with WAL) and
   its lock files are gitignored and machine-local. `br` never runs git.
2. **Git is the transport.** Before committing: `br sync --flush-only`, then
   stage `.beads/issues.jsonl`. After every pull: `br sync --import-only`. When
   git merged the JSONL cleanly but the database also changed, use
   `br sync --merge`, a three-way merge against the last export. It refuses
   files that still contain conflict markers.
3. **Claim atomically, locally.** `br update <id> --claim` sets you as
   assignee and `in_progress`. If someone else's claim is already in this
   clone's database, it fails with `CLAIM_CONFLICT` (exit 4): don't retry or
   clear their assignment; pick other work. The check is local only, so a claim
   protects nothing across machines until it is pushed and imported there.
4. **Child IDs collide across clones.** `<parent>.N` comes from each
   database's own counter, so two clones can mint the same ID.
   `br sync --merge` keeps the earlier issue and renumbers the other. Top-level
   IDs are hashes and don't collide.
5. **Don't steal stale claims** without evidence that the owner is gone. `br
   ready` hides `in_progress` work on purpose.
6. **Graph hygiene.** Close a bead only on cited evidence (PR link, commit,
   command output). Keep `br dep cycles` empty; never force-close around a
   cycle.
7. **Live coordination is a separate layer.** The beads_rust author pairs it
   with MCP Agent Mail file reservations. Without Mail, the documented fallback
   is: claim, then add a bead comment naming the files you will edit, and pick
   other work if another live claim names the same files.
8. **End every session** with the export, a commit and a push, so other
   agents see the state.
9. **Keep queue data off source branches.** The original beads now syncs its
   data under its own ref (`refs/dolt/data`), separate from `refs/heads/main`.

## Rules for these repos

- **The CLI is `beads-rust`.** `br` can be a different Homebrew tool. The
  pinned version (0.1.45, August 2026) has `update --claim` and
  `sync --merge`, but not `ready --brief` or `coordination`; upstream is at
  v0.7.x.
- **Never share `.beads/` through Syncthing, `/storage` (CIFS), NFS or any
  other file sync.** SQLite's locking is unreliable on network filesystems,
  and file sync copies `beads.db` and its WAL at different moments. Each
  machine keeps its own clone; git carries the JSONL between them.
- **Name yourself.** Pass `--actor <agent>` (for example `claude`, `codex`) so
  claims and comments say who made them.
- **Bead state must not sit on long-lived branches.** A claim nobody else can
  see is no claim. On 2026-11-21 a branch carried 22 commits of unpushed bead
  state for hours while another agent read a stale queue, and two branches
  minted the same child ID.
- **Create child beads from an up-to-date queue,** after fetching and checking
  open PRs that add beads under the same parent.
- **Live checks belong to the bead that deploys.** If a bead's acceptance needs
  a deployed host, put those checks in the deployment/verification bead, or
  neither can close first.

## Workflow today

Until the queue branch below exists, the shared queue is the copy on `main`.
A topic branch's own `git pull` does not bring it in, so start from
`origin/main`:

```sh
git fetch origin && git rebase origin/main && beads-rust sync --import-only
beads-rust list --status in_progress --json           # who is on what
beads-rust ready --json                               # pick
beads-rust update <id> --claim --actor <agent>        # claim
beads-rust sync --flush-only && git add -- .beads/issues.jsonl
# land the claim on its own, in a small commit or PR, right away
# ... work on a feature branch; close in the PR that does the work ...
beads-rust close <id> --reason "<what, PR link>" --actor <agent>
```

- Stage only `.beads/issues.jsonl`. The rest of `.beads/` (database, WAL,
  `beads.base.jsonl` merge snapshots, history backups) is local.
- A closure committed in a PR lands when the PR merges; reopen the bead if the
  PR is abandoned.
- Until a claim reaches `main`, another machine can claim the same bead. Check
  in-progress beads and open PRs first, and keep that window short.

### Recovering from a conflicted `issues.jsonl`

Don't hand-edit conflicted lines. beads-rust 0.1.45 imports an existing
record only if its `updated_at` is strictly newer, records the file as
imported anyway, and the next export writes the database's old copy back.
Upstream treats the database as a disposable cache, so rebuild it instead:

```sh
git checkout origin/main -- .beads/issues.jsonl       # take the shared queue
rm -f .beads/beads.db .beads/beads.db-wal .beads/beads.db-shm
beads-rust sync --import-only                          # rebuild from JSONL
# re-run your own claim/create/comment commands: they get fresh timestamps
beads-rust sync --flush-only && git add -- .beads/issues.jsonl
```

Verified on 0.1.45 (2026-11-22): after a hand edit, a plain import kept the
old record; after deleting the cache, the import took the edit.

## Planned: a shared queue branch

To give every agent on every machine one queue, and to stop code PRs from
conflicting in `.beads/issues.jsonl`:

- Each repo gets an orphan branch `beads` that contains only `.beads/`. With
  no `flake.nix` on it, CI has nothing to build.
- Each machine has one worktree of it, `~/flakes-worktrees/<repo>/beads`.
  Agents point `beads-rust` at it with `BEADS_DIR=<worktree>/.beads`, so the
  queue no longer depends on which feature branch is checked out.
- Every mutation is fetch → reset to `origin/beads` → rebuild the cache →
  mutate → `sync --flush-only` → commit → push. `git push` is the
  cross-machine lock: if two agents claim the same bead, the second push is
  rejected. That agent resets its queue worktree to `origin/beads` (it holds
  nothing but the queue, so its only local change is the rejected commit),
  rebuilds the cache, sees the other claim and picks other work. No JSONL
  merge is ever needed, because each push starts from the remote tip.
- Feature branches and PRs never touch `.beads/`. A bead closes on the queue
  branch after its PR merges, citing the PR.
- A small helper script wraps the steps above, and a user timer fetches
  regularly so each machine sees the other's pushes.

When this lands, each repo's AGENTS.md switches to it and this section moves
to "Workflow today".
