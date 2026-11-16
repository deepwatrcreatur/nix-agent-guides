# Code Comments in Nix Repositories

Most comments restate what the code does, which the code already shows. The
comments worth writing record what the code cannot show: why a choice was
made, and what breaks if someone "simplifies" it. Coding agents edit code
they have never seen run, so these comments matter even more for them than
for people.

## Two kinds of comment, two syntaxes

| Kind | Syntax | Audience | Example |
| --- | --- | --- | --- |
| API docs for a function other files call | `/** ... */` (RFC 145) | callers | what `cidrContains` takes and returns |
| Rationale at the line it protects | `# TAG: ...` | the next editor | why a unit retries, which upstream default bites |

Module options document themselves through `mkOption { description = ...; }`.
Do not duplicate that in comments.

## Doc comments (RFC 145)

[RFC 145](https://github.com/NixOS/rfcs/pull/145) is the one comment standard
the Nix ecosystem has. A comment starting with `/**` documents the binding
directly below it, in Markdown, with optional `# Example` and other
headings. nixfmt keeps it attached to the binding, nixdoc and
[Noogle](https://noogle.dev) publish it, and `nix repl`'s `:doc` can show it.
nixpkgs `lib` uses it.

~~~nix
/**
  Whether `cidrParent` contains every address of `cidrChild`.

  # Example

  ```nix
  cidrContains "10.0.0.0/8" "10.1.0.0/16"
  => true
  ```
*/
cidrContains = cidrParent: cidrChild: ...
~~~

Use it for exported helpers (`lib/`, functions passed between modules). Write
known limits under their own heading so callers see them.

## Rationale tags

| Tag | Use it for |
| --- | --- |
| `# WHY:` | a non-obvious decision, and the alternative that was rejected |
| `# GOTCHA:` | surprising behaviour of an external system the code depends on |
| `# INVARIANT:` | a property that must keep holding, and the check that enforces it |
| `# SECURITY:` | a permission, trust or secret-handling boundary |
| `# UPSTREAM:` | a workaround for nixpkgs/upstream behaviour, and when it can go |
| `# TODO(#123):` | deferred work, always with an issue number |

Rules:

- **One to three lines, on the line above the code it protects.** The test is
  whether someone editing that line needs it in front of them.
- **Longer explanations go in `docs/`, with a pointer:**
  `# WHY: docs/dns.md#static-host-records-and-pruning`. What was tried and
  what failed is valuable; it just should not sit between the reader and the
  code.
- **Never narrate.** `# enable the service` above `enable = true;` is noise.
- **Keep them true.** A change that makes a tagged comment wrong fixes or
  deletes it in the same commit.
- **Read them before editing a file:**

  ```sh
  rg -n '# (WHY|GOTCHA|INVARIANT|SECURITY|UPSTREAM|TODO)' path/to/file.nix
  ```

The tags are greppable on purpose: one search shows an agent every
constraint in a file before it changes anything.

## Where this comes from

There is no Nix-wide standard for rationale comments. This convention picks
the parts that are already in use:

- RFC 145 doc comments: nixpkgs `lib`, nixdoc, Noogle, nixfmt.
- `WHY:`, `INVARIANT:`, `GOTCHA:` and `SECURITY:` tags each appear in a few
  hundred Nix files on GitHub, including nixpkgs (`lib/lists.nix`) and
  repos such as arcanesys/nixfleet that use them throughout.
- Short comments at the protected line, with long reasoning moved to docs
  behind a pointer, follow olafkfreund/nixarchy's AGENTS.md.
