# SOP: Forensic Engineering for Agents

**Rule:** Do not make configuration changes based on symptoms or "likely causes." Establish Ground Truth first. Every phase below must be logged in `RESEARCH_LEDGER.md` before moving to the next.

---

## Phase 0: Snapshot State Before Touching Anything

Before any probe or change, capture where you are. This creates a rollback anchor.

```bash
# NixOS: record the current generation
ssh <host> "nixos-rebuild list-generations | tail -5"

# Record running service state
ssh <host> "systemctl status <service>"

# Record active network configuration
ssh <host> "ip addr; ip route; ss -tulpn"
```

Commit these outputs as the first `RESEARCH_LEDGER.md` entry before proceeding.

---

## Phase 0.5: Risk Classification and Change Authorization

Before running anything invasive, classify the next step:

| Class | Examples | Approval Bar |
|---|---|---|
| **Observe-only** | `tcpdump`, `strace`, `ss`, `journalctl`, `nix eval` | Ops can run immediately |
| **Local-only mutation** | editing a worktree, local `nix build`, local test harness | Ops or IC |
| **Live low-risk mutation** | restart of non-critical service, transient debug process, read-only failover probe | IC approval + rollback anchor logged |
| **Live high-risk mutation** | deploy, rollback, firewall change, routing change, storage/db mutation | IC approval + explicit mutation owner + success/failure criteria logged |

If the risk class is disputed, default upward.

---

## Phase 1: Isolation — Identify the Exact Failure Boundary

### 1a. Pinpoint the Config State

Do not trust source code alone. Verify the **rendered** configuration on the live host.

```bash
# Check what config file the running process actually loaded
ssh <host> "cat /etc/<service>/config.conf"

# For NixOS: evaluate what Nix rendered (may differ from what you think)
nix eval .#nixosConfigurations.<host>.config.services.<x>.settingName

# Check the systemd unit override in effect
ssh <host> "systemctl cat <service>"
```

### 1b. Bisect the Failure (if regression)

Identify the last known-good commit and the first known-bad commit.

```bash
# List NixOS generations with dates
ssh <host> "nixos-rebuild list-generations"

# Roll back one generation to verify the symptom disappears
ssh <host> "sudo nixos-rebuild switch --rollback"
```

If rolling back eliminates the symptom, the cause is in the diff between those two generations — not elsewhere.

### 1c. Establish the Runtime/Source Boundary

If the environment is declarative (for example NixOS), separate:

1. what the source currently says
2. what the evaluated config says
3. what the live host is actually running

Do not collapse these into one state in discussion.

---

## Phase 2: Observation — Establish Ground Truth

Use the minimum set of tools required to answer the question: **where exactly does the data stop?**

### Tool 1: Packet arrival — `tcpdump`

```bash
# Is the packet even reaching the interface?
tcpdump -ni <interface> <filter>

# Examples
tcpdump -ni eth0 port 67          # DHCP
tcpdump -ni any icmp              # ping
tcpdump -ni eth0 host 10.0.0.1    # specific host
```

**Interpretation:** If the packet does not appear here, the problem is upstream (routing, firewall, sender). Do not debug the application.

### Tool 2: Syscall visibility — `strace`

```bash
# Is the application calling the right syscalls?
strace -p <PID> -e trace=network -s 256

# For file/socket open issues
strace -p <PID> -e trace=open,openat,bind,connect,recvmsg,sendto -s 256

# From process start (catches setup errors)
strace -e trace=network -s 256 <command>
```

**Interpretation:**
- `tcpdump` sees the packet but `strace` shows no `recvmsg` → application is deaf (wrong socket, BPF filter, wrong FD)
- `strace` shows `bind("0.0.0.0")` but you expected a specific interface → socket is misconfigured

### Tool 3: Socket state — `ss`

```bash
# What is the socket actually bound to?
ss -uapn   # UDP
ss -tapn   # TCP

# Filter to a specific port
ss -uapn 'sport = :67'
```

**Interpretation:** Look for `127.0.0.1` vs `0.0.0.0` vs a specific IP. A service bound to loopback cannot receive external traffic regardless of firewall rules.

### Tool 4: System logs — `journalctl`

```bash
# Logs for a specific unit, last boot
journalctl -u <service> -b

# Follow live
journalctl -u <service> -f

# Kernel messages (hardware, driver, OOM)
journalctl -k -b

# Since a specific time
journalctl -u <service> --since "10 minutes ago"
```

### Tool 5: Kernel packet disposition — `nftables` / `conntrack`

```bash
# Is the kernel dropping the packet after tcpdump sees it?
nft list ruleset | grep -A5 drop

# Connection tracking state
conntrack -L | grep <address>

# Reverse-path filter (drops packets with unexpected source IPs)
sysctl net.ipv4.conf.<interface>.rp_filter
```

---

## Phase 3: The Mask Check

Before concluding a symptom is fixed, verify it is not masked by a higher-layer mechanism:

| Mask | How to Check |
|---|---|
| Service in standby/ready mode | Check application logs for "STANDBY", "PASSIVE", or equivalent state messages |
| `nftables`/`iptables` drop after raw capture | `nft list ruleset`; check DROP rules with `nft monitor` |
| Reverse-path filter | `sysctl net.ipv4.conf.all.rp_filter` — value `1` or `2` can silently drop asymmetric packets |
| SELinux/AppArmor denial | `ausearch -m avc -ts recent` or `journalctl -k | grep apparmor` |
| Systemd socket activation race | `systemctl status <service>.socket` — is the socket unit active before the service? |

A "fix" that passes Phase 2 but fails the Mask Check is not a fix.

---

## Phase 4: Fix Verification

After applying a change, re-run the **exact same probes from Phase 2**. Do not assume.

1. Confirm the config change is live: `systemctl cat <service>` / `cat /etc/<service>/config`
2. Confirm the socket state changed: `ss -uapn`
3. Confirm the packet is received: `strace -p <new-PID> -e trace=network`
4. Confirm end-to-end behavior: run the original failing operation

Log all four results in `RESEARCH_LEDGER.md`. If all four pass, the IC may mark the issue Resolved. If any fail, return to Phase 1.

---

## Phase 5: Closeout and Persistence

Once the fix is verified:

1. Update `SUMMARY.md` so the verified state is explicit.
2. Record any durable design choice as an ADR.
3. Record residual risks or physical/environmental blockers separately from the original software defect.
4. If source changes are still local/uncommitted, state that explicitly; "validated locally" is not the same as "persisted."

An incident is not truly closed if the understanding lives only in chat or in an unpushed worktree.

---

**Verification is the only path to finality.**
