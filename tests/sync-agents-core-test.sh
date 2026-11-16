#!/usr/bin/env bash
# Regression tests for scripts/sync-agents-core.sh. Run: tests/sync-agents-core-test.sh
set -euo pipefail

sync="$(cd "$(dirname "$0")/.." && pwd)/scripts/sync-agents-core.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }

# New repo: creates both files with the block.
mkdir "$work/new"
"$sync" "$work/new" >/dev/null
grep -q 'nix-agent-guides:core END' "$work/new/AGENTS.md" || fail "new: block missing"
[ "$(cat "$work/new/CLAUDE.md")" = "@AGENTS.md" ] || fail "new: CLAUDE.md"

# Idempotent.
"$sync" "$work/new" | grep -q '^unchanged' || fail "rerun not idempotent"

# Existing content kept; stale block refreshed; text after the block kept.
mkdir "$work/edit"
printf '# Mine\n\nKeep this.\n' > "$work/edit/AGENTS.md"
"$sync" "$work/edit" >/dev/null
sed -i 's/Shared conventions/STALE/' "$work/edit/AGENTS.md"
echo 'After block.' >> "$work/edit/AGENTS.md"
"$sync" "$work/edit" >/dev/null
grep -q STALE "$work/edit/AGENTS.md" && fail "edit: stale block kept"
grep -q 'Keep this.' "$work/edit/AGENTS.md" || fail "edit: lost text before"
grep -q 'After block.' "$work/edit/AGENTS.md" || fail "edit: lost text after"

# Missing END marker: refuse and leave the file untouched.
mkdir "$work/broken"
printf '# Mine\n<!-- nix-agent-guides:core BEGIN -->\nold\nDeploy rules.\n' > "$work/broken/AGENTS.md"
cp "$work/broken/AGENTS.md" "$work/broken.orig"
if "$sync" "$work/broken" 2>/dev/null; then fail "broken: should exit non-zero"; fi
cmp -s "$work/broken/AGENTS.md" "$work/broken.orig" || fail "broken: file changed"

# END before BEGIN: refuse.
mkdir "$work/reversed"
printf '<!-- nix-agent-guides:core END -->\nx\n<!-- nix-agent-guides:core BEGIN -->\n' > "$work/reversed/AGENTS.md"
if "$sync" "$work/reversed" 2>/dev/null; then fail "reversed: should exit non-zero"; fi

# AGENTS.md -> CLAUDE.md symlink: link kept, target updated.
mkdir "$work/link"
printf '# Claude notes\n' > "$work/link/CLAUDE.md"
ln -s CLAUDE.md "$work/link/AGENTS.md"
"$sync" "$work/link" >/dev/null
[ -L "$work/link/AGENTS.md" ] || fail "link: symlink replaced"
grep -q 'nix-agent-guides:core END' "$work/link/CLAUDE.md" || fail "link: target not updated"

echo "all sync-agents-core tests passed"
