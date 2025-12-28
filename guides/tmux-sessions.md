# tmux Session Management for Remote Development

## Why tmux for Agent Development?

AI agents often need to maintain persistent sessions across network disconnections, run long-duration builds and tests, and monitor multiple processes simultaneously.

## Basic tmux Usage for Agents

### Creating and Managing Sessions
```bash
# Create a named session for your work
ssh host "tmux new-session -d -s inference-test"

# Attach to session (interactive)
ssh -t host "tmux attach-session -t inference-test"

# Send commands to session without attaching
ssh host "tmux send-keys -t inference-test 'cd /path/to/work' Enter"
ssh host "tmux send-keys -t inference-test 'ollama serve' Enter"

# Check if session exists
ssh host "tmux list-sessions | grep inference-test"

# Kill session when done
ssh host "tmux kill-session -t inference-test"
```

### Multiple Windows for Task Separation
```bash
# Create windows for different tasks
ssh host "tmux new-window -t inference-test -n 'server'"
ssh host "tmux new-window -t inference-test -n 'testing'"
ssh host "tmux new-window -t inference-test -n 'monitoring'"

# Send commands to specific windows
ssh host "tmux send-keys -t inference-test:server 'ollama serve' Enter"
ssh host "tmux send-keys -t inference-test:testing 'ollama list' Enter"
ssh host "tmux send-keys -t inference-test:monitoring 'nvitop' Enter"

# List windows in session
ssh host "tmux list-windows -t inference-test"
```

### Background Process Management
```bash
# Start background processes that persist across SSH disconnections
ssh host "tmux send-keys -t session-name 'nohup command > output.log 2>&1 &' Enter"

# Monitor background processes
ssh host "tmux send-keys -t session-name 'ps aux | grep process-name' Enter"

# Check process logs
ssh host "tmux send-keys -t session-name 'tail -f output.log' Enter"
```

## Agent-Specific Patterns

### Named Sessions for Different Tasks
```bash
# Create task-specific sessions
ssh host "tmux new-session -d -s build"
ssh host "tmux new-session -d -s testing"
ssh host "tmux new-session -d -s monitoring"
ssh host "tmux new-session -d -s inference"
```

### Session per Development Branch
```bash
# Session for each git worktree
ssh host "tmux new-session -d -s main -c ~/nix-main"
ssh host "tmux new-session -d -s cuda -c ~/nix-cuda"
ssh host "tmux new-session -d -s minimal -c ~/nix-minimal"
```

## Best Practices for Agents

1. **Always use named sessions** - Makes it easier to reconnect and manage multiple tasks
2. **Create task-specific sessions** - e.g., "inference-test", "build-debug", "service-monitor"
3. **Use multiple windows** - Separate concerns like server processes, testing, and monitoring
4. **Check session existence** - Before creating, verify if session already exists to avoid conflicts
5. **Clean up sessions** - Kill sessions when work is complete to avoid resource accumulation