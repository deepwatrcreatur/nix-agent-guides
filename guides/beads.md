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
- **Bead state must not sit on long-lived branches** (moot with the queue branch). A claim nobody else can
  see is no claim. On 2026-11-21 a branch carried 22 commits of unpushed bead
  state for hours while another agent read a stale queue, and two branches
  minted the same child ID.
- **Create child beads from an up-to-date queue,** after fetching and checking
  open PRs that add beads under the same parent.
- **Live checks belong to the bead that deploys.** If a bead's acceptance needs
  a deployed host, put those checks in the deployment/verification bead, or
  neither can close first.

## Workflow: the shared queue branch

Repos with a queue keep it on an orphan **`beads-queue`** branch that holds
only `.beads/`; there is no `.beads/` on `main`. (Not `beads`: that name
conflicts with existing `beads/*` branches.) Agents use **`beads-q`**
(unified-nix-configuration `pkgs/beads-queue.sh`, installed by
`programs.beads`), which wraps `beads-rust` and works from any worktree:

```sh
beads-q ready --json
beads-q show <id>
beads-q update <id> --claim --actor <agent>
beads-q comments add <id> "<note>" --actor <agent>
beads-q close <id> --reason "<what, PR link>" --actor <agent>
```

Each call:

1. fetches `beads-queue` and hard-resets this machine's queue worktree
   (`~/flakes-worktrees/<repo>/beads`, detached) to the remote tip. It holds
   nothing but the queue, so nothing local is lost;
2. deletes and rebuilds the SQLite cache from `issues.jsonl` (upstream treats
   the database as disposable, and 0.1.45's import skips records that are not
   strictly newer, so a rebuild is the only reliable refresh);
3. runs the command;
4. for write commands, exports, commits and pushes. If the push is rejected
   because another agent pushed first, it starts again at step 1. A claim
   someone else now holds then fails with `CLAIM_CONFLICT` (exit 4); a create
   gets the next free child id. No JSONL merge ever happens.

A per-repo `flock` serialises agents on the same machine; `git push` is the
lock between machines. Tested (2026-11-22) with two simulated hosts: a
concurrent claim of one bead left one winner and one `CLAIM_CONFLICT`, and
three concurrent child creates under one parent got distinct ids.

Rules:

- Claim before starting; close after the PR merges, citing it. Beads you
  just created are not reserved for you: other agents pick up new beads
  within minutes.
- Feature branches and PRs never touch `.beads/`.
- Don't edit or run `git` in the queue worktree; every call resets it.
- Name the bead in the PR description on its own line: `Bead: <id>` (several
  allowed) or `Bead: none (<reason>)`. In `nix-clan-homelab` a required
  `bead-reference` check fails unless each named bead is claimed
  (`in_progress`) on `beads-queue`; editing the description re-runs it.
- `owner:` labels say who may take a bead. `owner:any` is open to every
  agent. `owner:claude` beads touch decrypted secrets or live hosts and are
  taken only by Claude working with the operator.

All three repos now keep their queue on `beads-queue`; `nix-clan-homelab`
moved on 2026-11-26 (its PR #72, after its discussion 01). There the branch
is protected against force-push and deletion, a GitHub Actions workflow on
the branch runs a duplicate-id and dangling-dependency check on every push,
and `checks.no-beads-on-main` fails if `.beads/` reappears on `main`.

### Recovering from a conflicted `issues.jsonl`

Only relevant to a queue kept on a code branch, which none of these repos
does any more.

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

