# Best Practices for AI Agent Development with Nix

## Development Workflow Standards

### Pre-Commit Gate Pattern

Always follow this sequence before committing:

```bash
# Standard pre-commit workflow
make check          # Run linting and tests
make update         # Apply to current host
# Verify deployment succeeds
git add .
git commit -m "module/scope: imperative description"
```

### Testing Strategy

1. **Evaluation-first testing** - Test configurations evaluate before building
2. **Focused module testing** - Test individual modules in isolation
3. **Incremental validation** - Test each change independently when possible

```bash
# Evaluation testing
nix eval .#nixosConfigurations.hostname.config --dry-run
nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem) --dry-run

# Focused testing
nix eval .#nixosConfigurations.hostname.config.services.myservice

# Full check
make check  # Combines linting, testing, and validation
```

## Code Quality Standards

### Nix Formatting Conventions

```nix
# Standard formatting: 2-space indents, trailing commas, alphabetized
{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    git,
    htop,
    vim,  # Always include trailing comma
  ];

  # Follow upstream option names (camelCase) rather than aliases
  services.openssh.settings = {
    PasswordAuthentication = false,  # Not password-auth
    PermitRootLogin = "no",         # Not permit-root
  };
}
```

### File and Module Organization

- **Use kebab-case filenames**: `gpu-monitoring.nix`, `rust-toolchain.nix`
- **Group by functionality**: Related options in same module
- **Clear module interfaces**: Use options for configurable modules
- **Avoid deep nesting**: Prefer composition over complex inheritance

### Shell Script Standards

```bash
#!/usr/bin/env bash
# Required header for all shell scripts
set -euo pipefail

# Script content here
# Must be POSIX-compliant and pass shellcheck
```

## Security Best Practices

### Secret Management

```nix
# Never commit secrets - use example files
# Good: secrets.yaml.example
# Bad: secrets.yaml with real values

# Use proper secret management
sops.secrets.database-password = {
  sopsFile = ./secrets.yaml;
  owner = config.services.myapp.user;
  mode = "0440";
};

# Reference secrets safely
services.myapp.passwordFile = config.sops.secrets.database-password.path;
```

### Safe Deployment Pattern

```bash
# For risky changes, always validate locally first
make check                    # Local validation
make update                   # Deploy to target
# Verify functionality before merging
```

## Agent-Specific Workflow Patterns

### Error Handling and Analysis

```bash
# Always analyze full output, not just success/failure
make check 2>&1 | tee check.log  # Capture all output
# Look for:
# - Warning messages (even non-fatal)
# - Permission errors in activation scripts
# - Failed scripts that ran silently
# - Package installation failures
```

### Systematic Debugging Process

1. **Reproduce issue** in controlled environment
2. **Isolate variables** with minimal test case
3. **Check evaluation** before building
4. **Test incrementally** to identify specific failure
5. **Document solution** for future reference

### Communication Standards

- **Use concise, direct responses** unless detail requested
- **Focus on technical accuracy** over validation
- **Provide specific error messages** and recovery steps
- **Ask clarifying questions** when requirements unclear

## Platform-Specific Patterns

### NixOS Best Practices

```bash
# Always check platform first
hostname
uname -a

# Use test before switch
sudo nixos-rebuild test --flake .#hostname

# Check specific components
systemctl status myservice
journalctl -u myservice -f
```

### macOS (nix-darwin) Best Practices

```bash
# Test darwin builds
darwin-rebuild test --flake .#hostname

# Handle macOS permissions gracefully
# Check System Preferences when operations fail
# Respect security restrictions
```

### Home Manager Best Practices

```bash
# Test home manager separately when possible
home-manager switch --flake .#user@hostname

# Check activation scripts
home-manager news  # Check for breaking changes
```

## Build and Performance Optimization

### Efficient Build Patterns

```bash
# Use binary caches
nix build --option substituters "https://cache.nixos.org https://nix-community.cachix.org"

# Parallel builds
nix build --cores 0 --max-jobs auto

# Build specific components
nix build .#nixosConfigurations.hostname.config.system.build.toplevel

# Clean up regularly
nix-collect-garbage -d
nix store gc
```

