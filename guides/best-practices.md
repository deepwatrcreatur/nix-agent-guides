# Best Practices for AI Agent Development with Nix

## General Workflow Principles

### 1. Test Before Commit
- **Always run build commands first** before committing changes
- Use `test` command instead of `switch` for safer testing
- Check for warnings and errors, not just final success

### 2. Maintain Context
- Use descriptive commit messages that explain the "why"
- Keep branches focused on specific features or fixes
- Document decisions in code comments for future agents

### 3. Incremental Development
- Make small, focused changes rather than large rewrites
- Test each change independently when possible
- Use git worktrees for parallel development streams

## Platform-Specific Best Practices

### NixOS Systems
- Always check `hostname` before running rebuild commands
- Use `sudo nixos-rebuild test` for safe testing
- Account for non-FHS compliance in scripts and paths
- Consider hardware-specific modules for different hosts

### macOS (nix-darwin) Systems
- Use `darwin-rebuild test` for safe testing
- Respect macOS security restrictions and prompts
- Be aware of Homebrew integration considerations
- Handle System Preferences permissions gracefully

## Code Organization

### Module Structure
- Separate platform-specific code into appropriate directories
- Use clear, descriptive module names and comments
- Avoid conditional logic within shared modules
- Prefer composition over complex inheritance

### Configuration Management
- Keep secrets encrypted and properly managed
- Use consistent naming conventions across hosts
- Document host-specific requirements and constraints
- Maintain clear separation between system and user configs

## Agent-Specific Patterns

### Error Handling
- Always read and analyze full command output
- Look for warnings and non-fatal errors that might indicate problems
- Test edge cases and error conditions
- Provide clear error messages and recovery steps

### Communication
- Use concise, direct responses unless detail is requested
- Focus on facts and technical accuracy over validation
- Disagree respectfully when technical evidence conflicts with assumptions
- Ask clarifying questions when requirements are ambiguous

### Tool Usage
- Prefer established Nix tools over custom solutions
- Use appropriate tools for the task (don't use grep when Read tool is available)
- Batch related operations when possible for efficiency
- Clean up temporary files and processes

## Security Considerations

### Secrets Management
- Never commit plain-text secrets or keys to repositories
- Use sops-nix or similar tools for encrypted secret management
- Rotate secrets regularly and document the process
- Restrict access to secrets to only necessary services/users

### Access Control
- Follow principle of least privilege for user permissions
- Use SSH keys instead of passwords where possible
- Regularly audit and update access controls
- Document security requirements and procedures

## Performance Optimization

### Build Efficiency
- Use binary caches when available
- Enable parallel building when appropriate
- Clean up old generations and garbage collect regularly
- Monitor build times and optimize bottlenecks

### Resource Management
- Monitor system resources during builds and operations
- Use appropriate hardware for different types of builds
- Consider memory and disk usage for large configurations
- Optimize for the specific use case and hardware

## Final Principles

1. **Reliability over cleverness** - Prefer simple, reliable solutions
2. **Documentation over memory** - Write things down, don't rely on memory
3. **Testing over assumptions** - Verify that things work as expected
4. **Clarity over brevity** - Make code and configs easy to understand
5. **Security by default** - Choose secure options as the default
6. **Maintainability over perfection** - Build for long-term maintenance

Following these practices leads to more reliable, maintainable, and secure Nix configurations that work well with AI agent assistance.