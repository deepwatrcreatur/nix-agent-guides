# SOP: Forensic Engineering for Agents

Rule: do not make configuration changes based on symptoms or likely causes.
Establish ground truth first.

## Phase 0: Snapshot State Before Touching Anything

Before any probe or change, capture where you are:

```bash
ssh <host> "nixos-rebuild list-generations | tail -5"
ssh <host> "systemctl status <service>"
ssh <host> "ip addr; ip route; ss -tulpn"
```

Log these outputs in `RESEARCH_LEDGER.md` before proceeding.

## Phase 0.5: Risk Classification

| Class | Examples | Approval Bar |
| --- | --- | --- |
| Observe-only | `tcpdump`, `strace`, `ss`, `journalctl`, `nix eval` | Ops can run immediately |
| Local-only mutation | editing a worktree, local `nix build` | Ops or IC |
| Live low-risk mutation | transient debug process, read-only failover probe | IC approval plus rollback anchor |
| Live high-risk mutation | deploy, rollback, firewall or routing change | IC approval plus explicit mutation owner |

If the risk class is disputed, default upward.

## Phase 1: Isolation

### 1a. Pinpoint the Config State

Do not trust source code alone. Verify rendered and live configuration:

```bash
ssh <host> "cat /etc/<service>/config.conf"
nix eval .#nixosConfigurations.<host>.config.services.<x>.settingName
ssh <host> "systemctl cat <service>"
```

### 1b. Bisect the Failure

If this is a regression:

```bash
ssh <host> "nixos-rebuild list-generations"
ssh <host> "sudo nixos-rebuild switch --rollback"
```

### 1c. Establish the Runtime/Source Boundary

Keep these states distinct:

1. what source says
2. what evaluation renders
3. what the live host is running

## Phase 2: Observation

Use the smallest toolset that answers where the data stops.

### Tool 1: `tcpdump`

```bash
tcpdump -ni <interface> <filter>
```

If the packet is not here, the problem is upstream.

### Tool 2: `strace`

```bash
strace -p <PID> -e trace=network -s 256
strace -p <PID> -e trace=open,openat,bind,connect,recvmsg,sendto -s 256
```

If `tcpdump` sees traffic but `strace` shows no receive syscall, the
application is deaf.

### Tool 3: `ss`

```bash
ss -uapn
ss -tapn
```

Use this to verify actual socket binding state.

### Tool 4: `journalctl`

```bash
journalctl -u <service> -b
journalctl -u <service> -f
journalctl -k -b
```

### Tool 5: Kernel packet disposition

```bash
nft list ruleset
conntrack -L
sysctl net.ipv4.conf.<interface>.rp_filter
```

## Phase 3: Mask Check

Before declaring success, rule out masking layers:

- standby/ready/passive service state
- firewall drops after raw capture
- reverse-path filtering
- MAC or policy-based routing asymmetry
- AppArmor/SELinux denial
- systemd socket activation races

A fix that passes observation but fails the mask check is not a fix.

## Phase 4: Fix Verification

After any change, re-run the same probes:

1. confirm config change is live
2. confirm socket state changed
3. confirm packet receive path
4. confirm end-to-end behavior

If any fail, return to Phase 1.

## Phase 5: Closeout

Once the fix is verified:

1. update `SUMMARY.md`
2. record durable design choices as an ADR
3. record residual risks separately from the original defect
4. state explicitly whether the fix is only local or actually pushed/deployed
