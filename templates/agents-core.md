<!-- nix-agent-guides:core BEGIN (v1). Synced from deepwatrcreatur/nix-agent-guides templates/agents-core.md by scripts/sync-agents-core.sh. Edit it there, not here. -->
## Shared conventions

- **Comments explain why, not what.** Mark them `# WHY:`, `# GOTCHA:`,
  `# INVARIANT:`, `# SECURITY:`, `# UPSTREAM:` or `# TODO(#issue):`. One to
  three lines above the code they protect; longer reasoning goes in `docs/`
  with a pointer (`# WHY: docs/x.md#heading`). Never narrate the next line.
- **Before editing a file**, read its tags:
  `rg -n '# (WHY|GOTCHA|INVARIANT|SECURITY|UPSTREAM|TODO)' <file>`.
  Fix or delete any tag your change makes untrue.
- **Exported Nix functions** get RFC 145 doc comments (`/** ... */`,
  Markdown, `# Example` section when useful).
- **Validate before committing:** the narrowest `nix build .#checks.<system>.<name>`
  or `nix build .#<package>` first, then `nix flake check`. For shell embedded
  in Nix, run `bash -n`/`shellcheck` on the generated script.
- **Same change, same PR:** behaviour changes come with their docs and an
  eval check or test.
- **Never commit secrets**, and do not deploy to or change live hosts unless
  asked.

Details: https://github.com/deepwatrcreatur/nix-agent-guides/blob/main/guides/code-comments.md
<!-- nix-agent-guides:core END -->
