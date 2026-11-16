# Agent Instruction Files Across Many Repos

How to keep `AGENTS.md`/`CLAUDE.md` consistent across a fleet of Nix repos
without copying hundreds of lines into each one.

## Three layers

| Layer | Lives in | Read by | Holds |
| --- | --- | --- | --- |
| 1. Personal | `~/.claude/CLAUDE.md` (or the agent's equivalent) | your local agents, in every repo | how *you* work: shells, hosts, git transport, commit trailers |
| 2. Shared conventions | the `nix-agent-guides:core` block in each repo's `AGENTS.md` | every agent and review bot, local or cloud | rules every Nix repo follows: comments, validation, secrets |
| 3. Repo-specific | the rest of that repo's `AGENTS.md`, plus `docs/` | every agent and review bot | layout, checks to run, pitfalls, deploy rules |

The canonical text of the shared layer is
[`CONVENTIONS.md`](../CONVENTIONS.md), which agents can read from its raw URL.
The block in each repo summarises it and names that URL first.

The summary is still copied into each repo, because the URL alone is not
enough:

- Review bots and some agents have no network access during a task, and
  Claude Code's `@import` only reads local files.
- Agents that can fetch usually treat fetched pages as information, not
  instructions. A rule they must follow has to be in the repo they work in.
- The online file can change after a commit. The in-repo copy shows the rules
  that applied when that code was written.

- Mutable content from another repository must not be able to steer agents.
  The block therefore labels the URL as reference only and ranks the repo's
  own text, including the summary, above it. A compromised
  `CONVENTIONS.md` can then at worst mislead about style, not inject
  commands.

So the essential rules live in the in-repo block, and `CONVENTIONS.md` holds
the full and newest text. Change both together, bump the block's version
(`v3`, ...), and re-run the sync script.

## Rules for each repo

- `AGENTS.md` is the single source. `CLAUDE.md` contains only `@AGENTS.md`
  (plus Claude-only additions if really needed). Never maintain two parallel
  files: they drift.
- Keep `AGENTS.md` short. Put procedures and history in `docs/` and link them.
  An agent reads the whole file on every task.
- Carry the shared block unchanged. Update it with
  `scripts/sync-agents-core.sh <repo>...` from this repo, then commit in each
  repo.

## Sizing by repo type

**Packaging repos** (a flake that packages one application): the shared block
plus a few lines: what is packaged, how to build and run it, how updates
work (version/hash bumps), and anything unusual about the build. Start from
`templates/AGENTS.packaging.md`.

**Module and infrastructure repos** (NixOS modules consumed by other flakes,
multi-host configurations): the shared block plus layout, which checks to
run for which change, the public interface (option names and defaults other
flakes rely on), deploy and safety rules, and recurring pitfalls. These repos
also benefit most from rationale tags and `docs/` pointers; see
[code-comments.md](code-comments.md).

## Rolling it out

```sh
# from this repo
scripts/sync-agents-core.sh ~/flakes-worktrees/<repo>/main ...
```

The script appends the block if missing, replaces it if present, and creates
`AGENTS.md` and `CLAUDE.md` (`@AGENTS.md`) when absent. If `AGENTS.md` is a
symlink, it updates the target. It refuses (and changes nothing) when the
markers are missing, duplicated or reversed. It does not otherwise touch an
existing `CLAUDE.md`; merge a standalone one into `AGENTS.md` by hand.
Tests: `tests/sync-agents-core-test.sh`.
