# Linux Challenges Simulator — Full Answer Key

> Use this only AFTER you've genuinely attempted each challenge yourself.
> Read `PROBLEM.md`, write out your commands/configs, and where possible
> actually run them (many of these are runnable directly in any Linux
> shell; a few assume a real KodeKloud VM with root/sudo, systemd, LVM
> tools, a package manager, or a firewall tool - each PROBLEM.md tells you
> which). Compare against this file only afterward.

> **How to read just one challenge:**
> `sed -n '/^## 5\. /,/^## 6\. /p' linux_challenge_answer.md | less`
>
> Every solution shows the **RHEL-family** commands first. Where Ubuntu /
> Debian differ, an **Ubuntu / Debian** block follows. Paths below assume you
> built the workspace with `./linux_challenge.sh <N>` (`~/linux-challenges/challengeN/`).
>
> **Tested on Ubuntu 24.04:** the corrected Ubuntu / Debian steps (the
> `groupadd` lines in Challenges 1 and 2, `tar --zstd` in 18, and the SSH
> drop-in, `backup.sh` and disk / inode monitor in 20). The Challenge 20 unit
> with `ExecReload` and file logging was only checked with
> `systemd-analyze verify`, not on a live systemd. `apt`, `ufw`, `zypper`,
> `firewalld` and LVM commands need a real VM - try them on your own.

**Table of Contents**
1. File Permissions & Ownership
2. User & Group Management
3. Process Management
4. systemd Service Management
5. Disk & Filesystem Management
6. LVM
7. Networking Fundamentals
8. Firewall Management
9. Package Management
10. Shell Scripting Fundamentals
11. Text Processing
12. Cron & Scheduled Tasks
13. Log Management
14. SSH Configuration & Hardening
15. find & xargs
16. Symbolic & Hard Links
17. Environment Variables & Shell Profiles
18. Archiving & Compression
19. Performance Troubleshooting
20. Capstone - Provision & Harden a Production Linux Server

---

## 1. File Permissions & Ownership - chmod, chown & Special Bits

### Step 1 — The 3 special bits, plain-language
- **setuid** (on an executable): when run, the process executes with the
  PERMISSIONS OF THE FILE'S OWNER, not the user who launched it — e.g.
  `/usr/bin/passwd` is setuid-root so any user can update their own
  password entry in a root-owned file.
- **setgid** (on a directory): any NEW file/subdirectory created inside
  inherits the DIRECTORY's group ownership automatically, instead of the
  creating user's own primary group.
- **sticky bit** (on a directory): even if a file is group/world-writable,
  ONLY the file's OWNER (or root) can delete/rename it — everyone else
  can still write NEW files into the directory, but can't touch each
  other's existing files.

### Step 2 — Fixing the shared_reports/ directory
Starting point, as the script builds it:
```bash
cd ~/linux-challenges/challenge1
ls -ld shared_reports scripts/backup.sh          # BEFORE
```
```
-rwxrwxr-x 1 student student   71 ... scripts/backup.sh
drwxrwxr-x 2 student student 4096 ... shared_reports
```
```bash
sudo groupadd finance                 # skip if the group already exists
sudo chown :finance shared_reports
sudo chmod 2775 shared_reports
```
`2775` = leading `2` (setgid) + `775` (rwxrwxr-x). Setgid alone solves
"every new file automatically belongs to the finance group" (so
teammates CAN read/write each other's files via shared group
permission) — but setgid does NOT stop one teammate from DELETING or
overwriting another's file outright. The STICKY bit is what additionally
restricts deletion/renaming to the file's own owner (or root) — you need
BOTH: setgid solves the "shared group ownership" half, sticky solves the
"don't let anyone delete anyone else's files" half. Combined:
```bash
sudo chmod 3775 shared_reports   # 3 = setgid(2) + sticky(1)
ls -ld shared_reports            # drwxrwsr-t
```
`ls -ld shared_reports` now shows `drwxrwsr-t` (lowercase `s`/`t` mean
the bit is set AND the underlying execute bit is also set; uppercase
`S`/`T` would mean the bit is set but execute is NOT — worth knowing as
a diagnostic detail).

The ticket's closure check shows the **stricter** form - no access at all
for "others":
```bash
sudo chmod 3770 shared_reports
ls -ld shared_reports            # drwxrws--T  (uppercase T: sticky set, others have no x)
```

### Step 3 — Fixing backup.sh
```bash
sudo groupadd backup-operators                 # skip if it already exists
sudo chown root:backup-operators scripts/backup.sh
sudo chmod 750 scripts/backup.sh
ls -l scripts/backup.sh          # -rwxr-x--- 1 root backup-operators 71 ... scripts/backup.sh
```
`750` = owner rwx, group r-x (can READ and EXECUTE, not modify), others
nothing at all — exactly matching "runnable by backup-operators group
members, not world-writable, only owner can edit." `755` would be WRONG
here specifically because it grants OTHERS (everyone on the system,
not just backup-operators) read+execute access too — `750` correctly
scopes execute access to ONLY the intended group.

> **Ubuntu / Debian:** `chmod`, `chown`, `groupadd` and `find -perm` are
> identical (Debian also has `addgroup`). Check results in one line with
> `stat -c '%A %a %U:%G %n' shared_reports`. The admin group is `sudo`
> (RHEL: `wheel`) - never add the finance or backup users to it for this
> ticket.

**Deliverable:** save the commands above into `SOLUTION_COMMANDS.txt` in the
challenge folder.

### Step 4 — Why setuid on a binary is dangerous
A setuid binary runs with the FILE OWNER'S privileges regardless of who
invokes it — if that owner is root and the binary has ANY exploitable
bug (a buffer overflow, an unsafe subprocess call, a path injection),
literally ANY user on the system can potentially leverage it to execute
arbitrary code AS ROOT. This is exactly why `find / -perm -4000` (find
all setuid files) is one of the very first commands a security audit
runs — every setuid-root binary is a potential full-system compromise
if it has any flaw at all, and accidentally setting `u+s` on something
like `/bin/bash` would mean ANY user who can execute that shell
instantly gets a root shell.

---

## 2. User & Group Management - useradd, sudoers & Least Privilege

### Step 1 — Creating Emma's account
```bash
head -5 ~/linux-challenges/challenge2/ONBOARDING_REQUEST.md
```
```
New hire onboarding ticket
==========================
Username:        emma.h
Full name:       Emma Hartley
Role:            Junior DevOps Engineer
```
```bash
sudo groupadd developers          # only if it does not exist yet
sudo useradd -m -d /home/emma.h -s /bin/bash -G developers -c "Emma Hartley" emma.h
id emma.h
```
`-g` sets the PRIMARY group (a user has exactly one); `-G` sets
SECONDARY group memberships (a user can belong to many). Since Emma
needs to be added to the ALREADY-EXISTING "developers" group as an
additional membership (not replacing her primary group), `-G developers`
is correct here — using `-g` would instead try to make "developers" her
primary group, which isn't what was asked.

### Step 2 — Force a password change on first login
```bash
sudo passwd emma.h          # set the initial temporary password
sudo chage -d 0 emma.h       # force password change on next login
sudo chage -l emma.h | head -1   # Last password change : password must be changed
```
`chage -d 0` sets the password's "last changed" date to epoch (day 0),
which the login system interprets as "this password is already
expired" — forcing a mandatory change prompt the very next time Emma
logs in, before she can do anything else.

### Step 3 — Least-privilege sudoers entry
```bash
sudo visudo -f /etc/sudoers.d/emma-billing-app
```
```
emma.h ALL=(root) NOPASSWD: /usr/bin/systemctl restart billing-app, /usr/bin/journalctl -u billing-app
```
```bash
sudo chmod 0440 /etc/sudoers.d/emma-billing-app
sudo visudo -cf /etc/sudoers.d/emma-billing-app     # parsed OK
sudo -l -U emma.h                                   # verify EXACTLY what she can do
```
Placed in `/etc/sudoers.d/` (never editing `/etc/sudoers` directly)
because sudoers.d entries are isolated, individually reviewable files —
a syntax error in one doesn't risk corrupting the entire system's sudo
configuration the way a mistake in the monolithic `/etc/sudoers` file
could. Full paths (`/usr/bin/systemctl`, not just `systemctl`) are
required because sudoers rules match on the EXACT executable path —
without it, a malicious or accidental `PATH` manipulation could
potentially point "systemctl" at a different binary entirely; full
paths remove that ambiguity.

### Step 4 — Why "just give full sudo" is a bad default
A compromised account (phished password, leaked SSH key, or an
accidental `rm -rf` typo) under a SCOPED sudoers entry can only ever do
the 2 specific things it was granted — restart one service and read
its logs. The SAME compromised account under FULL, unrestricted root
sudo could do literally ANYTHING on the box: read every file, modify
any other service, exfiltrate data, or destroy the system entirely.
Least privilege doesn't assume malice from Emma herself — it assumes
that ACCOUNTS get compromised or make mistakes regardless of the
person's intentions, and scopes the resulting BLAST RADIUS accordingly.

> **Ubuntu / Debian:** `useradd`, `usermod -aG`, `chage` and `visudo` behave
> the same. Debian's interactive `adduser` can reject a dotted name like
> `emma.h`, so the portable `useradd` above is the safer choice. The
> full-sudo group is `sudo` on Ubuntu / Debian and `wheel` on RHEL - Emma
> gets NEITHER, only her two-command file in `/etc/sudoers.d/`.

**Deliverables:** `useradd_command.txt` and `sudoers_emma` in the challenge
folder.

---

## 3. Process Management - ps, kill, Signals, nice & Job Control

### Step 1 — STAT column meanings
- **R** (PID 4471) — Running or runnable (actively on CPU or waiting for
  a CPU timeslice).
