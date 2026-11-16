#!/usr/bin/env bash
# Copy templates/agents-core.md into the AGENTS.md of each repo given.
# Replaces the block between the nix-agent-guides:core markers, or appends it
# when the file has none. Creates AGENTS.md (and a CLAUDE.md that imports it)
# when missing. Prints what changed; commit in each repo yourself.
#
# Usage: scripts/sync-agents-core.sh <repo-dir>...
set -euo pipefail

core="$(cd "$(dirname "$0")/.." && pwd)/templates/agents-core.md"
[ "$#" -gt 0 ] || { echo "usage: $0 <repo-dir>..." >&2; exit 2; }

status=0
for repo in "$@"; do
  agents="$repo/AGENTS.md"
  if [ ! -e "$agents" ]; then
    printf '# Notes for coding agents and contributors\n\n' > "$agents"
    echo "created $agents"
  fi
  # WHY: if AGENTS.md is a symlink (e.g. to CLAUDE.md), update its target so
  # the two names keep sharing one file.
  target="$(readlink -f "$agents")"

  # INVARIANT: refuse to rewrite unless the markers are exactly one BEGIN
  # followed by one END; otherwise everything after BEGIN would be dropped.
  begins="$(grep -c 'nix-agent-guides:core BEGIN' "$target" || true)"
  ends="$(grep -c 'nix-agent-guides:core END' "$target" || true)"
  if [ "$begins" != "$ends" ] || [ "$begins" -gt 1 ]; then
    echo "error: $target has $begins BEGIN and $ends END markers; fix by hand" >&2
    status=1; continue
  fi
  if [ "$begins" = 1 ]; then
    b="$(grep -n 'nix-agent-guides:core BEGIN' "$target" | cut -d: -f1)"
    e="$(grep -n 'nix-agent-guides:core END' "$target" | cut -d: -f1)"
    if [ "$e" -lt "$b" ]; then
      echo "error: $target has END before BEGIN; fix by hand" >&2
      status=1; continue
    fi
  fi

  tmp="$(mktemp)"
  if [ "$begins" = 1 ]; then
    # WHY: awk, not sed, so the block can contain any characters.
    awk -v core="$core" '
      /nix-agent-guides:core BEGIN/ { while ((getline line < core) > 0) print line; skip = 1; next }
      /nix-agent-guides:core END/   { skip = 0; next }
      !skip { print }
    ' "$target" > "$tmp"
  else
    { cat "$target"; printf '\n'; cat "$core"; } > "$tmp"
  fi

  if cmp -s "$tmp" "$target"; then
    echo "unchanged $agents"
  else
    # WHY: write in place rather than mv, to keep the file's mode and links.
    cat "$tmp" > "$target"
    echo "updated $agents"
  fi
  rm -f "$tmp"
  if [ ! -e "$repo/CLAUDE.md" ]; then
    printf '@AGENTS.md\n' > "$repo/CLAUDE.md"
    echo "created $repo/CLAUDE.md"
  fi
done
exit "$status"
