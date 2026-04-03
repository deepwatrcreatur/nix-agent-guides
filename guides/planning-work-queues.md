# Planning Work Queues for Parallel Agents

This guide describes a practical planning system for AI-agent-heavy projects.

It is intentionally lighter than a full project-management framework. The goal
is to help multiple agents contribute safely in parallel without forcing the
project into a heavy planning tool too early.

## Recommended Default

For most Nix projects, use:

- a git-tracked work-item folder
- one small file per PR-sized task
- one branch/worktree per task
- delete task files after merge

This works especially well when:

- agents work in parallel
- tasks are concrete implementation slices
- you want low-overhead planning that lives next to the code

## Why Not Start With A Heavy Planning System

Planning systems with rich dependency graphs can be useful, but they impose
overhead:

- more metadata to maintain
- more abstraction than many repos need
- more context for agents to load before they can start

They become worth it only when you have:

- many simultaneous contributors
- deep dependency chains
- recurring blocked/unblocked task orchestration
- large epics that routinely span many PRs

Until then, a disciplined small-file queue gets most of the value with much
less ceremony.

## Suggested Folder Structure

```text
docs/
  work-items/
    START-HERE.md
    README.md
    agent-prompts.md
    01-first-task.md
    02-second-task.md
    03-third-task.md
```

## File Roles

### `START-HERE.md`

This is the single file you can point a new agent at.

It should explain:

- how to pick the next task
- how to detect whether a task is already in progress
- what invariants must be preserved
- when to use GitHub issues instead
- how to mark a task as claimed or complete

### `README.md`

This is the ordered queue and stable overview.

It should include:

- ranked task order
- status meanings
- brief explanation of the planning system

### `agent-prompts.md`

This contains ready-to-send prompts for agents.

Use this when:

- you want to dispatch tasks quickly
- you want consistent task framing across agents

### Individual Work-Item Files

Each file should represent one PR-sized stream of work.

Good contents:

- status
- suggested branch/worktree name
- priority
- goal
- why it matters
- relevant files
- validation targets
- constraints / do-not-do items

## Status Model

Use a small status vocabulary:

- `blocked`
- `ready`
- `in-progress`
- `done`

Keep the file header authoritative.

## How Agents Should Select Work

Recommended selection rule:

0. refresh remote state first (`git fetch origin`)
1. Read `START-HERE.md`
2. Read the ordered list in `README.md`
3. Pick the first item marked `ready`
4. Check whether the suggested branch/worktree already exists
5. If it exists, do not treat that alone as active ownership. Look for
   evidence such as:
   - a recent commit on the branch
   - an open PR tied to the task
   - the task file already marked `in-progress`
6. If the branch/worktree exists but there is no clear evidence of active
   ownership, treat it as stale and continue with the task
7. Mark the chosen item `in-progress`

If the task queue lives in git, commit and push the status change promptly so
other agents see that the item has been claimed.

This uses both:

- primary truth: status header
- secondary signal: branch/worktree existence

Do not rely only on worktrees, because stale worktrees can exist without active
ownership. Existing branches/worktrees are a hint, not a lock.

## When To Use GitHub Issues

Use GitHub issues for:

- discussion-heavy work
- prioritization across humans
- cross-repo efforts
- multi-PR epics
- unclear or disputed design

Use git-tracked work-item files for:

- narrow implementation tasks
- execution-focused work
- agent handoff
- short-lived queues that should disappear when merged

## Example Work-Item Header

```md
# Stable Interface Matching

Status: `ready`
Suggested branch: `refactor/router-stable-interface-matching`
Priority: `very high`
```

## Example Task Shape

```md
## Goal
Stop depending on fragile kernel interface names for the router role.

## Relevant Files
- `hosts/nixos/router/configuration.nix`
- `hosts/nixos/router/networking.nix`

## Validation
- `nix build .#nixosConfigurations.router.config.system.build.toplevel`

## Do Not
- do not mix this with VLAN work
```

## Recommended Workflow

1. `git fetch origin`
2. create a worktree/branch for one task
3. update task status to `in-progress`
4. commit and push that claim promptly if multiple agents are active
5. implement and validate
6. open PR
7. merge
8. delete the task file or replace it with a smaller follow-up file if needed

## Completion Handling

The simplest default is to delete completed task files once merged.

If a project wants more planning history, an `archive/` subfolder is also a
reasonable option. The important part is to be consistent. For most repos, the
delete-on-merge approach keeps the queue cleaner and easier for agents to scan.

## Good Fit vs Bad Fit

Good fit:

- “make router management plane independent from LAN failure”
- “replace router interface naming with stable matching”
- “add eval checks for router invariants”

Bad fit:

- “redesign all networking eventually”
- “track every possible future feature in one monolithic roadmap”

## Recommendation

Use this small-file queue as the default planning system for future projects.

Only move to a richer, bead-like or issue-heavy planning model when the repo
and contributor load prove that this is no longer enough.
