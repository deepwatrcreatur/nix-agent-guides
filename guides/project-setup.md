# Project Setup for Agent-Friendly Nix Development

This guide covers how to organize Nix projects to be maximally effective with AI coding agents.

## Repository Structure Guidelines

### Recommended Layout

```
project/
├── flake.nix                    # Main flake entrypoint (keep at root)
├── flake.lock                   # Locked dependencies (keep at root)
├── README.md                    # Quick overview before diving in
├── CLAUDE.md                    # Project-specific agent instructions
├── Makefile                     # Standard build/test commands
├── hosts/                       # Host-specific configurations
│   ├── <hostname>/              # NixOS and Darwin configs by hostname
│   │   ├── configuration.nix    # Main host config
│   │   ├── hardware.nix         # Hardware-specific settings
│   │   └── services.nix         # Host-specific services
│   └── shared/                  # Cross-platform host configs
├── modules/                     # Shared and reusable modules
│   ├── common/                  # Cross-platform modules
│   ├── nixos/                   # NixOS-specific modules
│   ├── nix-darwin/              # macOS-specific modules
│   └── overlays/                # Package overlays
├── home-manager/                # User environment configurations
│   ├── hosts/                   # Host-specific HM profiles
│   │   └── <hostname>.nix       # Matching HM profile per host
│   ├── modules/                 # Reusable HM modules
│   └── applications/            # User application configs
├── pkgs/                        # Custom packages
│   ├── <package-name>/          # Package directory
│   │   └── default.nix          # Package definition
│   └── default.nix              # Package registry/wiring
├── docs/                        # Long-form documentation
├── reference/                   # Reference materials
├── fixtures/                    # Test fixtures
└── examples/                    # Example configurations
```

### Key Organizational Principles

1. **Keep flake entrypoints at root** - `flake.nix` and `flake.lock` should remain at the repository root
2. **Host-specific structure** - Use `hosts/<hostname>/` for system configs with matching `home-manager/hosts/<hostname>.nix`
3. **Clear separation** - Separate shared modules, overlays, and applications into distinct directories
4. **Custom packages** - Use `pkgs/<name>/default.nix` and wire through `pkgs/default.nix`
5. **Documentation hierarchy** - Use `docs/` for long-form, `README.md` for overview

## Standard Build and Development Commands

### Makefile Integration

Create a `Makefile` with standard commands:

```makefile
# Makefile for Nix project automation

.PHONY: lint test check update show

# Run all linters
lint:
	statix check .
	deadnix
	# Add other linters (shellcheck, etc.)

# Run test suite
test:
	# Run ShellSpec or other test framework
	# shellspec home-manager/claude-code/hooks/spec

# Combined check (default pre-commit gate)
check: lint test

# Rebuild current machine
update:
	@if command -v darwin-rebuild >/dev/null 2>&1; then \
		darwin-rebuild switch --flake .; \
	elif command -v nixos-rebuild >/dev/null 2>&1; then \
		sudo nixos-rebuild switch --flake .; \
	else \
		echo "No rebuild command available"; \
		exit 1; \
	fi

# Show available flake outputs
show:
	nix flake show

# Update flake inputs
update-inputs:
	nix flake update

# Check flake evaluation
eval:
	nix flake check
```

### Agent-Friendly Development Workflow

```bash
# Standard development cycle
make check          # Always run before committing
make update         # Apply changes to current host
nix flake show      # Inspect available outputs
make update-inputs  # Update dependencies when needed
```

## Coding Style and Conventions

### Nix Formatting Standards

```nix
# Good: Two-space indents, trailing commas, alphabetized when practical
{
  config,
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    git,
    htop,
    vim,  # Trailing comma
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false,  # Follow upstream camelCase
      PermitRootLogin = "no",
    };
  };
}
```

### File Naming Conventions

- **Use kebab-case** for filenames: `rust-toolchain.nix`, `gpu-monitoring.nix`
- **Follow upstream names** for options (often camelCase) rather than creating aliases
- **Consistent structure** within package directories

### Shell Script Standards

```bash
#!/usr/bin/env bash
# All shell scripts must be POSIX-compliant
set -euo pipefail  # Always start with this

# Script content here
```

- Must pass `shellcheck`
- Use POSIX compliance when possible
- Include proper error handling

## Testing Guidelines

### Testing Strategy

1. **Favor evaluation-only tests** - Test that configurations evaluate without building
2. **Focused module testing** - Test individual modules in isolation
3. **Expand test coverage** alongside any changes

### Test Structure

```bash
# Example test commands
nix eval .#nixosConfigurations.hostname.config.system.build.toplevel --dry-run
nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem) --dry-run

# ShellSpec for shell components
shellspec fixtures/test-spec.sh
```

