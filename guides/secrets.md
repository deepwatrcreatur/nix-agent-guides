# Secrets in Agent Work

How agents and operators get API tokens and passwords on machines set up with
[fnox-flake](https://github.com/deepwatrcreatur/fnox-flake), and where other
secret tools apply instead.

## Which tool holds which secret

| Secret is used by | Tool | Example |
| --- | --- | --- |
| A command you or an agent run (gh, curl, nix, AI CLIs) | **fnox**: encrypted per user, decrypted only for the one command | `GITHUB_TOKEN`, `PROXMOX_API_TOKEN`, `ANTHROPIC_API_KEY` |
| A system service on a host | **clan vars** (nix-clan-homelab) or **agenix** (unified-nix-configuration) | router VRRP password, Tailscale auth key |

A secret needed in both places is stored in both. Note that in the bead or doc
that adds it, so a rotation updates both.

## Rules

1. **Run a command that needs a secret through fnox.** Prefer the narrow
   wrapper for the tool (`gh-fnox`, `claude-fnox`, `bw-fnox`, ...; see the
   [wrapper catalog](https://github.com/deepwatrcreatur/fnox-flake/blob/main/docs/wrapper-catalog.md)):
   it loads only that tool's secrets. Otherwise use `fnox exec -- <command>`,
   which gives that one command every declared secret.
   Shell aliases do not apply in an agent's non-interactive shell, so call
   the wrapper by name.
2. **Never put a secret into a long-lived shell.** No
   `export X=$(cat <secret file>)`, no `X=$(fnox get X)`, no `fnox activate`
   in a shell an agent uses. The value must exist only inside the one
   command that needs it.
3. **Never print a secret.** Do not `cat` a token file, `echo` a variable or
   run `fnox get` in a way that shows the value. To check that two copies
   match, compare hashes:
   `fnox exec -- sh -c 'printf %s "$GITHUB_TOKEN" | sha256sum'`.
4. **Keep secrets out of command lines.** Arguments are visible in `ps` and
   shell history. Pass them through the environment or stdin, as in the
   examples below.
5. **Never commit a secret**, and never paste one into a PR, issue, bead or
   chat.

## Examples

GitHub CLI:

```bash
gh-fnox pr list
fnox exec -- gh pr create --fill     # same, through fnox exec
```

`git push` over HTTPS uses `git-credential-fnox` (fnox-flake), which gives
git the fnox token and never reads a token file. Where Home Manager enables
`programs.fnox.gitCredentialHelper`, plain `git push` already uses it.
Otherwise, or with the global git config off (`GIT_CONFIG_GLOBAL=/dev/null`),
name it for the one command; the empty value first drops other helpers, such
as `store`, that would also receive the token:

```bash
git -c credential.helper= -c credential.helper=fnox push
```

On machines without the helper, `fnox exec -- git push` still works with
`gh auth git-credential`, which reads `GITHUB_TOKEN` from its environment.
Never write an inline helper that `cat`s a token file.

`curl` with a bearer token, header sent on stdin so it is not in `ps`:

```bash
fnox exec -- sh -c 'printf "Authorization: Bearer %s\n" "$GITHUB_TOKEN" |
  curl -sS -H @- https://api.github.com/user'
```

Services with their own scheme only change the header line. Proxmox VE, with
`PROXMOX_API_TOKEN` holding `USER@REALM!TOKENID=UUID`:

```bash
fnox exec -- sh -c 'printf "Authorization: PVEAPIToken=%s\n" "$PROXMOX_API_TOKEN" |
  curl -sS -H @- https://pve.example:8006/api2/json/version'
```

Nix with a GitHub access token (avoids API rate limits), passed through
`NIX_CONFIG` rather than `--option`, and appended so settings already in
`NIX_CONFIG` (such as enabling flakes) are kept:

```bash
fnox exec -- sh -c 'NIX_CONFIG="$NIX_CONFIG
access-tokens = github.com=$GITHUB_TOKEN" exec nix flake update'
```

The single quotes matter in the last two: `$VAR` must expand inside the
command fnox starts, not in your shell, where it is empty.

## Adding a secret

1. Declare it in the Home Manager configuration (`programs.fnox`); add a
   `seedSecretSources` entry if a file (for example an agenix user secret)
   should seed it on activation.
2. Store a value without exposing it:

   ```bash
   fnox -c "${FNOX_CONFIG:-$HOME/.config/fnox/config.toml}" set --provider age NAME
   ```

   It prompts with hidden input, or reads stdin when piped. Never pass the
   value as an argument. Naming the file (the one the wrappers read) and the
   provider keeps the value encrypted in your user config, even when the
   current directory has a `fnox.toml` of its own.
3. Check it without printing it:
   `fnox -c "${FNOX_CONFIG:-$HOME/.config/fnox/config.toml}" list` shows
   names, and the probe below shows whether the value works.

## Checking that a secret works

Test the credential itself, not just the command. When fnox's value is
empty or malformed, `gh-fnox` falls back to a token file or to gh's own
stored login, so it can look healthy while `fnox exec` hands out a useless
value. Probe the value directly, against the config the wrappers read and with the
variable unset first: for a secret with no stored value, `fnox exec` passes
the shell's own value through, so a token exported elsewhere would make the
probe pass while fnox holds nothing.

```bash
env -u GITHUB_TOKEN -u GH_TOKEN \
  fnox -c "${FNOX_CONFIG:-$HOME/.config/fnox/config.toml}" exec -- sh -c '
  printf "Authorization: Bearer %s\n" "$GITHUB_TOKEN" |
    curl -sS -o /dev/null -w "%{http_code}\n" -H @- https://api.github.com/user'
```

200 means the token works; 401 means the value fnox returned is not a valid
token (not decrypted, or revoked). Then every `fnox exec` example above fails
too, `git push` included: stop and tell the operator, as below.

## When fnox is unavailable

If `fnox` is missing or cannot decrypt (no identity on that machine), stop
and tell the operator. Do not fall back to reading token files directly.
