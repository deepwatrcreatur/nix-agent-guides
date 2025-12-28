# Git Workflows for Agent Development

## Git Worktrees for Multi-Branch Development

### Why Worktrees?
When developing complex Nix configurations, you often need to test different approaches in parallel, compare configurations side-by-side, and keep a stable branch while experimenting.

### Setting Up Worktrees
```bash
# Set up worktrees for different development streams
git worktree add ../project-main main
git worktree add ../project-feature feature-branch
git worktree add ../project-experimental experimental-branch
```

### Recommended Naming Convention
```
~/projects/
├── nix-main/          # Stable configuration (main branch)
├── nix-cuda/          # GPU/CUDA development
├── nix-minimal/       # Lightweight testing
└── nix-experimental/  # Risky experiments
```

### Workflow Benefits
- **Parallel development**: Build different configurations simultaneously
- **Configuration comparison**: Diff configurations side-by-side
- **Rollback safety**: Keep known-good configuration always available

### Worktree Management
```bash
# List all worktrees
git worktree list

# Remove completed worktree
git worktree remove ../project-experimental

# Prune deleted worktrees
git worktree prune
```

## Agent-Specific Considerations

### Commit Message Format
```
type(scope): description

feat(inference-vm): add CUDA support with Tesla P40
fix(homeserver): resolve boot issues with ZFS
docs(agents): add tmux session management guide
```

### Commit Signing
Agents cannot handle interactive GPG prompts:
```bash
# Disable signing for agent commits
git config commit.gpgsign false

# Or use --no-gpg-sign flag
git commit --no-gpg-sign -m "feat: add feature"
```

## Best Practices
1. **Always use descriptive worktree names**
2. **Keep worktrees organized in a single parent directory**
3. **Clean up completed worktrees regularly**
4. **Use worktrees for risky experiments**
5. **Maintain one stable worktree as fallback**