### Pre-commit Testing

```bash
# Always run before requesting reviews
make check  # Combines linting and testing
```

## Security and Configuration Best Practices

### Secret Management

```nix
# Never commit secrets directly
# Use example files instead:
# hosts/hostname/secrets.yaml.example

# Good: Reference example in documentation
# Bad: Include actual secrets in repository

# Use sops-nix or similar for encrypted secrets
sops.secrets.api-key = {
  sopsFile = ./secrets.yaml;
  owner = "myuser";
};
```

### Safe Deployment Patterns

```bash
# For risky changes, follow this pattern:
make check                    # Validate locally
make update                   # Deploy to target host
# Verify deployment succeeds before merging
```

## Commit and Pull Request Guidelines

### Commit Message Format

```
module/scope: imperative mood description

Examples:
- modules/editor: enable tree-sitter syntax highlighting
- hosts/workstation: add GPU monitoring tools
- pkgs/rust-toolchain: bump to latest stable
- home-manager/git: configure delta for diff viewing
```

### Commit Organization

- **Group edits by scope** - host, module, or functional area
- **One logical change per commit** - easier to review and revert
- **Include context** in commit messages about why, not just what

### Pull Request Standards

A good PR should include:

1. **Clear summary** of the change and motivation
2. **Affected hosts** - list which systems are impacted
3. **Test results** - output from `make check`
4. **Screenshots** for UI-facing changes
5. **Issue links** when available
6. **Follow-up work** description if applicable

Example PR template:
```markdown
## Summary
Add GPU monitoring support for inference workstations

## Changes
- Add `gpu-monitoring.nix` module with nvtop and monitoring aliases
- Enable module on inference1 and workstation hosts
- Add shell aliases for common GPU monitoring tasks

## Testing
- `make check` passes ✅
- Tested on inference1: nvtop displays Tesla P40 correctly
- Verified aliases work in fish, bash, and zsh

## Affected Hosts
- inference1 (primary testing)
- workstation (secondary)

Fixes #123
```

## Integration with Development Tools

### direnv Configuration

```nix
# .envrc
use flake

# Optional: Project-specific environment
export PROJECT_ROOT=$(pwd)
export NIX_CONFIG="extra-experimental-features = nix-command flakes"
```

### Editor Integration

```nix
# Include common development tools in devShell
outputs = { ... }: {
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      # Nix tools
      nixpkgs-fmt
      statix
      deadnix
      nix-tree

      # Shell tools
      shellcheck
      shfmt

      # Documentation
      mdbook
    ];

    shellHook = ''
      echo "Available commands: make check, make update, make show"
      echo "Linting: statix, deadnix, shellcheck"
    '';
  };
};
```

### Git Hooks

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit
set -euo pipefail

echo "Running pre-commit checks..."
make check

if [ $? -ne 0 ]; then
    echo "Pre-commit checks failed. Please fix issues before committing."
    exit 1
fi
```

## Advanced Organizational Patterns

### Module Dependencies and Options

```nix
# Clear module interface with options
{ config, lib, pkgs, ... }:
{
  options.myProject.feature = {
    enable = lib.mkEnableOption "feature description";

    package = lib.mkPackageOption pkgs "default-package" {
      description = "Package to use for feature";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional configuration";
    };
  };

  config = lib.mkIf config.myProject.feature.enable {
    # Implementation here
  };
}
```

### Overlay Organization

```nix
# overlays/default.nix - Clean overlay management
{
  # Import all overlays from this directory
  custom-packages = import ./custom-packages;
  modifications = import ./modifications;

  # Or specific overlays
  rust-toolchain = final: prev: {
    rustc = prev.rustc.override { ... };
  };
}
```

## Documentation Standards

### Inline Documentation

```nix
{ ... }: {
  # Enable SSH daemon for remote access
  # This is required for deployment and remote management
  services.openssh = {
    enable = true;

    # Security hardening - disable password auth
    # Forces use of SSH keys for authentication
    settings.PasswordAuthentication = false;

    # Restrict access to specific users
    # Add users to this list as needed
    settings.AllowUsers = [ "admin" "deploy" ];
  };
}
```

### README Structure

```markdown
# Project Name

Brief description for humans and agents.

## Quick Start
```bash
# Essential commands to get started
git clone <repo> && cd <repo>
make check && make update
```

## Project Structure
- Brief explanation of key directories
- How to add new hosts/modules/packages

## Development
- `make check` - Run all checks
- `make update` - Apply to current host
- `make show` - List available outputs

## Adding New Components
- Step-by-step guides for common tasks

[Link to comprehensive docs/]
```

This structure provides a solid foundation for both human developers and AI agents to work effectively with Nix projects while maintaining consistency and quality.