- **S** (PID 4472) — Interruptible sleep (waiting on an event, e.g. a
  network read; can be woken by a signal).
- **Z** (PID 4901) — Zombie (see Step 2).
- **D** (PID 5002) — Uninterruptible sleep, almost always waiting on
  disk I/O. Killing a `D`-state process is DANGEROUS because the
  process is inside a kernel-level operation that CANNOT be interrupted
  by a signal at all — `kill -9` won't even affect it until the
  underlying I/O completes or times out (look at WHY first: `iostat -x 1 3`,
  `sudo dmesg -T | tail`; `iostat` needs the `sysstat` package); forcefully intervening at the
  wrong layer (e.g. yanking the underlying storage) risks filesystem
  corruption rather than actually resolving anything.

### Step 2 — Zombie processes
A zombie is NOT actually running at all — it's a process that has
already TERMINATED and released its resources, but whose EXIT STATUS
hasn't yet been collected by its PARENT process via `wait()`. The
kernel keeps a minimal process-table entry around specifically so the
parent CAN retrieve that exit code later — that's literally all a
zombie is: a leftover exit-status placeholder. `kill -9` targets a
process's execution, but there's no execution left to kill — the fix is
for the PARENT to call `wait()` (well-behaved parents do this
automatically); if the parent itself is broken/hung and never reaps its
children, the fix is usually restarting the PARENT process, which
causes the kernel to re-parent (and then clean up) the zombie
automatically.

```bash
ps -o ppid= -p 4901        # -> 4472  (the PARENT of the zombie)
sudo kill -15 4472         # ask the parent to exit; the zombie is then reaped
```

### Step 3 — SIGTERM vs. SIGKILL
Always try `SIGTERM` (`kill 4471`) FIRST — it's a request the
application can catch and respond to, typically by finishing in-flight
work, closing file handles/database connections cleanly, and exiting
gracefully. `SIGKILL` (`kill -9`) cannot be caught, ignored, or handled
at all — the kernel terminates the process immediately, with NO chance
for cleanup, potentially leaving corrupted files, orphaned locks, or
incomplete transactions behind. Reach for SIGKILL only when SIGTERM has
been given a reasonable window and the process still hasn't exited.
```bash
sudo kill -15 4471
sleep 10; ps -p 4471 >/dev/null && sudo kill -9 4471   # SIGKILL only if it is STILL alive
```

### Step 4 — Lowering priority with renice
```bash
sudo renice -n 10 -p 4471     # 4471 (process ID) old priority 0, new priority 10
```
Niceness ranges from **-20** (highest priority) to **+19** (lowest
priority) — counterintuitively, a HIGHER numeric niceness value means
LOWER scheduling priority ("nicer" to other processes, yielding CPU
time more readily). `renice -n 10` moves PID 4471 toward the lower-
priority end of that range.

### Step 5 — Ctrl+Z, bg, fg, jobs, and SIGHUP
```
Ctrl+Z        # suspends the foreground process, returns control to the shell
bg %1         # resumes it in the BACKGROUND
jobs -l       # confirm it is running
disown -h %1  # detaches it from this shell session so it survives logout
```
Without `disown` (or having started it with `nohup ... &` from the
start), closing the SSH session sends `SIGHUP` ("hangup") to every
process still attached to that session — most programs' default
response to SIGHUP is to terminate. `nohup` explicitly tells the
process to IGNORE SIGHUP from the start; `disown` removes an
already-backgrounded job from the shell's job table so the shell no
longer considers it something to signal on exit.

> **Ubuntu / Debian:** the process tools come from `procps` on every distro; only
> `iostat` needs an extra package (`sudo apt install sysstat`).

**Deliverable:** `ANSWER.md` in the challenge folder (written explanation +
commands).

---

## 4. systemd Service Management - Writing a Custom Unit File

### Step 1 — The complete unit file
```ini
[Unit]
Description=Billing Worker Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/app/worker.py
Restart=on-failure
RestartSec=5
User=billing
Group=billing

[Install]
WantedBy=multi-user.target
```

### Step 2 — Why After=network.target
Even if this specific worker doesn't obviously need network access, it
often either does (indirectly, via DNS, a database connection, an
internal API call) or might in the future — `After=network.target` is
a cheap, low-risk default ensuring the service doesn't start racing
against network initialization; omitting it usually causes no visible
problem until the one day it does, intermittently, on a slow boot.

### Step 3 — ExecStart full path, Restart, RestartSec, and non-root User
Using the FULL path to `python3` avoids relying on `PATH` resolution —
systemd units run in a minimal, controlled environment that may not
have the same `PATH` as an interactive shell, so a bare `python3` could
fail to resolve at all or resolve to an unexpected binary.
`Restart=on-failure` restarts the service on a CRASH or non-zero exit
code, but NOT on a clean `exit 0`, and NOT if it was intentionally
stopped via `systemctl stop` (which sends a deliberate stop request,
not treated as failure). `RestartSec=5` adds a short delay before
restarting — without it, a persistently-crashing app could enter a
tight, CPU-thrashing restart loop; a brief delay gives transient issues
(e.g. a dependency briefly unavailable) a chance to resolve. Running as
a dedicated non-root `User=billing` limits the blast radius if the app
is ever compromised or has a bug — it should never have MORE privilege
than its actual job requires, and "was just easier to run as root"
is never an acceptable justification on a production system.

### Step 4 — enable vs. start, and daemon-reload
`systemctl start` runs the service RIGHT NOW, for this boot session
only. `systemctl enable` creates the symlink (per `WantedBy=
multi-user.target`) so the service is ALSO started automatically on
every future boot — they're independent; `enable --now` does both at
once. `systemctl daemon-reload` is required whenever you create or
MODIFY a unit file — systemd caches parsed unit files in memory and
won't notice a change on disk until you explicitly tell it to
re-read them; skipping this step means your edits are silently ignored
by any subsequent `systemctl start/restart`.

```bash
sudo useradd -r -s /sbin/nologin billing            # dedicated non-root service account
sudo mkdir -p /opt/app && sudo cp ~/linux-challenges/challenge4/worker.py /opt/app/
sudo chown -R billing:billing /opt/app
systemd-analyze verify billing-worker.service       # no output = OK
sudo cp billing-worker.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now billing-worker
systemctl status billing-worker --no-pager | head -3
# prove Restart=on-failure works:
sudo kill -9 $(systemctl show -p MainPID --value billing-worker)
sleep 6; systemctl is-active billing-worker         # active
```

> **Ubuntu / Debian:** the unit file and every `systemctl` command are
> identical. Two differences: the no-login shell is `/usr/sbin/nologin`
> (RHEL: `/sbin/nologin`), and you can confirm the interpreter path for
> `ExecStart=` with `command -v python3`.

---

## 5. Disk & Filesystem Management - df, du, mount & /etc/fstab

### Step 1 — Diagnose: space or inodes?
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G   19G  600M  97% /

Filesystem       Inodes  IUsed   IFree IUse% Mounted on
/dev/sda1       1310720 1310000     720   99% /
```
`/` shows 600M BYTE-space still available (97% used, not 100%) — but
`df -i` shows INODE usage at 99%, with only 720 inodes left. An inode
is the metadata structure the filesystem uses to track EVERY file/
directory (permissions, timestamps, block pointers) — a filesystem can
run out of AVAILABLE INODES (and therefore be unable to create even a
single new, empty, zero-byte file) while still having plenty of raw
byte-space free, if it has accumulated an enormous number of TINY
files. A realistic cause: a directory silently accumulating millions of
small session files, cache fragments, or per-request log snippets —
each one consumes an inode regardless of how small its content is.
Takeaway: always read `df -h` AND `df -i`. Here `/` is out of inodes (99%)
while still showing 600M free.

### Step 2 — Finding the culprit
```bash
find / -xdev -type d | while read d; do
  echo "$(find "$d" -maxdepth 1 -xdev | wc -l) $d"