### Resource Management

- **Monitor build resources** during compilation
- **Use appropriate hardware** for build type
- **Consider memory usage** for large configurations
- **Optimize for specific use cases** and constraints

## Documentation and Commit Standards

### Commit Message Format

```
module/scope: imperative mood description

Examples:
modules/gpu: add Tesla P40 support with CUDA 6.1
hosts/inference1: enable Ollama with GPU acceleration
pkgs/nvtop: add GPU monitoring package
home-manager/shell: add GPU monitoring aliases
```

### Code Documentation Standards

```nix
{ ... }: {
  # Enable Ollama service for AI inference
  # Configured with Tesla P40 GPU support (CUDA compute 6.1)
  services.ollama = {
    enable = true;

    # GPU acceleration settings
    # Tesla P40 requires CUDA architecture 6.1 support
    acceleration = "cuda";
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "0";  # Use first GPU only
    };
  };
}
```

### Project Documentation Hierarchy

```
project/
├── README.md           # Quick start and overview
├── CLAUDE.md          # Agent-specific instructions
├── docs/              # Comprehensive documentation
│   ├── development.md # Development workflows
│   ├── deployment.md  # Deployment procedures
│   └── troubleshooting.md
└── reference/         # Reference materials
    ├── hardware.md    # Hardware-specific notes
    └── examples/      # Configuration examples
```

## Testing and Validation Standards

### Automated Testing Integration

```makefile
# Makefile testing targets
test:
	shellspec fixtures/
	nix eval .#checks.$(shell nix eval --impure --raw --expr builtins.currentSystem)

lint:
	statix check .
	deadnix
	shellcheck scripts/*.sh

check: lint test  # Combined validation
```

### Manual Testing Checklist

Before committing changes:
- [ ] `make check` passes without warnings
- [ ] Target functionality works as expected
- [ ] No regressions in existing functionality
- [ ] Documentation updated for new features
- [ ] Commit message follows standards

### Rollback Procedures

```bash
# NixOS rollback
sudo nixos-rebuild --rollback switch

# Check available generations
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Switch to specific generation
sudo nix-env --switch-generation 42 -p /nix/var/nix/profiles/system
```

## Advanced Development Patterns

### Module Testing Pattern

```nix
# Test module in isolation
{ pkgs ? import <nixpkgs> {} }:
let
  testModule = import ./modules/gpu-monitoring.nix;
  testConfig = {
    config = {};
    lib = pkgs.lib;
    pkgs = pkgs;
  };
in
testModule testConfig
```

### Multi-Host Validation

```bash
# Test across multiple hosts
for host in homeserver workstation inference1; do
  echo "Testing $host..."
  nix build ".#nixosConfigurations.$host.config.system.build.toplevel"
done
```

### Development Shell Integration

```nix
# Include validation tools in development environment
outputs = { ... }: {
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      # Nix tools
      statix deadnix nixpkgs-fmt

      # Validation tools
      shellcheck nodePackages.prettier

      # Development utilities
      just direnv
    ];

    shellHook = ''
      echo "Development environment ready"
      echo "Run 'make check' before committing"
    '';
  };
};
```

## Final Quality Principles

1. **Reliability over cleverness** - Simple, tested solutions win
2. **Documentation over memory** - Write it down, don't rely on memory
3. **Testing over assumptions** - Verify that things work as expected
4. **Consistency over perfection** - Follow established patterns
5. **Security by default** - Choose secure defaults always
6. **Maintainability over optimization** - Code for the next developer

## Continuous Improvement

### Learning from Issues

- **Analyze failures systematically** to understand root causes
- **Update documentation** based on lessons learned
- **Share knowledge** about solutions and patterns
- **Improve tooling** to prevent recurring issues

### Tool Evaluation

- **Stay current** with Nix ecosystem developments
- **Evaluate tools systematically** before adoption
- **Consider maintenance burden** vs benefits
- **Balance innovation** with stability needs

Following these practices leads to reliable, maintainable, and secure Nix configurations that work effectively with AI agent assistance while maintaining high code quality and development velocity.