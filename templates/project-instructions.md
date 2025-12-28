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