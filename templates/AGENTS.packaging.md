# Notes for coding agents and contributors

This flake packages [APPLICATION](https://upstream.example) for Nix.

- Package: `pkgs/<name>.nix` (or `package.nix`); exposed as
  `packages.<system>.default`.
- Build and smoke-test: `nix build .#default && ./result/bin/<name> --version`.
- Update: bump `version`, then replace `hash` (build once with
  `lib.fakeHash` and copy the expected hash from the error). For Rust/Go,
  update `cargoHash`/`vendorHash` the same way.
- Unusual build details: <patches, vendored assets, platforms not supported,
  why a dependency is pinned. Use `# WHY:`/`# UPSTREAM:` tags at the line too.>

<!-- Run scripts/sync-agents-core.sh from nix-agent-guides to add the shared block below. -->
