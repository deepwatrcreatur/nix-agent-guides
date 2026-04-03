# Nix Agent Guides

A collection of best practices, workflows, and patterns for using AI coding agents effectively with Nix-based projects.

## Overview

This repository provides guidance for developers using AI coding agents (like Claude Code, GitHub Copilot, etc.) in Nix environments. It covers common patterns, tools, and workflows that make agent-assisted development more efficient and reliable.

## Contents

### 📖 [Guides](./guides/)
- **[Git Workflows](./guides/git-workflows.md)** - Git worktrees, branch management, and collaboration patterns
- **[tmux Sessions](./guides/tmux-sessions.md)** - Remote session management and persistent workflows
- **[Project Setup](./guides/project-setup.md)** - Repository organization and configuration patterns
- **[Best Practices](./guides/best-practices.md)** - General workflow tips and optimization strategies
- **[Review Bot Strategy](./guides/review-bot-strategy.md)** - How to spend limited premium review quota on the PRs that matter

### 📝 [Templates](./templates/)
- **[Project Instructions](./templates/project-instructions.md)** - Template for project-specific agent guidance

## Quick Start

1. **For new projects**: Start with the [project setup guide](./guides/project-setup.md)
2. **For remote work**: Check out [tmux session management](./guides/tmux-sessions.md)
3. **For branching strategy**: Learn [git worktree patterns](./guides/git-workflows.md)

## Suggested Improvements Roadmap

The repository is useful as a concise starter pack, but these changes would significantly improve clarity and adoption:

1. **Add missing linked content or remove stale links**
   - Keep README links synchronized with actual files/directories to avoid dead ends.
2. **Create examples and reference implementations**
   - Add minimal, copy-paste-ready examples for `flake.nix`, `Makefile`, and CI checks.
3. **Add contributor workflow docs**
   - Include a short `CONTRIBUTING.md` with style, review expectations, and validation commands.
4. **Add guide cross-linking and "when to use" sections**
   - Help readers choose the right document quickly.
5. **Add automated docs quality checks**
   - Use markdown linting and link checking in CI to prevent regressions.

## Integration with Existing Projects

These guides are designed to be referenced from project-specific agent instruction files. The recommended approach is:

1. **Reference this repo** in your project's `CLAUDE.md` or `agents.md`
2. **Customize patterns** for your specific project needs
3. **Document project-specific implementations** of the general patterns

Example integration:
```markdown
## Additional Resources
For comprehensive Nix agent workflows, see the [Nix Agent Guides](https://github.com/deepwatrcreatur/nix-agent-guides) repository. The patterns below are customized implementations used specifically in this project.
```

## Contributing

Contributions are welcome! Please feel free to:
- Submit new workflow patterns you've discovered
- Improve existing documentation
- Add examples from your own projects
- Report issues or suggest improvements

## Who This Is For

- Developers using AI coding agents in Nix environments
- Teams working with NixOS, nix-darwin, or Home Manager
- Anyone looking to optimize their agent-assisted development workflow

## License

MIT License - see [LICENSE](LICENSE) for details.
