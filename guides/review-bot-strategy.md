# Review Bot Strategy

This guide describes how to use limited review-bot quota well in Nix-heavy
projects.

## Goal

Spend expensive review capacity on PRs where the bot is likely to catch real
behavioral or operational risk, not on low-signal docs churn.

## Recommended Rule

Use premium review bots on PRs that change:

- module APIs or option schemas
- activation scripts or install scripts
- shell wrappers or secret injection behavior
- router, firewall, or networking behavior
- CI logic or flake output structure
- service defaults, assertions, or failure handling

Skip premium review bots on PRs that only change:

- `README.md`
- `docs/`
- planning queues / work-item files
- typo fixes
- link cleanup

## Practical Monthly Budget

If you have a fixed monthly PR quota, treat it as a budget for behavior-changing
work.

A good default policy is:

- run the premium reviewer on every PR that changes `.nix` behavior or shell
  script behavior
- skip it for docs-only and queue-only PRs

That usually gives better value than spreading the quota evenly across all PRs.

## Good Triggers

Use a premium reviewer when a PR introduces:

- a new flake export
- a new module or module option
- a new wrapper command
- activation-time mutation or install logic
- secrets-related behavior
- policy routing, VPN, firewall, or ingress logic
- non-trivial CI refactors

## Weak Uses

Do not spend quota on:

- README navigation fixes
- planning or roadmap PRs
- work-queue setup
- pure docs clarifications
- tiny cosmetic cleanups

## Ask Better Questions

Premium review is more useful when the PR body asks specific questions.

Examples:

- Look for silent no-op behavior or misleading defaults.
- Check activation-time failure modes and partial-state risks.
- Review backward-compatibility risks for module consumers.
- Look for hidden assumptions in secrets or wrapper injection paths.

## Suggested Workflow

1. Let lightweight bots run on all PRs.
2. Reserve premium review for behavior-changing PRs.
3. Prefer using it on the first real implementation PR in a new area.
4. Track which review findings were actually useful over time.
5. Adjust the policy based on the repos and failure modes you actually have.

## For Multi-Repo Nix Work

In multi-flake setups, use premium review first on repos that are:

- operationally sensitive
- consumed by other repos
- likely to affect deploys or secret handling

That usually means prioritizing:

- infrastructure/config repos
- shared module flakes
- installer/wrapper flakes

over docs-only or template-only repos.
