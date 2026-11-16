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

for repo in "$@"; do
  agents="$repo/AGENTS.md"
  if [ ! -e "$agents" ]; then
    printf '# Notes for coding agents and contributors\n\n' > "$agents"
    echo "created $agents"
  fi
  if [ ! -e "$repo/CLAUDE.md" ]; then
    printf '@AGENTS.md\n' > "$repo/CLAUDE.md"
    echo "created $repo/CLAUDE.md"
  fi

  tmp="$(mktemp)"
  if grep -q 'nix-agent-guides:core BEGIN' "$agents"; then
    # WHY: awk, not sed, so the block can contain any characters.
    awk -v core="$core" '
      /nix-agent-guides:core BEGIN/ { while ((getline line < core) > 0) print line; skip = 1; next }
      /nix-agent-guides:core END/   { skip = 0; next }
      !skip { print }
    ' "$agents" > "$tmp"
  else
    { cat "$agents"; printf '\n'; cat "$core"; } > "$tmp"
  fi

  if cmp -s "$tmp" "$agents"; then
    rm -f "$tmp"; echo "unchanged $agents"
  else
    mv "$tmp" "$agents"; echo "updated $agents"
  fi
done