done | sort -rn | head -20
```
Or more targeted, checking known high-risk directories directly:
```bash
find /var/log -xdev | wc -l
find /tmp -xdev | wc -l
find /var/spool -xdev | wc -l
```
`-xdev` prevents `find` from crossing into OTHER mounted filesystems
while counting, keeping the count scoped to the filesystem you're
actually investigating.

### Step 3 — The fstab entry for /dev/sdb1
```bash
blkid /dev/sdb1
# /dev/sdb1: UUID="3f2a9c1e-77b4-4d0e-9c58-2b6f0a1d4e90" TYPE="ext4"
```
```
UUID=3f2a9c1e-77b4-4d0e-9c58-2b6f0a1d4e90  /opt/app-logs  ext4  defaults,nofail  0 2
```
`nofail` means that if this data disk is ever missing the server still
boots, instead of dropping into emergency mode.
UUID is preferred over a raw device path because device NAMING
(`/dev/sdb1`, `/dev/sdc1`, etc.) is assigned by the KERNEL at boot time,
based on detection ORDER — adding or removing a disk can shift which
physical disk gets which `/dev/sdX` name on a SUBSEQUENT reboot, silently
mounting the WRONG disk at the wrong mount point. A UUID is generated
once, at filesystem-creation time, and never changes regardless of
detection order or how many other disks come and go.

### Step 4 — Applying and verifying
```bash
sudo mkdir -p /opt/app-logs
sudo cp /etc/fstab /etc/fstab.bak                 # always keep a way back
echo 'UUID=3f2a9c1e-77b4-4d0e-9c58-2b6f0a1d4e90  /opt/app-logs  ext4  defaults,nofail  0 2' | sudo tee -a /etc/fstab
sudo mount -a
findmnt /opt/app-logs
```
Running `mount -a` immediately validates the new fstab line for real,
right now — if there's a typo (wrong UUID, wrong filesystem type), you
find out INSTANTLY, with the system still fully up and easy to fix. If
you skip this and only find out at the NEXT REBOOT, a broken fstab
entry can cause the boot process itself to hang or drop into an
emergency/rescue shell, turning a 30-second typo fix into a much more
stressful, potentially on-site recovery situation.

> **Ubuntu / Debian:** `df`, inodes, `blkid`, `/etc/fstab` and `mount -a` are
> identical. Extras:
> ```bash
> lsblk -f                                       # UUID + filesystem of every disk
> df -h -x tmpfs -x squashfs -x devtmpfs         # hide snap / tmpfs mounts
> df -i -x tmpfs -x squashfs -x devtmpfs         # same filter for the inode check
> sudo findmnt --verify                          # checks fstab WITHOUT mounting
> sudo systemctl daemon-reload                   # systemd turns fstab lines into mount units
> ```

---

## 6. LVM - Extending a Logical Volume Without Downtime

### Step 1 — The 3-layer LVM model
Think of it like plumbing: a **Physical Volume (PV)** is a raw disk (or
partition) initialized for LVM use — the "raw pipe." A **Volume Group
(VG)** pools one or more PVs together into a single, combined storage
capacity — a "reservoir" you can draw from. A **Logical Volume (LV)** is
a flexible "slice" carved out of that VG's pooled capacity, which you
actually format with a filesystem and mount — a "tap" drawing from the
reservoir. This extra abstraction layer means you can GROW an LV
on-demand from a VG's spare capacity (or after adding a new PV to the
VG) without ever needing to repartition a raw disk directly — exactly
what makes today's scenario possible.

### Step 2 — Extending without downtime
```bash
sudo lvextend -r -l +100%FREE /dev/data_vg/app_data     # LV + filesystem in ONE step (ext4 or XFS)
```
The same thing as two explicit steps (the form this ticket asks for - ext4):
```bash
sudo lvextend -l +100%FREE /dev/data_vg/app_data
sudo resize2fs /dev/data_vg/app_data                    # ext4 only
sudo xfs_growfs /data                                   # XFS instead - takes the MOUNT POINT
```
Lead with `-r` on RHEL, because RHEL 8/9 defaults to **XFS**, where
`resize2fs` fails. Check yours with `findmnt -no FSTYPE /data` (ext4 ->
`resize2fs`, xfs -> `xfs_growfs`). `lvextend -l +100%FREE` grows the LV to consume ALL remaining free space
in the VG. This alone does NOT resize the FILESYSTEM sitting on top of
it — the LV is now bigger, but ext4 itself still thinks it's the OLD
size until `resize2fs` is run separately. `resize2fs` can safely GROW a
MOUNTED, LIVE ext4 filesystem (an "online resize") because growing only
ever adds new, previously-unused space at the end — it never has to
relocate or invalidate any EXISTING data or metadata the running
filesystem is actively using. SHRINKING is fundamentally different: it
may need to relocate data currently occupying the space being removed,
which most implementations require doing OFFLINE (unmounted) for safety
— grow and shrink are NOT symmetric operations in terms of what's safe
to do live.

### Step 3 — Verifying
```bash
df -h /data     # e.g. Size 79G -> 98G, Use% 95% -> 81%  (df computes Use% as Used/(Used+Avail) = 75/(75+18))
```
If `lvextend` succeeded but `df -h` still shows the OLD total size, the
`resize2fs` step was forgotten (or failed) — the LV is bigger, but the
filesystem hasn't been told to actually USE that new space yet.

### Step 4 — If the VG had zero free space
```bash
sudo pvcreate /dev/sdc              # initialize a brand new physical disk
sudo vgextend data_vg /dev/sdc      # add it into the existing VG's pool
sudo lvextend -r -l +100%FREE /dev/data_vg/app_data    # or lvextend + resize2fs / xfs_growfs as above
```
The general growth path always starts with getting MORE raw capacity
into the VG (via a new PV) before you can `lvextend` beyond what the VG
currently has — today's scenario skipped straight to `lvextend` only
because the VG happened to already have 20GB of spare, unallocated
capacity provisioned ahead of time.

> **Ubuntu / Debian:** LVM commands are identical (`sudo apt install lvm2`).
> The installer default is ext4 (`resize2fs <device>`); `lvextend -r` handles
> either filesystem, so it is the portable choice. Ubuntu names the volume
> `/dev/mapper/ubuntu--vg-ubuntu--lv` (double dashes) - read yours from
> `lvs` / `df`.

---

## 7. Networking Fundamentals - ip, ss, DNS & Connectivity Troubleshooting

### Step 1 — The loopback-binding bug
```
LISTEN  0  128  127.0.0.1:8080  0.0.0.0:*  users:(("python3",pid=4471,fd=6))
```
`127.0.0.1` is the LOOPBACK address — traffic to it never actually
leaves the machine's own internal network stack at all. A process
bound to `127.0.0.1:8080` is reachable ONLY from processes running on
that SAME machine (e.g. `curl localhost:8080` locally would work
fine) — any OTHER host on the network, even on the same LAN, has no
path to reach it, because the packet never even attempts to traverse
a real network interface. This is an extremely common misconfiguration:
many frameworks/servers default to binding `127.0.0.1` for local-dev
safety, and that default is easy to carry unnoticed into production.

### Step 2 — The fix
The application itself needs to be reconfigured (a config file, a
startup flag, or an environment variable depending on the framework) to
bind to `0.0.0.0:8080` (all interfaces) or explicitly `10.0.1.55:8080`
(this specific interface), then restarted — `ss`/`ip` are diagnostic
tools here, not something that can fix an application's own bind
address.

### Step 3 — Other layers that could still block it
Even after fixing the bind address, connectivity can still fail due to:
- A HOST-BASED FIREWALL (firewalld/iptables) on this server blocking
  inbound port 8080 (tie to Challenge 8).
- A NETWORK-LEVEL security group / ACL / cloud provider firewall
  sitting between the two servers, entirely independent of anything
  configured on either host itself.
"The process is listening correctly" only confirms the LOCAL half of
the picture — end-to-end reachability depends on every layer along the
path. From the OTHER server, you'd run `nc -zv 10.0.1.55 8080` (or
`telnet 10.0.1.55 8080`) to directly test TCP reachability, and
`traceroute 10.0.1.55` to see how far a packet actually gets before
being dropped.

### Step 4 — ss vs. netstat
`ss` reads connection information directly from KERNEL data structures
via netlink sockets, while the older `netstat` traditionally parses
`/proc/net/*` text files — on a server with a very large number of open
connections, `ss` is dramatically faster and more efficient, which is
why it has become the modern default, with `netstat` largely considered
legacy/deprecated on current distributions.

> **Ubuntu / Debian:** `ss`, `ip` and `traceroute` work the same; the packages
> and host-firewall tool differ:
> ```bash
> sudo apt install -y netcat-openbsd traceroute    # nc (RHEL: nmap-ncat)
> sudo ufw status verbose                          # "inactive" = no host firewall
> sudo nft list ruleset                            # what the kernel really enforces (any distro)
> ```

**Deliverable:** `ANSWER.md` in the challenge folder (written explanation +
commands).

---

## 8. Firewall Management - firewalld / iptables Least-Privilege Rules

### Step 1 — Port 443 scoped to 10.0.0.0/16
```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="10.0.0.0/16" port port="443" protocol="tcp" accept'
```
A rich rule scoped to a specific source CIDR is used instead of the
simpler `--add-port=443/tcp` because the plain `--add-port` form opens
that port to ANY source reaching this interface at all — including the
public internet if this interface were ever exposed beyond the internal
network. Scoping the source explicitly to `10.0.0.0/16` means even if
this host somehow became reachable from outside that range, the
firewall itself would still reject the connection.

### Step 2 — Port 8080 scoped to exactly one IP
```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="10.0.5.20/32" port port="8080" protocol="tcp" accept'
```
`/32` is the CIDR notation meaning "exactly this one single IP address,
no range at all" (as opposed to, say, `/24` meaning a 256-address
block) — required here because the requirement was literally ONE
specific monitoring server, nothing broader, not even the rest of the
internal network.

### Step 3 — --permanent and --reload
```bash
sudo firewall-cmd --reload
sudo firewall-cmd --list-rich-rules     # verify both rules
sudo firewall-cmd --list-ports          # must stay EMPTY - nothing opened globally
```
Without `--permanent`, a rule applies IMMEDIATELY but is LOST on the
next `firewall-cmd --reload` or service restart/reboot. WITH
`--permanent`, the rule is saved to firewalld's persistent
configuration but does NOT take effect on the currently-running
firewall until you `--reload` (which re-reads the permanent
configuration into the active runtime). The standard workflow is: add
with `--permanent`, then `--reload` once to apply it live immediately
— giving you BOTH immediate effect AND reboot survival in one short
sequence.

### Step 4 — firewalld vs. raw iptables, conceptually
Raw `iptables` evaluates packets against an ORDERED LIST of rules within
chains — rule ORDER is explicit and matters directly (a broader ALLOW
rule earlier in the chain can make a later, more specific DENY rule
never even get evaluated). `firewalld` provides a higher-level
ZONE-based abstraction (a "zone" represents a trust level for a network
interface, e.g. "public," "internal," "trusted") with rich rules layered
on top — you generally don't manage explicit rule ORDERING yourself the
same way; firewalld handles the underlying nftables/iptables rule
generation and sequencing for you, trading some low-level control for
much simpler day-to-day management.

> **Ubuntu / Debian (ufw):** allow SSH FIRST, or enabling ufw can cut your
> session. ufw rules apply immediately and persist - there is no
> `--permanent` / `--reload` pair.
> ```bash
> sudo ufw default deny incoming
> sudo ufw allow 22/tcp
> sudo ufw allow from 10.0.0.0/16 to any port 443 proto tcp
> sudo ufw allow from 10.0.5.20 to any port 8080 proto tcp     # a bare IP means exactly one host (/32)
> sudo ufw enable                                              # ufw ships INACTIVE on Ubuntu
> sudo ufw status numbered
> ```
> Raw iptables (any distro) - ORDER MATTERS, the ACCEPT rules go BEFORE the DROP:
> ```bash
> sudo iptables -A INPUT -p tcp -s 10.0.0.0/16 --dport 443 -j ACCEPT
> sudo iptables -A INPUT -p tcp -s 10.0.5.20/32 --dport 8080 -j ACCEPT
> sudo iptables -A INPUT -p tcp -m multiport --dports 443,8080 -j DROP
> ```

---

## 9. Package Management - Repos, Dependency Conflicts & Pinning

(Demonstrated here using the RHEL/CentOS `yum` family — the same
reasoning applies to Debian/Ubuntu's `apt`/`apt-mark hold`.)

### Step 1 — Checking available versions
```bash
yum list --showduplicates libfoo
```

### Step 2 — Downgrading to the known-good version
```bash
yum downgrade libfoo-1.4.2
```
If the repo no longer serves 1.4.2 by default (common once a repo
"moves on"), you may need a versioned package cache/vault repo, or the
exact RPM file retrieved from an internal artifact store, then:
```bash
yum install /path/to/libfoo-1.4.2.rpm
```

### Step 3 — Pinning the version going forward
```bash
yum install yum-plugin-versionlock
yum versionlock add libfoo-1.4.2
```
This prevents future `yum update` runs from touching `libfoo`
SPECIFICALLY, while every OTHER package on the system continues to
receive updates normally — a far narrower, safer fix than "never run
updates on this server at all," which would leave the ENTIRE system
increasingly unpatched over time just to protect one package.

### Step 4 — Resolving the version conflict with the new tool
Since you generally can't have two different versions of the same
system library installed via the normal package manager simultaneously,
the real options are: (a) run the new tool inside an isolated CONTAINER
with its own dependency set, fully decoupled from the host's
`libfoo-1.4.2` — a valid, quick workaround; or (b) determine whether the
CRASHING APP can actually be updated/patched to work correctly with
`libfoo-1.6.0`, eliminating the need to pin an old version at all.
Option (b), if genuinely feasible, is the more durable fix — it resolves
BOTH problems simultaneously and removes the ongoing maintenance burden
of a permanent version pin/exception; option (a) merely works around
the conflict without ever actually resolving the underlying
incompatibility.

> **Ubuntu / Debian (apt) and RHEL 8/9 (dnf):**
> ```bash
> apt-cache policy libfoo                              # installed / candidate / all versions
> sudo apt install libfoo=1.4.2-1 --allow-downgrades   # back to the known-good version
> sudo apt-mark hold libfoo                            # pin; undo: sudo apt-mark unhold libfoo
> apt-mark showhold
> # dnf ("yum" is just an alias on RHEL 8/9):
> sudo dnf downgrade libfoo-1.4.2-1.el9
> sudo dnf install -y 'dnf-command(versionlock)'
> sudo dnf versionlock add libfoo-1.4.2
> ```
> APT keeps very few old versions - keep the `.deb` (or a mirror) of anything
> you may need to roll back to, and keep companion packages (`libfoo-dev`...)
> at the SAME version. RHEL 8/9 ships `podman` instead of `docker`
> (`podman run --rm newtool:latest --version`).

---

## 10. Shell Scripting Fundamentals - A Real Production-Style Script

### Step 1 — The complete, fixed script
```bash
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="${1:-90}"                  # optional argument, default 90
OVER_THRESHOLD=0

check_line() {                        # one function = one job
  local usage="$1" mount="$2"
  if [ "$usage" -gt "$THRESHOLD" ]; then
    echo "WARNING: $mount is at ${usage}% - over threshold!"
    return 1
  fi
  return 0
}

# the LAST variable (mount) receives the rest of the line, so spaces survive
while read -r _fs _size _used _avail pct mount; do
  usage="${pct%\%}"
  if ! check_line "$usage" "$mount"; then
    OVER_THRESHOLD=1
  fi
done < <(df -P | tail -n +2)          # process substitution keeps the loop in THIS shell

echo "Disk check complete."
exit "$OVER_THRESHOLD"
```
Tested against a fake `df` that includes a mount point WITH spaces
(`/mnt/my nfs share`):
```
$ ./disk_check.sh              # default 90 -> both breach
WARNING: / is at 95% - over threshold!
WARNING: /mnt/my nfs share is at 92% - over threshold!
Disk check complete.           # exit=1
$ ./disk_check.sh 99           # nothing breaches -> exit=0
$ ./disk_check.sh 93           # only / (95%) breaches -> exit=1
```
The starter script's output, for comparison (note the mount cut at the
first space, and the exit code of 0 despite breaches):
```
WARNING: / is at 95%
WARNING: /mnt/my is at 92%
Disk check complete.           # exit=0
```

### Step 2 — Handling spaces in mount points
`df -P` gives POSIX-predictable, single-line-per-filesystem output.
`read -r _fs _size _used _avail pct mount` lets the LAST variable
(`mount`) absorb the remainder of the line, so a multi-word path like
"/mnt/my nfs share" survives intact. `awk '{print $6}'` or
`cut -d' ' -f6` would cut the path at its first space - and `df` pads
its columns with several spaces, which breaks `cut` even harder. Every
variable is quoted (`"$usage"`, `"$mount"`) so word-splitting never
fragments a value unexpectedly. Unquoted expansions (`$line` instead of
`"$line"`) let the shell re-split on whitespace, which is exactly the bug
that broke the original script on any mount path containing a space.

### Step 3 — set -euo pipefail, one bug each
- **`-e`** (exit on any command failing): would have caught a case
  where `awk`/`sed` themselves failed silently and the script continued
  with garbage data instead of stopping.
- **`-u`** (error on unset variables): would have caught a typo'd
  variable name (e.g. referencing `$THRESHHOLD` instead of
  `$THRESHOLD`) immediately, instead of silently treating it as an
  empty string.
- **`-o pipefail`** (a pipeline's exit code is that of the LAST (rightmost)
  command that failed, instead of just the last command's): would have
  caught `df -P | tail -n +2` silently succeeding even if `df` itself had
  failed, since `tail` returns 0 on empty input and would otherwise mask
  that. Quick proof in bash: `false | (exit 3) | true` returns `0` by
  default but `3` with `set -o pipefail`.

### Step 4 — The subshell scoping gotcha
```bash
df -h | while read line; do ... done   # BUG: while loop runs in a SUBSHELL
```
Any variable modified INSIDE this loop (like a running counter) is lost
the moment the loop ends, because the entire pipeline's right-hand side
runs in a forked subshell with its OWN copy of the shell's variables —
changes never propagate back to the parent script. The fix used above,
process substitution (`done < <(df -P | tail -n +2)`), keeps the `while`
loop running in the SAME shell as the rest of the script, so
`OVER_THRESHOLD=1` set inside the loop is correctly visible after it
ends.

### Step 5 — Why named functions matter
Breaking "check one line of df output" into `check_line()` makes the
logic independently readable, testable (you could call `check_line 95
/data` directly to sanity-check the threshold logic without running the
whole `df` pipeline), and reusable — exactly the same "why bother"
reasoning that applies to functions in any larger programming language,
just as valid in "just a shell script."

> **Ubuntu / Debian:** `/bin/sh` is **dash** (RHEL: bash), so run the script
> as `./disk_check.sh` or `bash disk_check.sh`, never `sh disk_check.sh`.
> Ubuntu also mounts every snap as a read-only squashfs at 100% used, which
> would make the script warn on every run - filter them out of `df`:
> ```bash
> done < <(df -P -x tmpfs -x squashfs -x devtmpfs | tail -n +2)    # the one changed line
> ```
> `bash ./disk_check.sh 1; echo "exit=$?"` forces a breach to prove the exit
> code still works.

---

## 11. Text Processing - grep, awk, sed & the Unix Pipeline

### Step 1 — Count 500-status requests
```bash
grep -c '" 500 ' access.log
```

### Step 2 — Unique IPs hitting /api/billing/charge with a 500, by frequency
```bash
grep '/api/billing/charge' access.log | grep '" 500 ' | awk '{print $1}' | sort | uniq -c | sort -rn
```
```
      4 10.0.2.9
```
One client, `10.0.2.9`, caused all 4 failures on `/api/billing/charge`. (A
fifth charge, from `10.0.5.1`, succeeded with 200.)

### Step 3 — Unique method+path combinations, sorted by count
```bash
awk -F'"' '{print $2}' access.log | awk '{print $1, $2}' | sort | uniq -c | sort -rn
```
```
      5 POST /api/billing/charge
      3 GET /api/health
      1 GET /api/users/42
      1 GET /api/orders
```

### Step 4 — Redact source IPs with sed
```bash
sed -E 's/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/REDACTED/' access.log
```
The `^` anchor replaces only the LEADING IP - never an IP-looking string
elsewhere in the line.
```
REDACTED - - [14/Sep/2026:08:01:12] "GET /api/health HTTP/1.1" 200 45
REDACTED - - [14/Sep/2026:08:01:15] "POST /api/billing/charge HTTP/1.1" 500 120
```

### Step 5 — Why awk over cut for question 3
The log's bracketed timestamp (`[14/Sep/2026:08:01:12]`) contains NO
spaces internally in this format, but the QUOTED request field
(`"GET /api/health HTTP/1.1"`) genuinely DOES contain spaces as
meaningful content — a strictly space-delimited tool like `cut -d' '
-f6` would only grab ONE word (e.g. just "GET"), not the full method+
path+protocol string. `awk` (especially combined with `-F'"'` to first
split on the quote characters surrounding the request field) lets you
extract a semantically meaningful CHUNK and then further process just
that chunk — `cut`'s purely positional, single-delimiter field
splitting has no equivalent way to say "grab everything between these
two quote marks, regardless of how many spaces it contains inside."

> **Ubuntu / Debian:** `grep`, `sed` and `sort | uniq -c` are identical. Ubuntu
> ships **mawk** as `awk` (RHEL: gawk) - these one-liners use only features
> both have. Real log paths differ: `/var/log/nginx/access.log` (nginx),
> `/var/log/apache2/access.log` (Apache on Ubuntu / Debian) vs
> `/var/log/httpd/access_log` (Apache on RHEL). `zcat -f` reads rotated
> `.gz` logs together with the current one:
> ```bash
> sudo zcat -f /var/log/nginx/access.log* | grep -c '" 500 '
> ```

**Deliverable:** `commands.txt` in the challenge folder.

---

## 12. Cron & Scheduled Tasks - crontab and systemd Timers

### Step 1 — The crontab line
```
30 2 * * 1-5 /home/student/linux-challenges/challenge12/backup_db.sh
```
(Replace `student` with your username.)
Fields in order: minute(30) hour(2) day-of-month(*) month(*)
day-of-week(1-5, Monday=1 through Friday=5). `1-5` correctly expresses
"weekdays only," leaving Saturday(6)/Sunday(0) untouched.

### Step 2 — A genuine one-time task with `at`
```bash
echo "/home/student/linux-challenges/challenge12/cleanup_once.sh" | at 23:45
atq                                   # list pending at jobs
```
`at` is correct here because it's designed for exactly this: a single,
one-off execution at a specific time, with NO recurrence built in at
all. Forcing a "one time" task into cron syntax means you must remember
to manually DELETE the crontab entry afterward — if you forget, it
silently fires again at the exact same time tomorrow, and every day
after that, with no built-in mechanism to stop it.

### Step 3 — Why cron gives zero visibility into "did it even start"
Plain crontab has no concept of "confirm this job attempted to run" —
if the cron daemon itself isn't running, or the server is down at
2:30 AM, NOTHING happens: no log entry, no error, no alert, and no way
to distinguish "ran fine with no output" from "never even attempted."
A systemd TIMER + SERVICE pair gives you: `systemctl list-timers`
(showing exactly when each timer last fired and will next fire),
`OnFailure=` directives (triggering a separate notification unit if the
service exits non-zero), and full journalctl history for the service
(including explicit "service failed to start" entries) — meaningfully
better observability than cron's "nothing happened, silently" default.

### Step 4 — The timer + service unit pair
`billing-backup.service`:
```ini
[Unit]
Description=Nightly billing DB backup

[Service]
Type=oneshot
ExecStart=/home/student/linux-challenges/challenge12/backup_db.sh
```
`billing-backup.timer`:
```ini
[Unit]
Description=Run billing-backup.service weekdays at 2:30 AM

[Timer]
OnCalendar=Mon..Fri 02:30:00
Persistent=true

[Install]
WantedBy=timers.target
```
`OnCalendar=Mon..Fri 02:30:00` expresses the identical weekday/2:30AM
schedule using systemd's calendar syntax; `Persistent=true` additionally
ensures a MISSED run (e.g. server was down at exactly 2:30 AM) fires as
soon as possible once the system is back up — a resilience feature
plain cron has no equivalent for at all.
```bash
sudo cp billing-backup.service billing-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now billing-backup.timer
systemd-analyze calendar 'Mon..Fri 02:30:00'    # validate the schedule expression
systemctl list-timers billing-backup.timer      # last run / next run
journalctl -u billing-backup.service            # full history incl. "failed to start"
```

> **Ubuntu / Debian:** crontab syntax and systemd timers are identical. The
> cron service is `cron` on Ubuntu / Debian / SUSE and `crond` on RHEL
> (`journalctl -u cron --since today`). `at` is usually NOT installed by
> default - install it and start `atd`:
> ```bash
> sudo apt install -y at && sudo systemctl enable --now atd      # RHEL: dnf install -y at
> ```

---

## 13. Log Management - journalctl, /var/log & logrotate

### Step 1 — logrotate config
```
# /etc/logrotate.d/billing-app
/var/log/billing-app/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        systemctl reload billing-app > /dev/null 2>&1 || true
    endscript
}
```
`delaycompress` leaves the MOST recently rotated file uncompressed for
one additional cycle — useful because a process might still hold a
brief open file handle to the just-rotated file right after rotation
(due to timing between rotation and the process actually reopening a
new file), and compressing it immediately could interfere with that
narrow window. `postrotate` sending a reload signal is preferred for an
app that supports a clean "reopen your log file" signal — it tells the
running process to close its OLD file handle and open a NEW one
targeting the freshly-rotated-into-place file, with zero data loss.
`copytruncate` (copy the log then truncate the original in place,
without ever needing to signal the app) is the right FALLBACK for apps
that don't support any such reload signal — but it carries a real risk:
between the COPY and the TRUNCATE, the app could write MORE data that
gets lost in that gap, a small window of potential log loss the
signal-based approach avoids entirely.

**Important:** `systemctl reload` only does something if the app's unit
defines `ExecReload=` (for example `ExecReload=/bin/kill -HUP $MAINPID`)
AND the app reopens its log file when it receives SIGHUP. If it does not,
use `copytruncate` instead of `postrotate`:
```
/var/log/billing-app/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```
```bash
sudo logrotate -d /etc/logrotate.d/billing-app    # dry-run: shows what WOULD happen
sudo logrotate -f /etc/logrotate.d/billing-app    # force one rotation to prove it works
```

### Step 2 — journalctl commands
```bash
journalctl -u billing-app                                    # (a)
journalctl -u billing-app --since "22:00" --until "22:30"     # (b)
journalctl -u billing-app -f                                  # (c)
journalctl -u billing-app -p err                              # (d)
```
Priority levels run 0 (emerg) through 7 (debug); `-p err` (or `-p 3`)
shows entries at ERROR severity or higher (more severe/lower-numbered).

### Step 3 — Why output goes to the journal, and the trade-off
By default, systemd captures a managed service's STDOUT/STDERR
automatically and routes it into the systemd JOURNAL — no explicit
logging configuration is needed for this to happen; it's the default
behavior for any unit that doesn't redirect its own output elsewhere.
The journal is structured, indexed, and easily filtered/queried (by
unit, time range, priority) — but an engineer who has only ever learned
to `grep` plain text files, and never learned `journalctl`, will
struggle to find this output at all, since it simply isn't sitting in a
`/var/log/*.log` file the way they're used to looking for it.

> **Ubuntu / Debian:** `journalctl` and `logrotate` work identically. The
> plain-text logs live in different files:
> ```bash
> sudo tail -f /var/log/syslog      # Ubuntu / Debian general log (if rsyslog is installed; Debian 12+ often has only the journal, so use journalctl)
> sudo tail -f /var/log/auth.log    # Ubuntu / Debian SSH / sudo / login events (same rsyslog caveat)
> sudo tail -f /var/log/messages    # RHEL-family general log   (/var/log/secure for auth)
> journalctl -u ssh --since "22:00" # Ubuntu / Debian service is "ssh" (RHEL / SUSE: sshd)
> ```

**Deliverables:** `billing-app.logrotate` and `journalctl_commands.txt` in the
challenge folder.

---

## 14. SSH Configuration & Hardening - Key-Based Auth Done Right

### Step 1 — Generating a key pair
```bash
ssh-keygen -t ed25519 -C "emma.h@company.com"
```
`ed25519` is preferred over `rsa` for new keys today because it offers
equivalent (or stronger) real-world security with a MUCH shorter key
size, faster key generation, and faster sign/verify operations — RSA
remains supported for compatibility with older systems but is no longer
the default recommendation for new keys.

### Step 2 — Installing the public key
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub emma.h@server
```
Manually, this means appending the public key to
`~/.ssh/authorized_keys` on the server, and ensuring:
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
# SAFETY: prove key login works in a SECOND terminal, keep the first one open:
ssh -i ~/.ssh/id_ed25519 -o PasswordAuthentication=no emma.h@server
```
SSH itself REFUSES to use an `authorized_keys` file (or its containing
`.ssh` directory) if permissions are too permissive (group- or
world-writable) — this is a deliberate SSH security check, since an
overly-permissive `authorized_keys` file could otherwise let ANOTHER
user on the system append their OWN key and gain access to this
account.

### Step 3 — The hardened sshd_config
```
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
```
Put them in `/etc/ssh/sshd_config` (or, better, in a drop-in - see Step 4).
All the hardened settings must be present: `PermitRootLogin`,
`PasswordAuthentication`, `X11Forwarding`, `MaxAuthTries`,
`ClientAliveInterval` and `ClientAliveCountMax`.
- `PermitRootLogin no` — root should never log in directly over SSH;
  use a named account + `sudo` instead, preserving a clear audit trail
  of WHO performed WHAT privileged action, rather than an anonymous
  "root did it" log entry.
- `PasswordAuthentication no` — disabling password auth entirely is
  categorically stronger than any password policy (length/complexity/
  rotation rules), since it eliminates the entire class of
  password-guessing/credential-stuffing attacks. CRITICAL: test
  key-based login SUCCESSFULLY in a SEPARATE terminal session FIRST,
  without closing your current session — if key auth is misconfigured
  and you disable password auth before confirming it works, you can
  permanently lock EVERYONE (including yourself) out, with no
  password-based fallback left.
- `X11Forwarding no` — rarely needed on a production server; leaving it
  enabled is unnecessary attack surface with no real day-to-day benefit
  for most workloads.
- `MaxAuthTries 3` — reduces the practical window for online brute-
  force/credential-stuffing attempts per connection.
- `ClientAliveInterval 300` + `ClientAliveCountMax 2` — together, these
  detect and drop dead/unresponsive SSH sessions (probing every 300
  seconds, dropping after 2 missed responses) — good for both security
  hygiene (stale sessions aren't left hanging indefinitely) and
  resource cleanup on the server.

### Step 4 — Validating before restart
```bash
sudo sshd -t                     # syntax check - no output means the config is valid
echo $?                          # 0
sudo systemctl reload sshd       # Ubuntu / Debian: ssh
sudo sshd -T | grep -i -E 'permitrootlogin|passwordauthentication'   # the EFFECTIVE values
```
`sshd -t` checks the new config's SYNTAX without touching the running
service at all. Restarting `sshd` with a broken config could leave SSH
completely unable to accept new connections — and since you'd be
restarting the very service your CURRENT session depends on, a broken
config might not even let you recover over that SAME session if it
drops; validating first prevents ever finding out the hard way.

**Drop-ins can override your edit.** RHEL 9 and cloud images read
`/etc/ssh/sshd_config.d/*.conf`, and sshd keeps the FIRST value it sees for
a setting - so a file such as `50-cloud-init.conf` that re-enables
passwords can silently win. `sshd -T` shows what is really in effect. To
win on purpose, use a drop-in that sorts first:
```bash
sudo tee /etc/ssh/sshd_config.d/00-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
sudo sshd -t && sudo systemctl reload sshd
```

> **Ubuntu / Debian:** `ssh-keygen`, `authorized_keys` permissions and every
> `sshd_config` option are identical; the service is `ssh` (RHEL / SUSE:
> `sshd`). Ubuntu 22.10+ starts sshd through a systemd socket (`ssh.socket`):
> normal setting changes only need `reload ssh`, but changing the PORT or
> ListenAddress needs `systemctl daemon-reload && systemctl restart ssh.socket`
> - and open the new port first with `sudo ufw allow <port>/tcp`.

**Deliverable:** `hardened_sshd_config.md` in the challenge folder.

---

## 15. find & xargs - Safe, Efficient Batch File Operations

### Step 1 — Deleting old .tmp files
```bash
find app_data/tmp_uploads -name '*.tmp' -mtime +7 -print     # DRY RUN first - read the list
find app_data/tmp_uploads -name '*.tmp' -mtime +7 -delete
ls -1 app_data/tmp_uploads                                   # only upload_4.tmp, upload_5.tmp survive
```
`-delete` is preferable to piping into `xargs rm` when it's sufficient
for your needs — it's simpler, spawns no subprocess per file, and has
no quoting/escaping concerns at all. You'd need `xargs` INSTEAD when you
need to run something MORE COMPLEX per file than `find`'s own
`-exec`/`-delete` actions can express — e.g. piping matched files into a
custom script that does several unrelated things per file, or batching
many filenames into a SINGLE invocation of an external command for
efficiency (something `-exec ... \;` running once per file cannot do,
though `-exec ... +` can batch similarly to xargs in simpler cases).

### Step 2 — Fixing world-writable files safely
```bash
find app_data -type f -perm -o+w -print0 | xargs -0 chmod o-w
```
`-print0` (from `find`) and `-0` (from `xargs`) use the NULL byte as the
delimiter between filenames instead of whitespace/newlines — this is
essential because filenames CAN legitimately contain spaces, or even
(rarely but validly) newlines, which would otherwise cause a naive
`find | xargs` pipeline to MISINTERPRET one filename as multiple
separate arguments. Concrete example: a file literally named
`my file.conf` would, without `-print0`/`-0`, be split into two separate
"filenames" (`my` and `file.conf`) by a plain, non-null-delimited pipe —
`chmod o-w my file.conf` would then try to chmod a probably-nonexistent
file called `my` and a DIFFERENT file called `file.conf`, silently doing
the wrong thing.

### Step 3 — The real danger of careless find | xargs rm
A typo'd path — e.g. an unset shell variable inside a path expression,
resolving to an empty string, turning `find "$BASE_DIR/tmp" ...` into
`find "/tmp" ...` (or worse, `find "" ...` resolving unexpectedly) — can
silently scope a destructive command far more broadly than intended,
potentially reaching `/` or `$HOME` entirely by accident. A personal
safety habit: ALWAYS run the equivalent `find ... -print` FIRST, and
manually review the exact file list BEFORE ever piping it into a
destructive `xargs` command, or use `xargs -p` for an interactive,
per-command confirmation prompt while testing a new bulk operation for
the first time against real production data.

> **Ubuntu / Debian:** `find`, `xargs` and `touch -d` are the GNU versions, so
> every command is identical. One habit worth adding on any distro: `-r`
> (`--no-run-if-empty`) skips the command when there is no input:
> ```bash
> find app_data -type f -perm -o+w -print0 | xargs -0 -r chmod o-w
> ```
> For age-based cleanup with NO script at all, `systemd-tmpfiles` ships on
> Ubuntu / Debian and RHEL:
> ```bash
> sudo tee /etc/tmpfiles.d/app-uploads.conf <<'EOF'
> d /srv/app/tmp_uploads 0750 app app 7d
> EOF
> sudo systemd-tmpfiles --clean      # deletes entries older than 7 days (a daily timer runs it too)
> ```
> Test it with files that are genuinely old; `touch -d` back-dating may not
> work because ctime is also checked.

---

## 16. Symbolic & Hard Links - Inodes and What Can Go Wrong

### Step 1 — Hard link vs. symbolic link
A HARD link points DIRECTLY at the same INODE as the original file — an
inode is the filesystem's internal record of a file's actual data
blocks and metadata; a hard link is just another directory entry
referencing that SAME inode number. Because inodes are only meaningful
WITHIN a single filesystem, a hard link CANNOT cross filesystem/
partition boundaries — there's no inode number that means anything on
a DIFFERENT filesystem. A SYMBOLIC link, by contrast, stores a PATH
STRING, resolved fresh every time it's accessed — since it's just text
naming a path, it can point anywhere, including across filesystems
entirely.

### Step 2 — Why the hard-link attempt failed as a "current" pointer
A hard link to `v1.0.0/app.jar`'s inode has NO ongoing relationship to
"whatever the newest release happens to be" — it's permanently locked
to that ONE specific inode. If you OVERWRITE the CONTENTS of that exact
inode (editing the same file in place), `current` would reflect the
change, because it's the SAME inode. But creating a brand NEW file at
the v1.1.0 path is an entirely DIFFERENT inode — hard-linking `current`
once, at v1.0.0 time, gives it no automatic way to "follow" a later,
different file at a different path/inode at all — the engineer would
have needed to re-create the hard link from scratch every single
deploy, which defeats the whole purpose of a stable "current" pointer.

### Step 3 — The correct symlink-based implementation
```bash
cd ~/linux-challenges/challenge16
ln -sfn v1.1.0 releases/current
cat releases/current/app.jar          # app version 1.1.0
```
Symlinking the DIRECTORY (not the specific .jar file) means
`releases/current/app.jar` resolves THROUGH the symlink to whichever
version directory it currently points at — more flexible than
symlinking the .jar directly, since a release might later include
MULTIPLE files that all need to move together as one version. To
"deploy" v1.0.0 instead:
```bash
ln -sfn v1.0.0 releases/current
cat releases/current/app.jar          # app version 1.0.0
```
A relative target is resolved from the LINK'S OWN folder, not from where
you typed the command. So `v1.1.0` is right; `releases/v1.1.0` would be
looked up as `releases/releases/v1.1.0` - a broken link (`cat` fails with
"No such file or directory"). Use `v1.1.0` or an absolute path.

`-f` forces overwriting the EXISTING symlink (without it, `ln -s` would
refuse, complaining the target already exists) — `-n` treats `current`
itself as the symlink to replace, rather than (if `current` already
existed as a symlink to a directory) following it and creating the new
link INSIDE that target directory instead, which is a classic, very
confusing `ln -s` gotcha without `-n`.

### Step 4 — The rollback advantage
Rolling back is a single, near-instant symlink repoint — no file
copying, no redeploy, no rebuild — just `ln -sfn v1.0.0
releases/current` and the running application (assuming it re-resolves
the `current` path per-request or on next restart) is back on the known
-good version in milliseconds. A "copy files directly into place"
deployment approach has no equivalent instant-rollback path — reverting
means re-copying the OLD version's files back over the current ones,
which takes real time and carries more risk of partial/inconsistent
state during the copy.

> **Ubuntu / Debian:** `ln`, `ls -li` and symlink behaviour are identical.
> Handy inspection commands: `readlink releases/current` (one hop) and
> `readlink -f releases/current` (fully resolved path); `stat -c '%i %h %n' <file>`
> prints inode, hard-link count and name. Debian / Ubuntu use the same idea
> for "which version is the default": `ls -l /etc/alternatives/editor`
> (`update-alternatives --display editor`; RHEL: `alternatives --display editor`).

---

## 17. Environment Variables & Shell Profiles - PATH and Login Shells

### Step 1 — Why ~/.bashrc doesn't apply to cron/CI
`~/.bashrc` is specifically read for INTERACTIVE, non-login shells (an
SSH session typically triggers login-shell startup files, which on most
distros then also source `.bashrc` indirectly for interactive use). A
CRON JOB's shell is neither interactive nor typically a login shell —
cron invokes commands directly, non-interactively, with a deliberately
minimal environment. A typical CI pipeline step is similarly
non-interactive, often running inside a fresh, isolated shell/container
invocation with no interactive startup files sourced at all. Since
`PATH` was modified ONLY inside `~/.bashrc`, neither context ever reads
that file, and the addition silently never applies there.

### Step 2 — bashrc vs. bash_profile vs. /etc/environment
`~/.bash_profile`/`~/.profile` are read for LOGIN shells specifically
(historically, an SSH login IS a login shell, which is part of why
interactive SSH sessions often end up sourcing both, depending on
distro conventions and whether `.bash_profile` itself sources
`.bashrc`). `/etc/environment` is read by PAM for essentially ANY login,
system-wide, independent of shell type — but cron itself sources a very
MINIMAL environment of its own, and doesn't necessarily honor
`/etc/environment` consistently across every distro/cron implementation
either. The MOST reliable fix is to NOT depend on any shell startup
file being sourced at all — set `PATH` explicitly inside the crontab
file itself, or inside the script being run.

### Step 3 — Two concrete fixes
```
# a) inside the crontab file itself:
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/deploy-tool/bin
0 3 * * * deploy-tool --version
```
```bash
# b) use the full absolute path directly, sidestepping PATH entirely:
/opt/deploy-tool/bin/deploy-tool --version
```
Simulate what cron / CI sees (no rc files, minimal environment) with the
stand-in tool the script creates:
```bash
cd ~/linux-challenges/challenge17
TOOL=$PWD/opt/deploy-tool/bin
export PATH=$PATH:$TOOL && deploy-tool --version        # interactive shell: works
env -i HOME=$HOME bash -c 'deploy-tool --version'       # bash: deploy-tool: command not found  (exit 127)
env -i HOME=$HOME PATH=/usr/bin:/bin:$TOOL bash -c 'deploy-tool --version'   # fix (a): works
env -i $TOOL/deploy-tool --version                      # fix (b): works with an EMPTY environment
```

### Step 4 — Why absolute paths are good practice in automation
Hardcoding an absolute path inside automation (cron, CI, systemd units)
removes ANY dependency on which environment/shell happens to invoke it
— it will resolve correctly regardless of what `PATH` (if any) the
calling context provides. This is the EXACT same reasoning behind using
the full path to `python3` in a systemd unit's `ExecStart=` (Challenge
4) — in automation contexts, "portable" actually means "not dependent
on an assumed, possibly-missing environment," which is the OPPOSITE of
relying on `PATH` resolution the way you comfortably would in your own
interactive shell.

> **Ubuntu / Debian:** which startup file a LOGIN bash reads depends on the
> distro - RHEL: `~/.bash_profile` (which sources `~/.bashrc`); Ubuntu /
> Debian: `~/.profile` (no `~/.bash_profile` by default). Ubuntu's default
> `~/.bashrc` also has a guard near the top that quits for NON-interactive
> shells (`case $- in *i*) ;; *) return;; esac`), so anything exported
> BELOW it never runs under cron or CI. Both fixes above behave the same on
> every distro.

**Deliverable:** `explanation.md` in the challenge folder.

---

## 18. Archiving & Compression - tar, gzip & a Real Backup Strategy

### Step 1 — Creating the dated, excluding archive
```bash
cd ~/linux-challenges/challenge18
tar -czvf "app-backup-$(date +%F).tar.gz" --exclude='app_to_backup/logs' app_to_backup
ls app-backup-*.tar.gz        # the date in the name comes from $(date +%F)
```
`-c` create, `-z` gzip-compress, `-v` verbose (list files as archived),
`-f` specify the archive filename, `--exclude` skip the matching
path(s). `$(date +%F)` dynamically generates today's date in
`YYYY-MM-DD` format so consecutive daily backups never overwrite one
another.

### Step 2 — gzip vs. bzip2
`tar czf` (gzip) is FASTER but achieves a somewhat lower compression
ratio; `tar cjf` (bzip2) compresses tighter but is noticeably SLOWER.
For a large, FREQUENT backup job (e.g. nightly), speed usually wins —
gzip. For a smaller, INFREQUENT archival backup where storage cost
matters more than how long the job takes, bzip2's better ratio can be
worth the extra time.

### Step 3 — Verifying integrity without extracting
```bash
tar tzf app-backup-2026-10-11.tar.gz
```
`tar t` LISTS the archive's contents and verifies its internal
structure/checksums are readable WITHOUT writing anything to disk — it
does decompress the stream internally to read through it, but never
extracts file contents onto the filesystem, making it a safe, fast
sanity check that the archive isn't corrupted.

### Step 4 — Partial restore of just config/
```bash
tar tzf app-backup-2026-10-11.tar.gz | grep config    # discover the exact internal path first
tar xzf app-backup-2026-10-11.tar.gz -C /restore/location app_to_backup/config
```
You need the archive's EXACT internal path (relative to wherever `tar`
was originally run FROM when the archive was created) because `tar`
matches extraction targets against that stored internal path literally
— listing the archive first (`tar tzf`) is the reliable way to discover
that exact path if you're not certain of it, rather than guessing.

> **Ubuntu / Debian:** `tar`, `gzip` and `date +%F` are identical (minimal
> images may lack the other compressors: `sudo apt install -y bzip2 xz-utils zstd`).
> Extra integrity checks on top of `tar tzf` (nothing is extracted):
> ```bash
> gzip -t app-backup-2026-10-11.tar.gz && echo "gzip -t: OK"
> sha256sum app-backup-2026-10-11.tar.gz > app-backup-2026-10-11.tar.gz.sha256
> sha256sum -c app-backup-2026-10-11.tar.gz.sha256        # re-run later / on another host
> ```
> Other formats (`tar --zstd` needs GNU tar 1.31+, i.e. **Ubuntu 22.04+** and
> Debian 11+):
> ```bash
> tar -cJf  "app-backup-$(date +%F).tar.xz"  --exclude='app_to_backup/logs' app_to_backup   # xz
> tar --zstd -cf "app-backup-$(date +%F).tar.zst" --exclude='app_to_backup/logs' app_to_backup   # zstd
> tar --zstd -tf app-backup-2026-10-11.tar.zst           # list a zstd archive the same way
> ```

---

## 19. Performance Troubleshooting - Load Average, Memory & I/O

### Step 1 — Interpreting load average
Load average measures the number of processes either ACTIVELY RUNNING
on a CPU or WAITING for a resource (CPU time OR I/O completion) — NOT
simply "% CPU used." On a 4-core machine, a load average meaningfully
above 4 indicates more work is queued/waiting than the machine can
actually process concurrently right now. 8.42 is roughly DOUBLE the
core count — a clear overload signal. The TREND (6.10 -> 7.95 -> 8.42,
rising across the 15/5/1-minute windows) matters just as much as the
current value: it shows the situation is actively WORSENING, not a
brief transient spike that's already recovering.

### Step 2 — Interpreting free -h
```
Mem:   16Gi  14Gi  200Mi  ...
Swap:  4.0Gi 3.8Gi 200Mi
```
"Most memory used" is often completely normal and even desirable
(Linux aggressively uses free RAM for page cache) — the REAL red flag
here is HEAVY SWAP USAGE (3.8Gi of 4.0Gi). Swap is disk-backed virtual
memory, and DISK I/O is orders of magnitude slower than RAM access —
once the system is forced to swap heavily, every memory access that
hits swapped-out pages incurs a massive latency penalty compared to a
pure in-RAM operation, which is precisely why heavy swapping causes a
system-wide slowdown, not just an issue for whichever process is
"using too much memory."

### Step 3 — Connecting wa (I/O wait) to the swap/load picture
`wa` ~45% means the CPU is IDLE roughly 45% of the time NOT because
there's no work to do, but because it's STUCK waiting on disk I/O to
complete before it can proceed. Connecting all three pieces into ONE
causal chain: the system has exhausted RAM (14Gi/16Gi used, only 200Mi
free) and is being forced to swap heavily (3.8Gi swapped) — every
process that touches swapped-out memory has to wait on slow DISK I/O to
page it back in, which shows up directly as high `wa` — and THAT I/O
wait is what's actually driving the high load average, NOT genuine
CPU-bound computation. This is "swap thrashing": the system spends more
effort shuffling memory in and out of swap than doing real work, and it
compounds — the more it thrashes, the slower everything gets, the more
processes pile up waiting, further raising load average.

### Step 4 — Immediate and long-term remediation
Immediate:
```bash
ps aux --sort=-%mem | head -5            # top line = the biggest memory consumer
sudo systemctl restart <offending-service>   # (or kill the process) to relieve pressure now
```
Identify and restart/kill the specific process consuming excessive
memory to relieve the acute pressure right now. Longer-term: right-size
the instance (add RAM) if the workload's genuine memory footprint has
simply outgrown capacity; investigate and FIX a memory leak if the
offending app's usage is growing unboundedly over time rather than
being a legitimate steady-state need; and add proactive
monitoring/alerting on swap usage and memory trends BEFORE they reach
this severity, so the NEXT time memory pressure starts building, someone
gets paged well before the system reaches swap-thrashing collapse.
Treating only the symptom (killing the process once) without any of
these longer-term fixes guarantees this exact incident repeats the next
time memory pressure builds up again.

> **Ubuntu / Debian:** `uptime`, `free`, `vmstat` and `ps` come from `procps`
> on every distro. Where the swap lives differs - `swapon --show` lists it on
> any distro (Ubuntu's default is a swapfile, `/swap.img`; RHEL's installer
> usually creates a swap partition or LV). `iostat` needs `sysstat`.

**Deliverable:** `ANSWER.md` in the challenge folder (written explanation +
commands).

---

## 20. Capstone - Provision & Harden a Production Linux Server

### The complete runbook (RHEL-family commands; Ubuntu / Debian differences are in the block at the end)

### Step 1 — Create the dedicated service account
(Challenge 2) — must exist
BEFORE anything is chowned to it or any systemd unit references it:
```bash
sudo useradd -r -s /sbin/nologin -d /opt/billing-service billing
```
`-r` (system account), `-s /sbin/nologin` (no interactive login
shell at all), no password set — least privilege from account
creation onward.

### Step 2 — Set ownership/permissions on the app directory
(Challenge 1) —
done AFTER the user exists, so `chown` has a valid target:
```bash
sudo mkdir -p /opt/billing-service/{releases/v1.0.0,data} /var/log/billing-service /backups
sudo chown -R billing:billing /opt/billing-service /var/log/billing-service
sudo chmod -R 750 /opt/billing-service
```

### Step 3 — Install dependencies, pinned
(Challenge 9):
```bash
sudo yum install -y python3 libfoo-1.4.2 yum-plugin-versionlock
sudo yum versionlock add libfoo-1.4.2
```

### Step 4 — First release + "current" symlink
(Challenge 16) — BEFORE the unit,
so `ExecStart=` can use `current/`:
```bash
sudo cp worker.py /opt/billing-service/releases/v1.0.0/     # from ~/linux-challenges/challenge4/
sudo ln -sfn /opt/billing-service/releases/v1.0.0 /opt/billing-service/current
sudo chown -R billing:billing /opt/billing-service/releases
sudo chown -h billing:billing /opt/billing-service/current
```

### Step 5 — Write and enable the systemd unit
(Challenge 4) — done AFTER the
app and its user both exist, so `ExecStart=`/`User=` are both valid:
```bash
sudo tee /etc/systemd/system/billing-service.service <<'EOF'
[Unit]
Description=Billing Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/billing-service/current/worker.py
ExecReload=/bin/kill -HUP $MAINPID
StandardOutput=append:/var/log/billing-service/app.log
StandardError=inherit
User=billing
Group=billing
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now billing-service
ss -tlnp | grep 8080                  # confirm what the app REALLY listens on
```
`ExecReload=` makes `systemctl reload` send SIGHUP, and
`StandardOutput=append:` writes the log file that logrotate watches.
The step 7 `postrotate` reload only does something if `worker.py`
handles SIGHUP by reopening its log file — if it does not, use
`copytruncate` instead of `postrotate` in the step 7 block.

### Step 6 — Configure the firewall
(Challenge 8) — done once the app is
actually listening, so you know which port to open: one port, one CIDR:
```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule=\
'rule family="ipv4" source address="10.0.0.0/16" port port="8080" protocol="tcp" accept'
sudo firewall-cmd --reload
```

### Step 7 — Set up log rotation
(Challenge 13):
```bash
sudo tee /etc/logrotate.d/billing-service <<'EOF'
/var/log/billing-service/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        systemctl reload billing-service > /dev/null 2>&1 || true
    endscript
}
EOF
```

### Step 8 — Schedule a nightly backup via systemd timer
(Challenges 12 & 18) —
observable, and logs excluded:
```bash
sudo tee /opt/billing-service/backup.sh <<'EOF'
#!/bin/bash
set -euo pipefail
tar czf /backups/billing-$(date +%F).tar.gz -C /opt/billing-service --exclude='*.log' data
EOF
sudo chmod 750 /opt/billing-service/backup.sh
```
`-C /opt/billing-service` plus the relative path `data` also removes the
"Removing leading `/`" warning.
```bash
sudo tee /etc/systemd/system/billing-backup.service <<'EOF'
[Unit]
Description=Nightly billing-service backup

[Service]
Type=oneshot
ExecStart=/opt/billing-service/backup.sh
EOF
sudo tee /etc/systemd/system/billing-backup.timer <<'EOF'
[Unit]
Description=Nightly backup at 02:00

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
sudo systemctl daemon-reload && sudo systemctl enable --now billing-backup.timer
```

### Step 9 — Harden SSH
(Challenge 14) — verify key login in a SECOND session
FIRST. A drop-in that sorts first wins over cloud-init files, because
sshd keeps the first value it reads:
```bash
sudo tee /etc/ssh/sshd_config.d/00-hardening.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
sudo sshd -t && sudo systemctl reload sshd          # Ubuntu / Debian: ssh
sudo sshd -T | grep -i -E 'permitrootlogin|passwordauthentication'   # confirm the effective values
```
This works on both RHEL 9 and Ubuntu, and gives you the `sshd -T`
check of the EFFECTIVE values on the RHEL side too.

### Step 10 — Disk + inode monitor, hourly
(Challenges 5 & 10) — an inode mode, and
snap / tmpfs mounts skipped on every distro, and the `-` that some
filesystems report in the percentage column ignored:
```bash
sudo tee /opt/billing-service/disk_check.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="${1:-90}"
MODE="${2:-space}"                    # "space" (default) or "inodes"
OVER_THRESHOLD=0

check_line() {
  local usage="$1" mount="$2"
  if [ "$usage" -gt "$THRESHOLD" ]; then
    echo "WARNING: $mount ($MODE) is at ${usage}% - over threshold!"
    return 1
  fi
  return 0
}

DF_FLAGS="-P"
[ "$MODE" = "inodes" ] && DF_FLAGS="-Pi"

while read -r _fs _total _used _free pct mount; do
  usage="${pct%\%}"
  [[ "$usage" =~ ^[0-9]+$ ]] || continue
  if ! check_line "$usage" "$mount"; then
    OVER_THRESHOLD=1
  fi
done < <(df $DF_FLAGS -x tmpfs -x devtmpfs -x squashfs | tail -n +2)

echo "Disk check ($MODE) complete."
exit "$OVER_THRESHOLD"
EOF
sudo chown root:billing /opt/billing-service/disk_check.sh
sudo chmod 750 /opt/billing-service/disk_check.sh
```
Cron file, with a log fallback because stock Ubuntu has no mail agent:
```bash
sudo tee /etc/cron.d/billing-disk-check <<'EOF'
MAILTO=oncall@company.com
0 * * * * root /opt/billing-service/disk_check.sh 90 >/dev/null || logger -p user.crit "billing: disk SPACE threshold breached"
5 * * * * root /opt/billing-service/disk_check.sh 90 inodes >/dev/null || logger -p user.crit "billing: INODE threshold breached"
EOF
sudo systemctl enable --now crond                   # RHEL: make sure the cron service is running (Ubuntu / Debian: cron)
systemctl list-timers billing-backup.timer          # final check: next backup is scheduled
```
`MAILTO` only works if a mail agent (postfix or mailx) is installed; the
`logger` line is the fallback.

> **Ubuntu / Debian — only the steps that differ.** Steps 2, 4, 5 (unit
> file), 7 (logrotate) and 8 (backup timer) are IDENTICAL.
> ```bash
> # STEP 1 - the no-login shell path differs
> sudo useradd -r -s /usr/sbin/nologin -d /opt/billing-service billing
> # STEP 3 - apt instead of yum (libfoo is the fictional pinned package)
> sudo apt update
> sudo apt install -y python3 libfoo=1.4.2-1
> sudo apt-mark hold libfoo
> # STEP 6 - ufw instead of firewalld: SSH first, then one port from one CIDR
> sudo ufw allow 22/tcp
> sudo ufw allow from 10.0.0.0/16 to any port 8080 proto tcp
> sudo ufw enable
> # STEP 9 - same drop-in + sshd -t, but the service is called ssh
> sudo sshd -t && sudo systemctl reload ssh
> sudo sshd -T | grep -i -E 'permitrootlogin|passwordauthentication'
> # STEP 10 - the cron service is "cron" (RHEL: crond) - make sure it runs
> sudo systemctl enable --now cron
> ```

### Why this ordering matters
Creating the user BEFORE setting ownership avoids a `chown` failure (or
worse, silently chowning to a nonexistent UID that later gets reused by
an unrelated account). Creating the release directory and the `current`
symlink BEFORE the unit means `ExecStart=` already has a real path, and
every future deploy is then an atomic `ln -sfn` plus a restart. Writing
the systemd unit AFTER the app and user both exist avoids a unit that
references a user/path that isn't there yet. Opening the firewall AFTER
confirming what the app actually listens on avoids guessing the wrong
port. SSH hardening and disk monitoring are largely independent of the
app-specific steps and could be done earlier or later without breaking
anything — but doing them LAST here serves as a deliberate final "harden
and monitor" pass once the core service is confirmed working (and never
before key login is proven), rather than fighting with a half-broken app
while also worrying about being locked out of SSH.

Each step maps to a named principle: **least privilege** (steps 1, 2, 6),
**reproducibility** (3, 4), **resilience** (5, 7, 8), **observability**
(8, 10) and **attack-surface reduction** (9).

### Closing note
This runbook combines every earlier challenge into one coherent, ordered
sequence: not just knowing each individual command, but understanding WHY
they must happen in THIS order, and being able to explain what would
break if two steps were swapped.

**Deliverable:** `RUNBOOK.md` in the challenge folder.

---

**You've now covered the full production Linux system administration skill
set: file permissions and special bits, least-privilege user/sudo
management, process/signal handling, systemd service authoring,
disk/filesystem/inode troubleshooting, LVM online growth, networking
fundamentals and connectivity triage, firewall least-privilege rules,
package management and version pinning, production-quality shell
scripting, the Unix text-processing pipeline, cron vs. systemd timers,
log rotation and journald, SSH hardening, safe find/xargs batch
operations, symlink-based deployment patterns, environment/PATH gotchas in
automation, backup/restore with tar, load-average/memory/I-O performance
triage, and a full capstone runbook tying every piece together.
