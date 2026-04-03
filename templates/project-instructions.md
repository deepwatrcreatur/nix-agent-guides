# [Project Name] - Agent Instructions Template

## Repository Purpose
Brief description of what this project does and its main goals.

## Key Technologies
List the main technologies used:
- **Nix/NixOS:** For system and package management
- **home-manager:** For user-specific dotfiles and packages
- **Nix Flakes:** For reproducible builds
- **[Other technologies specific to your project]**

## How It's Organized
Explain your directory structure:
- `flake.nix`: The main entry point
- `hosts/`: Configurations for each specific machine
- `modules/`: Shared and reusable configuration modules
- `users/`: User-specific settings

## Common Tasks

### Applying Configurations
Provide platform-specific commands:
- **NixOS:** `sudo nixos-rebuild switch --flake .#<hostname>`
- **macOS:** `darwin-rebuild switch --flake .#<hostname>`

### Adding a New Package
Explain where and how to add packages for different scopes.

## Agent Instructions

### Additional Resources
For comprehensive Nix agent workflows, see the [Nix Agent Guides](https://github.com/deepwatrcreatur/nix-agent-guides) repository. The patterns below are customized implementations used specifically in this project.

### Planning And Parallel Work

If this project uses a git-tracked work queue, point agents to a single entry
file such as:

- `docs/work-items/START-HERE.md`

That file should explain:

- how to choose the next available task
- how to detect whether a task is already in progress
- how to use suggested branch/worktree names
- what invariants must be preserved

Recommended rule:

0. fetch remote state first if multiple agents are active
1. pick the highest-priority task still marked `ready`
2. check whether the suggested branch/worktree already exists
3. if it exists, do not treat that alone as active ownership; check for a
   recent commit, an open PR, or the task already marked `in-progress`
4. if there is no clear evidence of active ownership, treat the branch/worktree
   as stale and continue
5. mark the chosen task `in-progress`
6. commit and push that status change promptly if the queue is shared through git

### Shell Environment
- **Default shell**: Specify your default shell (Fish, Zsh, etc.)
- **Shell compatibility**: Note any shell-specific considerations

### Multi-Host Configuration Awareness
- **Always check hostname first**: Start by running `hostname` to identify which host you're working on
- **Host-specific commands**: Use appropriate commands based on the host type

### Host Detection Examples
```bash
# Check which host you're on
hostname
# Then use appropriate rebuild commands:
# For NixOS: sudo nixos-rebuild switch --flake .#hostname
# For Darwin: darwin-rebuild switch --flake .#hostname
```

## Project-Specific Patterns
Add patterns specific to your project here.

### Suggested Task Queue Files

If your project is large enough to benefit from a reusable planning pattern,
consider adding:

```text
docs/work-items/
  START-HERE.md
  README.md
  agent-prompts.md
  01-task-name.md
```

Use GitHub issues for discussion-heavy or multi-PR epics.
Use git-tracked task files for concrete implementation work.

## Testing Before Committing
- **Run build commands first** before committing
- **Analyze ALL output** - not just final success message
- **Verify specific functionality** you intended to fix

---

## Instructions for Using This Template
1. Copy this file to your project as `CLAUDE.md` or `agents.md`
2. Replace placeholders with project-specific information
3. Remove sections that don't apply
4. Add project-specific sections as needed
5. Keep it updated as your project evolves
