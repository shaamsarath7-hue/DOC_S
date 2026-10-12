#!/usr/bin/env bash
# ==============================================================================
#  LINUX CHALLENGES SIMULATOR  -  20 production-style Linux challenges
#
#  Every challenge arrives as an ITSM ticket (Incident, Service Request, Change
#  Request or Problem record). The script builds a safe practice workspace under
#  ~/linux-challenges/ and prints the ticket. It never touches the real system.
#
#  Usage:
#     ./linux_challenge.sh list            show all 20 challenges
#     ./linux_challenge.sh <1-20>          build the workspace and print the ticket
#     ./linux_challenge.sh show <1-20>     print the ticket again
#     ./linux_challenge.sh clean <1-20>    wipe one challenge workspace
#     ./linux_challenge.sh clean all       wipe everything and start fresh
#
#  All people, teams, servers and ticket numbers are fictional.
# ==============================================================================
set -u

TOTAL=20
SELF="$(basename "$0")"
BASE="${LINUX_CHALLENGES_HOME:-${HOME:?HOME is not set}/linux-challenges}"

die() { echo "Error: $*" >&2; exit 1; }

# write_file <path> <mode>   (file content is read from stdin)
write_file() {
  mkdir -p "$(dirname "$1")" || die "cannot create directory for $1"
  cat > "$1" || die "cannot write $1"
  chmod "$2" "$1" || die "cannot chmod $1"
}

title() {
  case "$1" in
    1) echo "File Permissions & Ownership - chmod, chown & Special Bits" ;;
    2) echo "User & Group Management - useradd, sudoers & Least Privilege" ;;
    3) echo "Process Management - ps, kill, Signals, nice & Job Control" ;;
    4) echo "systemd Service Management - Writing a Custom Unit File" ;;
    5) echo "Disk & Filesystem Management - df, du, mount & /etc/fstab" ;;
    6) echo "LVM - Extending a Logical Volume Without Downtime" ;;
    7) echo "Networking Fundamentals - ip, ss, DNS & Connectivity Troubleshooting" ;;
    8) echo "Firewall Management - firewalld / iptables Least-Privilege Rules" ;;
    9) echo "Package Management - Repos, Dependency Conflicts & Pinning" ;;
    10) echo "Shell Scripting Fundamentals - A Real Production-Style Script" ;;
    11) echo "Text Processing - grep, awk, sed & the Unix Pipeline" ;;
    12) echo "Cron & Scheduled Tasks - crontab and systemd Timers" ;;
    13) echo "Log Management - journalctl, /var/log & logrotate" ;;
    14) echo "SSH Configuration & Hardening - Key-Based Auth Done Right" ;;
    15) echo "find & xargs - Safe, Efficient Batch File Operations" ;;
    16) echo "Symbolic & Hard Links - Inodes and What Can Go Wrong" ;;
    17) echo "Environment Variables & Shell Profiles - PATH and Login Shells" ;;
    18) echo "Archiving & Compression - tar, gzip & a Real Backup Strategy" ;;
    19) echo "Performance Troubleshooting - Load Average, Memory & I/O" ;;
    20) echo "Capstone - Provision & Harden a Production Linux Server" ;;
    *) echo "?" ;;
  esac
}

setup_1() {
  local d="$BASE/challenge1"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM1__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 1 of 20
================================================================================
 INCIDENT   INC0041831                                  PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : Finance team gets "permission denied" on shared_reports;
                      backup.sh permissions too open
 State              : In Progress
 Opened             : 05-Oct-2026 11:05
 Caller             : Olivia Bennett (Finance)
 Contact type       : Self-service portal
 Impact             : 2 - Medium
 Urgency            : 2 - Medium
 Category           : Access / Permissions
 Business service   : Finance Reporting
 Configuration item : fin-reports-01
 Target resolution  : 3 business days
 Assignment group   : Linux Platform Ops
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   Two access problems hit the same server. (1) shared_reports/ is used by the
   whole finance team, but every file is owned only by whoever created it, so
   teammates keep getting "permission denied" and the on-call engineer keeps
   doing manual sudo chmod fixes. (2) scripts/backup.sh must be runnable by
   members of backup-operators, must not be world-writable, and only its owner
   may edit it.

 WORK REQUIRED
  1. Explain setuid, setgid and the sticky bit in one plain sentence each.
  2. Fix shared_reports/ with setgid + sticky (group finance) - give exact
     commands and explain the leading digit of the numeric mode.
  3. Fix backup.sh so the group can execute but not modify it - justify the
     exact numeric mode.
  4. Explain why a setuid bit on a binary (e.g. /bin/bash) is dangerous.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge1/
 DELIVERABLE : ~/linux-challenges/challenge1/SOLUTION_COMMANDS.txt
 NEEDS       : sudo for chown / groupadd (the chmod parts run anywhere).
 CLOSE WHEN  : ls -ld shared_reports shows both setgid and sticky, and you can
               explain why each bit is independently necessary.
================================================================================
__PROBLEM1__
  write_file "$d/shared_reports/q3_report.csv" 664 <<'__F1_1__'
region,revenue,cost
north,120000,80000
south,98000,61000
east,143000,90500
west,87000,59000
__F1_1__
  write_file "$d/scripts/backup.sh" 775 <<'__F1_2__'
#!/bin/bash
tar czf /backups/reports-$(date +%F).tar.gz shared_reports
__F1_2__
  ( cd "$d" && chmod 775 shared_reports scripts ) || die "post-setup step failed"
}

setup_2() {
  local d="$BASE/challenge2"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM2__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 2 of 20
================================================================================
 SERVICE REQUEST (RITM)   RITM0010505                   PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : New hire onboarding: Linux account emma.h with scoped
                      sudo for billing-app
 State              : Work in Progress
 Opened             : 05-Oct-2026 13:37
 Requested for      : Emma Hartley (Junior DevOps Engineer)
 Requested by       : Daniel Whitfield (Hiring Manager)
 Catalog item       : New Hire - Linux Server Access
 Request            : REQ0031079
 Approval           : Approved (Manager)
 Catalog task       : SCTASK0010573
 Category           : Access Management
 Business service   : Linux Server Access
 Configuration item : lab-vm-01
 Target fulfilment  : 3 business days
 Assignment group   : Linux Platform Ops
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   A new hire, Emma (emma.h), starts today. The request asks for: a normal
   account in /home with /bin/bash, membership of the existing developers
   group, a temporary password that must be changed at first login, and
   passwordless sudo for only two things - restarting billing-app and viewing
   its logs. A past audit flagged someone who was handed full root sudo "to
   save time".

 WORK REQUIRED
  1. Write the useradd command and explain -g vs -G.
  2. Force a password change on first login with chage and explain what it
     changes in /etc/shadow.
  3. Write a least-privilege sudoers entry under /etc/sudoers.d/ with full
     command paths.
  4. Explain why "just give full sudo, we trust them" is a bad default.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge2/
 DELIVERABLE : ~/linux-challenges/challenge2/useradd_command.txt,
               ~/linux-challenges/challenge2/sudoers_emma
 NEEDS       : root / sudo on a Linux VM (a group called developers must
               exist).
 CLOSE WHEN  : Sudoers entry covers exactly the 2 commands with full paths,
               lives in /etc/sudoers.d/, and -G (not -g) is used.
================================================================================
__PROBLEM2__
  write_file "$d/ONBOARDING_REQUEST.md" 644 <<'__F2_1__'
New hire onboarding ticket
==========================
Username:        emma.h
Full name:       Emma Hartley
Role:            Junior DevOps Engineer
Home directory:  /home/emma.h
Shell:           /bin/bash
Groups:          developers (already exists on the server)
Password:        temporary - MUST be changed at first login
Sudo access:     passwordless sudo for ONLY these two actions:
                   - restart the billing-app service
                   - view the billing-app logs (journalctl)
Note:            A previous audit flagged an engineer who was given full root sudo
                 "to save time". Do not repeat that.
__F2_1__
}

setup_3() {
  local d="$BASE/challenge3"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM3__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 3 of 20
================================================================================
 INCIDENT   INC0041888                                      PRIORITY: P2 - High
--------------------------------------------------------------------------------
 Short description  : worker.py processes stuck in R / Z / D states on
                      app-srv-03, CPU pegged at 97%
 State              : In Progress
 Opened             : 05-Oct-2026 14:36
 Caller             : Monitoring alert: CPU > 95% for 30 min
 Contact type       : Monitoring alert
 Impact             : 2 - Medium
 Urgency            : 1 - High
 Category           : Application / Performance
 Business service   : Billing Platform
 Configuration item : app-srv-03
 Target resolution  : 8 hours
 Assignment group   : IT Operations - L2
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   An application server running a supervisor and several worker.py processes
   is in trouble. The captured ps snapshot shows four workers in four different
   states: R (PID 4471, pinned at 97% CPU), S (4472), Z (4901, a zombie) and D
   (5002, uninterruptible sleep). Triage this live and explain your reasoning
   like a real incident call.

 WORK REQUIRED
  1. Explain the STAT values R, S, Z, D - and why kill -9 on a D process is
     dangerous.
  2. What is a zombie, why will kill -9 4901 not remove it, and what actually
     cleans it up? (Use the PPID column.)
  3. SIGTERM vs SIGKILL on PID 4471 - which first and why?
  4. Lower PID 4471's priority with renice and explain the niceness range.
  5. A colleague must disconnect SSH without killing a foreground job - walk
     through Ctrl+Z, bg, jobs, disown, and SIGHUP.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge3/
 DELIVERABLE : ~/linux-challenges/challenge3/ANSWER.md
 NEEDS       : Analysis challenge - the commands run on any Linux shell.
 CLOSE WHEN  : You distinguish zombie vs uninterruptible sleep correctly, and
               state the SIGTERM-then-SIGKILL order with a reason.
================================================================================
__PROBLEM3__
  write_file "$d/PS_OUTPUT_SNAPSHOT.md" 644 <<'__F3_1__'
# ps snapshot captured from app-srv-03 at 10:21

USER  PID  PPID %CPU %MEM    VSZ   RSS TTY STAT START   TIME COMMAND
app  4400     1  0.0  0.1  98000  4100 ?   Ss   08:02   0:00 /usr/bin/python3 /opt/app/supervisor.py
app  4471  4400 97.2  1.1 812004 45120 ?   R    08:03  41:12 /usr/bin/python3 /opt/app/worker.py
app  4472  4400  0.1  0.3 221004 12300 ?   S    08:03   0:02 /usr/bin/python3 /opt/app/worker.py
app  4901  4472  0.0  0.0      0     0 ?   Z    09:14   0:00 [worker.py] <defunct>
app  5002  4400  1.9  1.0 801200 44000 ?   D    09:40   6:03 /usr/bin/python3 /opt/app/worker.py

STAT: R running | S interruptible sleep | Z zombie | D uninterruptible sleep
__F3_1__
}

setup_4() {
  local d="$BASE/challenge4"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM4__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 4 of 20
================================================================================
 CHANGE REQUEST   CHG0030636                            PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : Convert billing-worker from a manually started script
                      into a managed systemd service
 State              : Implement
 Opened             : 05-Oct-2026 15:37
 Type               : Normal
 Risk               : Moderate
 Requested by       : Lucas Fontaine (Application Support)
 Approval           : Approved (CAB)
 Category           : Service Management
 Business service   : Billing Platform
 Configuration item : app-srv-03
 Change task        : CTASK0030923
 Planned start      : 06-Oct-2026 22:00
 Planned end        : 07-Oct-2026 00:00
 Assignment group   : Cloud & DevOps
 Assigned to        : You (DevOps Engineer)
 Justification      : The worker stayed down after 2 of the last 3 reboots and
                      nobody was alerted. Managed service gives boot start,
                      restart on failure and status visibility.
--------------------------------------------------------------------------------
 DESCRIPTION
   The billing-worker Python process is started by hand with python3
   /opt/app/worker.py &. It does not survive reboots, does not restart after a
   crash, and nobody can tell if it is running except by grepping ps aux -
   which is why it silently stayed down after 2 of the last 3 reboots. Turn it
   into a proper managed systemd service.

 WORK REQUIRED
  1. Write billing-worker.service with Description= and After=network.target.
  2. [Service]: full-path ExecStart=, Restart=on-failure, RestartSec=5,
     non-root User= / Group=.
  3. [Install]: WantedBy=multi-user.target - and explain enable vs start.
  4. Show install + verify: copy, daemon-reload, enable --now, status.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge4/
 DELIVERABLE : ~/linux-challenges/challenge4/billing-worker.service
 NEEDS       : root + systemd (KodeKloud Linux VM).
 CLOSE WHEN  : Unit has Restart=on-failure, a non-root User=,
               WantedBy=multi-user.target; enable-vs-start and daemon-reload
               are explained.
================================================================================
__PROBLEM4__
  write_file "$d/worker.py" 755 <<'__F4_1__'
#!/usr/bin/env python3
"""billing-worker: stand-in worker used by the challenge."""
import time

print("billing-worker started", flush=True)
while True:
    time.sleep(5)
__F4_1__
  write_file "$d/CURRENT_PRACTICE.md" 644 <<'__F4_2__'
# How billing-worker is run today
cd /opt/app
python3 /opt/app/worker.py &

- Started by hand after every reboot (when someone remembers).
- Runs as root because "it was easier".
- If it crashes nothing restarts it and nothing alerts.
- Last 3 reboots: it stayed down after 2 of them.
__F4_2__
}

setup_5() {
  local d="$BASE/challenge5"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM5__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 5 of 20
================================================================================
 INCIDENT   INC0041904                                  PRIORITY: P1 - Critical
--------------------------------------------------------------------------------
 Short description  : "No space left on device" on / although df shows 600M
                      free; new disk must be mounted permanently
 State              : In Progress
 Opened             : 05-Oct-2026 17:22
 Caller             : Application error: "No space left on device"
 Contact type       : Phone
 Impact             : 1 - High
 Urgency            : 1 - High
 Category           : Storage
 Business service   : Billing Platform
 Configuration item : app-srv-03 (/dev/sda1)
 Target resolution  : 4 hours
 Assignment group   : Linux Platform Ops
 Assigned to        : You (DevOps Engineer)
 Related task       : SCTASK0010580
--------------------------------------------------------------------------------
 DESCRIPTION
   An application throws "No space left on device". At first glance / is only
   97% full and still has 600M free - so is it really a space problem? The df
   -i output tells a different story. Separately, a new disk /dev/sdb1 (ext4)
   must be mounted permanently at /opt/app-logs and survive reboots.

 WORK REQUIRED
  1. Diagnose precisely: space or inodes? Explain what an inode is and a
     realistic cause of exhaustion.
  2. Give the find-based approach to locate the directory that is eating the
     inodes.
  3. Write the /etc/fstab entry using the UUID, and explain why UUID beats
     /dev/sdb1.
  4. Show get-UUID, create mount point, add the line, mount -a - and why mount
     -a is also a validation step.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge5/
 DELIVERABLE : ~/linux-challenges/challenge5/diagnosis.txt,
               ~/linux-challenges/challenge5/fstab_entry.txt
 NEEDS       : root on a VM with a spare ext4 partition for the fstab part.
 CLOSE WHEN  : You identify inode exhaustion from the actual numbers (99%
               inodes vs 97% space) and the fstab entry uses a UUID.
================================================================================
__PROBLEM5__
  write_file "$d/DF_OUTPUT.md" 644 <<'__F5_1__'
# Captured from app-srv-03

$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G   19G  600M  97% /

$ df -i /
Filesystem       Inodes  IUsed   IFree IUse% Mounted on
/dev/sda1       1310720 1310000     720   99% /

Application log: "OSError: [Errno 28] No space left on device"
__F5_1__
  write_file "$d/FSTAB_CURRENT.md" 644 <<'__F5_2__'
# /etc/fstab on app-srv-03 (current)
UUID=7c1e5b52-0d3e-4a63-9d4b-1f2a3b4c5d6e  /          ext4  defaults  1 1
UUID=1a2b3c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d  swap       swap  defaults  0 0

# New disk attached, formatted ext4, NOT yet in fstab:
#   device: /dev/sdb1   mount point wanted: /opt/app-logs
__F5_2__
}

setup_6() {
  local d="$BASE/challenge6"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM6__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 6 of 20
================================================================================
 CHANGE REQUEST   CHG0030686                                PRIORITY: P2 - High
--------------------------------------------------------------------------------
 Short description  : Emergency change: extend /data logical volume online -
                      95% full and growing
 State              : Implement
 Opened             : 06-Oct-2026 08:49
 Type               : Emergency
 Risk               : Moderate
 Requested by       : Sophia Marchetti (Data Platform)
 Approval           : Approved (Emergency CAB)
 Category           : Storage
 Business service   : Data Platform
 Configuration item : data-srv-01 (data_vg/app_data)
 Change task        : CTASK0030971
 Planned start      : 06-Oct-2026 09:49
 Planned end        : 06-Oct-2026 11:49
 Assignment group   : Linux Platform Ops
 Assigned to        : You (DevOps Engineer)
 Justification      : /data is 95% full, the writing application cannot be
                      paused, and data_vg still holds 20 GB of unallocated
                      space.
--------------------------------------------------------------------------------
 DESCRIPTION
   /data is backed by LVM and is 95% full and climbing. The application writing
   to it cannot be paused or pruned on short notice. Luckily the volume group
   data_vg still has 20 GB free and unallocated. Grow app_data to use it -
   without unmounting and without taking the app offline.

 WORK REQUIRED
  1. Explain the PV -> VG -> LV model and why the extra layer makes this
     possible.
  2. Give the exact commands: lvextend to use all free space and the matching
     resize2fs.
  3. How do you verify the fix, and what does it mean if df still shows the old
     size?
  4. What changes if the VG had zero free space? (pvcreate -> vgextend -> ...)
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge6/
 DELIVERABLE : ~/linux-challenges/challenge6/lvm_commands.txt
 NEEDS       : root on a VM with LVM tools (a spare disk for the "no free
               space" path).
 CLOSE WHEN  : Your sequence contains both lvextend and resize2fs, and you can
               explain why online grow works but shrink does not.
================================================================================
__PROBLEM6__
  write_file "$d/LVM_CURRENT_STATE.md" 644 <<'__F6_1__'
# Captured from data-srv-01

$ vgs data_vg
  VG      #PV #LV #SN Attr   VSize    VFree
  data_vg   1   1   0 wz--n- 100.00g  20.00g

$ lvs data_vg
  LV       VG      Attr       LSize
  app_data data_vg -wi-ao---- 80.00g

$ df -h /data
Filesystem                    Size  Used Avail Use% Mounted on
/dev/mapper/data_vg-app_data   79G   75G  4.0G  95% /data

Filesystem type: ext4.  The writing application cannot be paused.
__F6_1__
}

setup_7() {
  local d="$BASE/challenge7"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM7__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 7 of 20
================================================================================
 INCIDENT   INC0041939                                      PRIORITY: P2 - High
--------------------------------------------------------------------------------
 Short description  : billing-api on port 8080 returns "Connection refused" for
                      every other server
 State              : In Progress
 Opened             : 06-Oct-2026 11:41
 Caller             : Liam Prescott (Dev Team)
 Contact type       : Phone
 Impact             : 2 - Medium
 Urgency            : 1 - High
 Category           : Network
 Business service   : Billing Platform
 Configuration item : billing-api-01 (10.0.1.55)
 Target resolution  : 8 hours
 Assignment group   : Network & Platform Support
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   The billing-api should listen on port 8080 and be reachable from other
   servers on the internal network, but callers get "Connection refused".
   Before escalation, someone proved outbound internet works (ping 8.8.8.8) and
   that the server has a valid IP (10.0.1.55/24). The remaining clue is in the
   ss -tlnp output.

 WORK REQUIRED
  1. Why does a process that is listening on 8080 still refuse other hosts?
     (read the Local Address column)
  2. What is the fix - and why is it an application setting, not a network-tool
     fix?
  3. After the fix, name 2 other layers that can still block traffic and the
     commands to narrow it down.
  4. ss vs netstat - why is ss the modern default?
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge7/
 DELIVERABLE : ~/linux-challenges/challenge7/ANSWER.md
 NEEDS       : Analysis challenge - the commands run on any Linux shell.
 CLOSE WHEN  : You identify the loopback binding from the ss output alone and
               name at least 2 more layers that can block the connection.
================================================================================
__PROBLEM7__
  write_file "$d/SYMPTOM_DATA.md" 644 <<'__F7_1__'
# billing-api-01 (10.0.1.55/24)

$ ping -c1 8.8.8.8
1 packets transmitted, 1 received, 0% packet loss        <- outbound internet works

$ ip -br addr
lo      UNKNOWN  127.0.0.1/8
eth0    UP       10.0.1.55/24                             <- valid IP

$ ss -tlnp | grep 8080
LISTEN 0 128 127.0.0.1:8080 0.0.0.0:* users:(("python3",pid=4471,fd=6))

# From another server on the network:
$ curl -sv http://10.0.1.55:8080/health
* connect to 10.0.1.55 port 8080 failed: Connection refused
__F7_1__
}

setup_8() {
  local d="$BASE/challenge8"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM8__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 8 of 20
================================================================================
 SERVICE REQUEST (RITM)   RITM0010549                   PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : Firewall rule request: 443/tcp from 10.0.0.0/16 and
                      8080/tcp from monitoring host 10.0.5.20 only
 State              : Work in Progress
 Opened             : 06-Oct-2026 13:55
 Requested for      : Isabella Moreau (Application Team)
 Requested by       : Isabella Moreau (Application Team)
 Catalog item       : Firewall Rule Request
 Request            : REQ0031087
 Approval           : Approved (Security)
 Catalog task       : SCTASK0010636
 Category           : Network Security
 Business service   : Billing Platform
 Configuration item : app-srv-03 (firewalld)
 Target fulfilment  : 3 business days
 Assignment group   : Security Operations
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   The server's firewalld currently allows only SSH. The app team needs two
   deliberately narrow rules: port 443/tcp open to the internal network
   10.0.0.0/16 only (never the internet), and port 8080/tcp open to one
   monitoring server 10.0.5.20 only - not even the rest of the internal
   network.

 WORK REQUIRED
  1. Open 443/tcp to 10.0.0.0/16 with a rich rule - and explain why not plain
     --add-port=443/tcp.
  2. Open 8080/tcp to exactly 10.0.5.20/32 - explain what /32 means.
  3. Explain --permanent vs runtime and the permanent + reload workflow.
  4. Conceptually compare firewalld zones/rich rules with raw iptables chain
     ordering.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge8/
 DELIVERABLE : ~/linux-challenges/challenge8/firewall_commands.txt
 NEEDS       : root + firewalld.
 CLOSE WHEN  : 443 is scoped to 10.0.0.0/16, 8080 to exactly 10.0.5.20/32, and
               the permanent + reload workflow is explained.
================================================================================
__PROBLEM8__
  write_file "$d/CURRENT_FIREWALL_STATE.md" 644 <<'__F8_1__'
# firewalld on app-srv-03 (current)

$ firewall-cmd --state
running

$ firewall-cmd --list-all
public (active)
  target: default
  interfaces: eth0
  services: ssh
  ports:
  rich rules:

Only SSH is allowed today.
__F8_1__
}

setup_9() {
  local d="$BASE/challenge9"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM9__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                    CHALLENGE 9 of 20
================================================================================
 INCIDENT   INC0041960                                      PRIORITY: P2 - High
--------------------------------------------------------------------------------
 Short description  : Critical app crash-looping since fleet-wide yum update
                      upgraded libfoo 1.4.2 to 1.6.0
 State              : In Progress
 Opened             : 06-Oct-2026 14:50
 Caller             : Marcus Hale (Application Support)
 Contact type       : Email
 Impact             : 2 - Medium
 Urgency            : 1 - High
 Category           : Software / Packages
 Business service   : Billing Platform
 Configuration item : app-srv-03
 Target resolution  : 8 hours
 Assignment group   : Linux Platform Ops
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   A fleet-wide yum update silently upgraded libfoo 1.4.2 -> 1.6.0 on this
   server, and a critical app with a known incompatibility has been
   crash-looping since. To make it harder, a different engineer needs a
   brand-new tool that requires libfoo 1.6.0 or newer on the same server.
   (libfoo is a fictional package used for the challenge; family used:
   RHEL/CentOS yum.)

 WORK REQUIRED
  1. Show installed and available versions of libfoo.
  2. Downgrade to 1.4.2 - and what if the repo no longer serves it?
  3. Pin libfoo so future updates never touch it, without freezing every other
     package.
  4. Resolve the conflict with the new tool that needs 1.6.0+.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge9/
 DELIVERABLE : ~/linux-challenges/challenge9/package_commands.txt
 NEEDS       : root on a RHEL-family VM (Debian/Ubuntu equivalents shown in
               comments).
 CLOSE WHEN  : Real downgrade + pinning commands within one package-manager
               family, and containerising (or fixing the app) named as the
               actual resolution.
================================================================================
__PROBLEM9__
  write_file "$d/INCIDENT_CONTEXT.md" 644 <<'__F9_1__'
# app-srv-03 package situation (RHEL / CentOS family, yum)

Fleet-wide "yum update" ran at 03:10 and upgraded libfoo 1.4.2 -> 1.6.0.
The critical application has been crash-looping since, because of a known
incompatibility with libfoo 1.6.0.

$ yum list --showduplicates libfoo
Installed Packages
libfoo.x86_64     1.6.0-1.el9     @updates
Available Packages
libfoo.x86_64     1.4.2-1.el9     baseos
libfoo.x86_64     1.6.0-1.el9     updates

Complication: a different engineer needs a brand-new tool on the SAME server
which REQUIRES libfoo 1.6.0 or newer.
(libfoo is a fictional package used for this challenge.)
__F9_1__
}

setup_10() {
  local d="$BASE/challenge10"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM10__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 10 of 20
================================================================================
 PROBLEM RECORD   PRB0040095                            PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : disk_check.sh breaks on mount points with spaces and
                      never returns a failing exit code
 State              : Root Cause Analysis
 Opened             : 06-Oct-2026 17:19
 Category           : Monitoring / Scripting
 Business service   : Infrastructure Monitoring
 Configuration item : disk_check.sh
 Related incidents  : 3 incidents
 Known error        : Yes - workaround documented
 Target resolution  : 3 business days
 Assignment group   : IT Operations - L2
 Assigned to        : You (DevOps Engineer)
 Problem statement  : The disk threshold script mis-parses mount points
                      containing spaces, has a hard-coded threshold, runs its
                      loop in a subshell and always exits 0, so cron and
                      monitoring cannot rely on it.
--------------------------------------------------------------------------------
 DESCRIPTION
   The starter disk_check.sh.starter alerts when a filesystem crosses a usage
   threshold, but it breaks in production: it mis-parses mount points
   containing spaces, has a hard-coded threshold, never exits non-zero (so
   cron/monitoring cannot use it), and its df | while read loop runs in a
   subshell, so any counter is lost.

 WORK REQUIRED
  1. Accept an optional threshold: ./disk_check.sh 85 (default 90) using
     ${1:-90}.
  2. Handle mount points with spaces - quote everything, use df -P.
  3. Add set -euo pipefail and explain -e, -u, -o pipefail.
  4. Exit 1 if anything is over threshold, else 0 - and fix the subshell
     gotcha.
  5. Move the per-line logic into a named function.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge10/
 DELIVERABLE : ~/linux-challenges/challenge10/disk_check.sh
 NEEDS       : Runs anywhere (any Linux shell).
 CLOSE WHEN  : Mount points with spaces parse correctly; exit code is 1 on
               breach and 0 otherwise; set -euo pipefail is at the top.
================================================================================
__PROBLEM10__
  write_file "$d/disk_check.sh.starter" 644 <<'__F10_1__'
#!/bin/bash
# disk_check.sh - starter version (known to be broken in production)
THRESHOLD=90
OVER=0

df | tail -n +2 | while read line; do
  usage=$(echo $line | awk '{print $5}' | tr -d '%')
  mount=$(echo $line | cut -d' ' -f6)
  if [ $usage -gt $THRESHOLD ]; then
    echo "WARNING: $mount is at ${usage}%"
    OVER=1
  fi
done

echo "Disk check complete."
exit 0
__F10_1__
}

setup_11() {
  local d="$BASE/challenge11"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM11__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 11 of 20
================================================================================
 INCIDENT   INC0041978                                      PRIORITY: P2 - High
--------------------------------------------------------------------------------
 Short description  : Customers report failed billing charges - HTTP 500 on
                      /api/billing/charge
 State              : In Progress
 Opened             : 07-Oct-2026 08:42
 Caller             : Chloe Dubois (Customer Support)
 Contact type       : Email
 Impact             : 2 - Medium
 Urgency            : 1 - High
 Category           : Application / Errors
 Business service   : Billing Platform
 Configuration item : web-srv-02 (access.log)
 Target resolution  : 8 hours
 Assignment group   : IT Operations - L2
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   Customers report failed billing charges. You have a raw web-server
   access.log (a 10-line sample here - imagine millions of lines) and must
   answer several questions fast, using only the Unix pipeline, as if
   live-debugging over SSH during an incident.

 WORK REQUIRED
  1. Count how many requests returned 500.
  2. List the unique IPs that got a 500 on /api/billing/charge, with counts,
     most frequent first.
  3. Extract METHOD + PATH from every line, show each unique pair once with its
     count (descending).
  4. Use sed to redact the source IP on every line.
  5. Why awk rather than cut for question 3?
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge11/
 DELIVERABLE : ~/linux-challenges/challenge11/commands.txt
 NEEDS       : Runs anywhere (any Linux shell).
 CLOSE WHEN  : Every command is a real one-liner producing the exact output
               shown, and the IP list is sorted by count, descending.
================================================================================
__PROBLEM11__
  write_file "$d/access.log" 644 <<'__F11_1__'
10.0.1.5 - - [14/Sep/2026:08:01:12] "GET /api/health HTTP/1.1" 200 45
10.0.2.9 - - [14/Sep/2026:08:01:15] "POST /api/billing/charge HTTP/1.1" 500 120
10.0.1.5 - - [14/Sep/2026:08:01:20] "GET /api/health HTTP/1.1" 200 45
10.0.3.7 - - [14/Sep/2026:08:01:31] "GET /api/users/42 HTTP/1.1" 200 310
10.0.2.9 - - [14/Sep/2026:08:01:44] "POST /api/billing/charge HTTP/1.1" 500 120
10.0.4.2 - - [14/Sep/2026:08:02:03] "GET /api/orders HTTP/1.1" 200 1288
10.0.2.9 - - [14/Sep/2026:08:02:10] "POST /api/billing/charge HTTP/1.1" 500 120
10.0.1.5 - - [14/Sep/2026:08:02:20] "GET /api/health HTTP/1.1" 200 45
10.0.2.9 - - [14/Sep/2026:08:02:31] "POST /api/billing/charge HTTP/1.1" 500 120
10.0.5.1 - - [14/Sep/2026:08:02:40] "POST /api/billing/charge HTTP/1.1" 200 98
__F11_1__
}

setup_12() {
  local d="$BASE/challenge12"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM12__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 12 of 20
================================================================================
 SERVICE REQUEST (RITM)   RITM0010568                   PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : Schedule nightly DB backup on weekdays 02:30, a one-time
                      cleanup at 23:45, and start-failure visibility
 State              : Work in Progress
 Opened             : 07-Oct-2026 09:44
 Requested for      : Nathan Brooks (DBA Team)
 Requested by       : Nathan Brooks (DBA Team)
 Catalog item       : Job Scheduling Request
 Request            : REQ0031131
 Approval           : Approved (Service Owner)
 Catalog task       : SCTASK0010679
 Category           : Job Scheduling
 Business service   : Billing Database
 Configuration item : db-srv-01 (backup_db.sh)
 Target fulfilment  : 3 business days
 Assignment group   : IT Operations - L2
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   Three scheduling needs around backup_db.sh: (1) run it daily at 2:30 AM on
   weekdays only; (2) run a separate cleanup script exactly once tonight at
   11:45 PM; (3) leadership wants to know immediately if the nightly backup
   ever fails to even start (server down, scheduler not running...) - something
   plain cron can never tell you.

 WORK REQUIRED
  1. Write the exact crontab line and explain the 5 fields.
  2. Use at for the one-time job - why not cron?
  3. Why does plain cron give no visibility into "did it start"? What is the
     systemd alternative?
  4. Write the .timer + .service pair for the same weekday 2:30 AM schedule.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge12/
 DELIVERABLE : ~/linux-challenges/challenge12/crontab_entry.txt,
               ~/linux-challenges/challenge12/billing-backup.timer,
               ~/linux-challenges/challenge12/billing-backup.service
 NEEDS       : cron, at and systemd (replace student with your username in
               paths).
 CLOSE WHEN  : Crontab = 30 2 * * 1-5; at job is genuinely one-time;
               OnCalendar=Mon..Fri 02:30:00 expresses the same schedule.
================================================================================
__PROBLEM12__
  write_file "$d/backup_db.sh" 755 <<'__F12_1__'
#!/bin/bash
# Nightly database backup (stand-in for the challenge)
echo "$(date '+%F %T') backup started"
echo "$(date '+%F %T') backup finished"
__F12_1__
  write_file "$d/cleanup_once.sh" 755 <<'__F12_2__'
#!/bin/bash
# One-time cleanup (stand-in for the challenge)
echo "$(date '+%F %T') cleanup done"
__F12_2__
  write_file "$d/REQUIREMENTS.md" 644 <<'__F12_3__'
# Scheduling requirements

1. backup_db.sh  - every weekday (Mon-Fri) at 02:30. Not weekends.
2. cleanup_once.sh - exactly ONCE, tonight at 23:45. Never again.
3. Leadership wants to know immediately if the nightly backup ever fails to
   even START (server down, scheduler stopped...). Plain cron cannot tell you.
__F12_3__
}

setup_13() {
  local d="$BASE/challenge13"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM13__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 13 of 20
================================================================================
 INCIDENT   INC0041994                                      PRIORITY: P2 - High
--------------------------------------------------------------------------------
 Short description  : /var/log filled the root filesystem overnight; logs for
                      the incident window also needed
 State              : In Progress
 Opened             : 07-Oct-2026 10:54
 Caller             : Monitoring alert: / filesystem > 90%
 Contact type       : Monitoring alert
 Impact             : 2 - Medium
 Urgency            : 2 - Medium
 Category           : Storage / Logging
 Business service   : Billing Platform
 Configuration item : app-srv-03 (/var/log)
 Target resolution  : 8 hours
 Assignment group   : Linux Platform Ops
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   Two related problems. (1) /var/log filled the root filesystem overnight
   because billing-app logs heavily and nothing rotates, compresses or deletes
   old logs. (2) An engineer must see what billing-app did around an incident
   time last night - but it logs only to the systemd journal, not to a .log
   file.

 WORK REQUIRED
  1. Write a logrotate config: daily, keep 14, compress with delaycompress, and
     postrotate or copytruncate (justify).
  2. Give four journalctl commands: unit logs, a time window, live follow,
     errors only.
  3. Why does the output land in the journal, and what is the trade-off?
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge13/
 DELIVERABLE : ~/linux-challenges/challenge13/billing-app.logrotate,
               ~/linux-challenges/challenge13/journalctl_commands.txt
 NEEDS       : root + logrotate + systemd.
 CLOSE WHEN  : Config has daily, rotate 14, compression and a justified
               postrotate/copytruncate choice; journalctl uses -u,
               --since/--until, -f, -p.
================================================================================
__PROBLEM13__
  write_file "$d/INCIDENT_CONTEXT.md" 644 <<'__F13_1__'
# Context

- /var/log filled the root filesystem overnight. Nothing rotates, compresses
  or deletes old logs for billing-app.
- Separately: an engineer must see what billing-app did around 22:00-22:30 last
  night. The service logs only to the systemd journal, not to a .log file.
- Sample log files are in var_log_sim/ so you can practise logrotate safely.
__F13_1__
  write_file "$d/var_log_sim/app-1.log" 644 <<'__F13_2__'
2026-10-01 22:05:11 INFO  billing-app request processed id=1511
2026-10-01 22:09:40 INFO  billing-app request processed id=1940
2026-10-01 22:14:02 INFO  billing-app request processed id=1142
__F13_2__
  write_file "$d/var_log_sim/app-2.log" 644 <<'__F13_3__'
2026-10-02 22:05:11 INFO  billing-app request processed id=2511
2026-10-02 22:09:40 INFO  billing-app request processed id=2940
2026-10-02 22:14:02 INFO  billing-app request processed id=2142
__F13_3__
  write_file "$d/var_log_sim/app-3.log" 644 <<'__F13_4__'
2026-10-03 22:05:11 INFO  billing-app request processed id=3511
2026-10-03 22:09:40 INFO  billing-app request processed id=3940
2026-10-03 22:14:02 INFO  billing-app request processed id=3142
__F13_4__
  write_file "$d/var_log_sim/app-4.log" 644 <<'__F13_5__'
2026-10-04 22:05:11 INFO  billing-app request processed id=4511
2026-10-04 22:09:40 INFO  billing-app request processed id=4940
2026-10-04 22:14:02 INFO  billing-app request processed id=4142
__F13_5__
  write_file "$d/var_log_sim/app-5.log" 644 <<'__F13_6__'
2026-10-05 22:05:11 INFO  billing-app request processed id=5511
2026-10-05 22:09:40 INFO  billing-app request processed id=5940
2026-10-05 22:14:02 INFO  billing-app request processed id=5142
__F13_6__
}

setup_14() {
  local d="$BASE/challenge14"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM14__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 14 of 20
================================================================================
 CHANGE REQUEST   CHG0030734                            PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : Remediate SSH audit findings: root login, password auth,
                      X11, retries and idle sessions
 State              : Implement
 Opened             : 07-Oct-2026 13:22
 Type               : Normal
 Risk               : Moderate
 Requested by       : Hannah Lindqvist (Security Compliance)
 Approval           : Approved (CAB)
 Category           : Security Hardening
 Business service   : Linux Server Access
 Configuration item : app-srv-03 (sshd)
 Change task        : CTASK0030984
 Planned start      : 08-Oct-2026 22:00
 Planned end        : 09-Oct-2026 00:00
 Assignment group   : Cloud & DevOps
 Assigned to        : You (DevOps Engineer)
 Justification      : Security audit flagged PermitRootLogin yes,
                      PasswordAuthentication yes, X11Forwarding yes,
                      MaxAuthTries 6 and ClientAliveInterval 0.
--------------------------------------------------------------------------------
 DESCRIPTION
   A security audit flagged every line of this server's SSH config:
   PermitRootLogin yes, PasswordAuthentication yes, X11Forwarding yes,
   MaxAuthTries 6 and ClientAliveInterval 0. Harden it fully - without locking
   yourself out.

 WORK REQUIRED
  1. Generate an SSH key pair (algorithm choice: ed25519 vs rsa).
  2. Install the public key and explain the 700 / 600 permissions.
  3. Rewrite every flagged line and justify each change.
  4. Validate the config with sshd -t before restarting - and explain why.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge14/
 DELIVERABLE : ~/linux-challenges/challenge14/hardened_sshd_config.md
 NEEDS       : root + sshd on a VM (and a second terminal for the safety test).
 CLOSE WHEN  : All 6 hardened settings are present, and you explain the "test
               key login in a second session first" safety step.
================================================================================
__PROBLEM14__
  write_file "$d/current_sshd_config.md" 644 <<'__F14_1__'
# /etc/ssh/sshd_config (current, as flagged by the security audit)

Port 22
PermitRootLogin yes
PasswordAuthentication yes
X11Forwarding yes
MaxAuthTries 6
ClientAliveInterval 0
UsePAM yes
Subsystem sftp /usr/libexec/openssh/sftp-server
__F14_1__
}

setup_15() {
  local d="$BASE/challenge15"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM15__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 15 of 20
================================================================================
 CHANGE REQUEST   CHG0030764                            PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : Standard change: purge stale tmp uploads and remove
                      world-writable permissions from app_data
 State              : Implement
 Opened             : 07-Oct-2026 15:43
 Type               : Standard
 Risk               : Low
 Requested by       : Hannah Lindqvist (Security Compliance)
 Approval           : Pre-approved (Standard template)
 Category           : Security / Housekeeping
 Business service   : Billing Platform
 Configuration item : app-srv-03 (app_data)
 Change task        : CTASK0031022
 Planned start      : 08-Oct-2026 22:00
 Planned end        : 09-Oct-2026 00:00
 Assignment group   : Linux Platform Ops
 Assigned to        : You (DevOps Engineer)
 Justification      : A security scan found world-writable config files
                      (secrets.conf and legacy settings.conf); tmp_uploads/
                      also holds .tmp files older than 7 days.
--------------------------------------------------------------------------------
 DESCRIPTION
   Two jobs on app_data/: (1) tmp_uploads/ collects .tmp files that must be
   deleted once older than 7 days; (2) a security scan found world-writable
   config files - secrets.conf and one with a space in its name (legacy
   settings.conf) - that must be fixed in one safe, batched operation.

 WORK REQUIRED
  1. Delete .tmp files older than 7 days with -mtime +7 -delete - and when
     would you need xargs instead?
  2. Find all world-writable files and fix them with xargs chmod o-w using
     -print0 / -0 - why?
  3. What is the real danger of a careless find | xargs rm, and what safety
     habit do you follow?
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge15/
 DELIVERABLE : ~/linux-challenges/challenge15/commands.txt
 NEEDS       : Runs anywhere (any Linux shell).
 CLOSE WHEN  : -mtime +7 and -delete used correctly; -print0 / xargs -0 used
               with a clear explanation of why.
================================================================================
__PROBLEM15__
  write_file "$d/app_data/tmp_uploads/upload_1.tmp" 644 <<'__F15_1__'
temp upload 1
__F15_1__
  write_file "$d/app_data/tmp_uploads/upload_2.tmp" 644 <<'__F15_2__'
temp upload 2
__F15_2__
  write_file "$d/app_data/tmp_uploads/upload_3.tmp" 644 <<'__F15_3__'
temp upload 3
__F15_3__
  write_file "$d/app_data/tmp_uploads/upload_4.tmp" 644 <<'__F15_4__'
temp upload 4
__F15_4__
  write_file "$d/app_data/tmp_uploads/upload_5.tmp" 644 <<'__F15_5__'
temp upload 5
__F15_5__
  write_file "$d/app_data/configs/app.conf" 664 <<'__F15_6__'
mode=production
__F15_6__
  write_file "$d/app_data/configs/secrets.conf" 666 <<'__F15_7__'
db_password=ChangeMe-not-a-real-secret
__F15_7__
  write_file "$d/app_data/configs/legacy settings.conf" 666 <<'__F15_8__'
legacy=true
__F15_8__
  ( cd "$d" && touch -d '10 days ago' app_data/tmp_uploads/upload_1.tmp app_data/tmp_uploads/upload_2.tmp app_data/tmp_uploads/upload_3.tmp ) || die "post-setup step failed"
}

setup_16() {
  local d="$BASE/challenge16"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM16__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 16 of 20
================================================================================
 INCIDENT   INC0042027                                  PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : Deploying v1.1.0 did not switch the live release -
                      "current" pointer misbehaving
 State              : In Progress
 Opened             : 07-Oct-2026 17:50
 Caller             : Oliver Grant (Release Management)
 Contact type       : Self-service portal
 Impact             : 2 - Medium
 Urgency            : 2 - Medium
 Category           : Release / Deployment
 Business service   : Billing Platform
 Configuration item : app-srv-03 (releases/)
 Target resolution  : 3 business days
 Assignment group   : Cloud & DevOps
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   Every release lives under releases/<version>/, and a current pointer must
   indicate the live one so a supervisor can always run
   releases/current/app.jar without knowing the version number - and a deploy
   can "switch" by repointing it. An engineer made current a hard link to
   v1.0.0/app.jar and was confused when "deploying" v1.1.0 did not behave as
   expected.

 WORK REQUIRED
  1. Explain symbolic vs hard link in terms of inodes - and why a hard link
     cannot cross filesystems.
  2. Why did the hard-link current fail as a release pointer?
  3. Implement it correctly with a symlink to the directory and re-point it
     with ln -sfn - what do -f and -n do?
  4. What is the rollback advantage of this pattern?
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge16/
 DELIVERABLE : ~/linux-challenges/challenge16/commands.txt
 NEEDS       : Runs anywhere (any Linux shell).
 CLOSE WHEN  : Inode-based reasoning for why hard links fail as a pointer, and
               ln -sfn used to re-point the symlink.
================================================================================
__PROBLEM16__
  write_file "$d/DEPLOYMENT_CONTEXT.md" 644 <<'__F16_1__'
# Release layout

releases/
  v1.0.0/app.jar      <- live today
  v1.1.0/app.jar      <- new release

The supervisor always starts:  releases/current/app.jar
so it never needs to know the version number. A deploy should "switch" by
re-pointing "current".

An engineer created "current" as a HARD LINK to v1.0.0/app.jar. After deploying
v1.1.0 the supervisor still ran the old code.
__F16_1__
  write_file "$d/releases/v1.0.0/app.jar" 644 <<'__F16_2__'
app version 1.0.0
__F16_2__
  write_file "$d/releases/v1.1.0/app.jar" 644 <<'__F16_3__'
app version 1.1.0
__F16_3__
}

setup_17() {
  local d="$BASE/challenge17"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM17__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 17 of 20
================================================================================
 INCIDENT   INC0042080                                  PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : deploy-tool works over SSH but fails with "command not
                      found" in cron and CI
 State              : In Progress
 Opened             : 08-Oct-2026 08:51
 Caller             : Mia Hoffmann (Build & Release)
 Contact type       : Self-service portal
 Impact             : 2 - Medium
 Urgency            : 2 - Medium
 Category           : Automation / Environment
 Business service   : CI/CD Pipeline
 Configuration item : build-srv-01
 Target resolution  : 3 business days
 Assignment group   : Cloud & DevOps
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   An engineer installed a tool at /opt/deploy-tool/bin/deploy-tool and added
   export PATH=$PATH:/opt/deploy-tool/bin to ~/.bashrc. It works perfectly over
   SSH, but the same command fails with "command not found" from a cron job and
   from a CI pipeline step - even though the file is still there.

 WORK REQUIRED
  1. Why is ~/.bashrc never read by cron or CI shells?
  2. Compare ~/.bashrc, ~/.bash_profile / ~/.profile and /etc/environment for
     non-interactive contexts.
  3. Give 2 concrete fixes (PATH inside the crontab, and absolute path).
  4. Why is hard-coding absolute paths in automation a good practice?
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge17/
 DELIVERABLE : ~/linux-challenges/challenge17/explanation.md
 NEEDS       : Runs anywhere (a stand-in tool is created inside the workspace).
 CLOSE WHEN  : You explain interactive/login vs non-interactive shells
               correctly and give at least 2 working fixes.
================================================================================
__PROBLEM17__
  write_file "$d/deploy_tool_report.md" 644 <<'__F17_1__'
# Report

The tool lives at  /opt/deploy-tool/bin/deploy-tool
An engineer added  export PATH=$PATH:/opt/deploy-tool/bin  to ~/.bashrc.

- Over SSH: `deploy-tool --version` works.
- From a cron job:  /bin/sh: deploy-tool: command not found
- From a CI pipeline step: "deploy-tool: command not found"
The file is still there in both cases.

For this lab a stand-in tool is created at:
  ~/linux-challenges/challenge17/opt/deploy-tool/bin/deploy-tool
(use that path instead of /opt/deploy-tool/bin).
__F17_1__
  write_file "$d/opt/deploy-tool/bin/deploy-tool" 755 <<'__F17_2__'
#!/bin/sh
echo "deploy-tool 2.3.1"
__F17_2__
}

setup_18() {
  local d="$BASE/challenge18"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM18__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 18 of 20
================================================================================
 SERVICE REQUEST (RITM)   RITM0010581                   PRIORITY: P3 - Moderate
--------------------------------------------------------------------------------
 Short description  : Dated backup of app_to_backup excluding logs, integrity
                      check, and partial restore of config/
 State              : Work in Progress
 Opened             : 08-Oct-2026 10:24
 Requested for      : Ethan Calloway (Application Owner)
 Requested by       : Ethan Calloway (Application Owner)
 Catalog item       : Backup & Restore Request
 Request            : REQ0031145
 Approval           : Approved (Service Owner)
 Catalog task       : SCTASK0010733
 Category           : Backup & Restore
 Business service   : Billing Platform
 Configuration item : app-srv-03 (app_to_backup)
 Target fulfilment  : 3 business days
 Assignment group   : IT Operations - L2
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   Back up the entire app_to_backup/ directory into one compressed archive,
   excluding logs/ (regenerable bloat), with the date in the filename so daily
   backups never overwrite each other. Verify the archive is not corrupted
   without extracting it, and later restore only config/ after an accidental
   config deletion.

 WORK REQUIRED
  1. Create the dated .tar.gz, excluding logs/ - explain -c -z -v -f --exclude.
  2. tar czf vs tar cjf - gzip vs bzip2 trade-off.
  3. Verify integrity without extracting (tar tzf).
  4. Restore only config/ into a fresh directory - and why you need the exact
     internal path.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge18/
 DELIVERABLE : ~/linux-challenges/challenge18/backup_commands.txt
 NEEDS       : Runs anywhere (any Linux shell).
 CLOSE WHEN  : Archive command excludes logs/ and embeds the date; the partial
               restore targets only config/.
================================================================================
__PROBLEM18__
  write_file "$d/BACKUP_REQUIREMENTS.md" 644 <<'__F18_1__'
# Backup requirements for app_to_backup/

1. One compressed archive of the ENTIRE app_to_backup/ directory,
   EXCLUDING logs/ (regenerable bloat).
2. The date must be in the file name so daily backups never overwrite each other.
3. Verify the archive is readable WITHOUT extracting it.
4. Later: someone deletes config/ by accident - restore ONLY config/ into a fresh directory.
__F18_1__
  write_file "$d/app_to_backup/config/app.conf" 644 <<'__F18_2__'
mode=production
port=8080
__F18_2__
  write_file "$d/app_to_backup/data/records.db" 644 <<'__F18_3__'
id,name,amount
1,alpha,100
2,beta,250
__F18_3__
  write_file "$d/app_to_backup/logs/old.log" 644 <<'__F18_4__'
2026-10-01 INFO old log line
2026-10-02 INFO another old log line
__F18_4__
}

setup_19() {
  local d="$BASE/challenge19"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM19__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 19 of 20
================================================================================
 INCIDENT   INC0042117                                      PRIORITY: P2 - High
--------------------------------------------------------------------------------
 Short description  : Production server very slow - load 8.42 on 4 cores, swap
                      3.8/4.0 Gi used, I/O wait ~45%
 State              : In Progress
 Opened             : 08-Oct-2026 11:38
 Caller             : Monitoring alert: load average 8.42 on 4 cores
 Contact type       : Monitoring alert
 Impact             : 1 - High
 Urgency            : 2 - Medium
 Category           : Performance
 Business service   : Billing Platform
 Configuration item : app-srv-03
 Target resolution  : 8 hours
 Assignment group   : IT Operations - L2
 Assigned to        : You (DevOps Engineer)
--------------------------------------------------------------------------------
 DESCRIPTION
   Customers say a production server is "slow". The snapshot: load average
   8.42, 7.95, 6.10 on a 4-core machine; free -h shows 200Mi free of 16Gi and
   swap 3.8Gi of 4.0Gi used; vmstat shows I/O wait (wa) around 45%. Work
   through it like a live incident call and connect all three signals into one
   diagnosis.

 WORK REQUIRED
  1. Interpret load average vs nproc and the trend 6.10 -> 7.95 -> 8.42.
  2. Interpret free -h - why is heavy swap (not "memory mostly used") the red
     flag?
  3. Interpret wa ~45% and tie it to swapping and load in a single causal
     chain.
  4. Give the immediate and long-term remediation.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge19/
 DELIVERABLE : ~/linux-challenges/challenge19/ANSWER.md
 NEEDS       : Analysis challenge - the commands run on any Linux shell.
 CLOSE WHEN  : All three signals (load, swap, I/O wait) are connected into one
               coherent explanation - not three separate observations.
================================================================================
__PROBLEM19__
  write_file "$d/PERFORMANCE_SNAPSHOT.md" 644 <<'__F19_1__'
# app-srv-03 - captured while users reported "very slow"

$ uptime
 14:32:01 up 45 days,  3:12,  2 users,  load average: 8.42, 7.95, 6.10

$ nproc
4

$ free -h
              total        used        free      shared  buff/cache   available
Mem:           16Gi        14Gi       200Mi       100Mi       1.7Gi       1.5Gi
Swap:         4.0Gi       3.8Gi       200Mi

$ vmstat 1 3
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 6  4 3891200 204800 102400 1740000 120  340    88   210 1400 2200 22 18 15 45  0
 5  5 3891300 198000 102400 1741000 118  355    92   225 1420 2250 21 19 14 46  0
 6  4 3891400 201000 102400 1739500 125  348    90   218 1410 2230 23 17 15 45  0
__F19_1__
}

setup_20() {
  local d="$BASE/challenge20"
  mkdir -p "$d" || die "cannot create $d"
  write_file "$d/PROBLEM.md" 644 <<'__PROBLEM20__'
================================================================================
 LINUX CHALLENGES SIMULATOR                                   CHALLENGE 20 of 20
================================================================================
 CHANGE REQUEST   CHG0030778                                PRIORITY: P2 - High
--------------------------------------------------------------------------------
 Short description  : New production server build for billing-service:
                      provision and harden end to end
 State              : Implement
 Opened             : 08-Oct-2026 13:02
 Type               : Normal
 Risk               : High
 Requested by       : Elena Petrova (IT Operations)
 Approval           : Approved (CAB)
 Category           : Server Build
 Business service   : Billing Platform
 Configuration item : billing-srv-new (RHEL)
 Change task        : CTASK0031053
 Planned start      : 09-Oct-2026 22:00
 Planned end        : 10-Oct-2026 00:00
 Assignment group   : Cloud & DevOps
 Assigned to        : You (DevOps Engineer)
 Justification      : A bare RHEL/CentOS VM must become the production home of
                      billing-service. Steps are ordered; swapping two of them
                      breaks the build.
--------------------------------------------------------------------------------
 DESCRIPTION
   A brand-new, bare RHEL/CentOS VM must become the production home of the
   billing-service application. Combine everything from Challenges 1-19 into
   one ordered runbook: service account, permissions, pinned dependencies,
   systemd unit, narrow firewall, log rotation, nightly backup timer, SSH
   hardening, release symlink and disk monitoring. Order matters - be ready to
   say what breaks if two steps are swapped.

 WORK REQUIRED
  1. Create a non-root billing account with no login shell.
  2. Set ownership / permissions (nothing world-writable).
  3. Install pinned dependencies; write + enable the systemd unit.
  4. Firewall: only the app port, only from the internal CIDR.
  5. logrotate, nightly backup timer (tar, excluding logs), SSH hardening,
     current-release symlink, disk/inode monitor.
--------------------------------------------------------------------------------
 WORKSPACE   : ~/linux-challenges/challenge20/
 DELIVERABLE : ~/linux-challenges/challenge20/RUNBOOK.md
 NEEDS       : root on a fresh RHEL-family VM.
 CLOSE WHEN  : The runbook is genuinely ordered, every step ties to a named
               principle, and you can explain what breaks if two steps are
               swapped.
================================================================================
__PROBLEM20__
  write_file "$d/REQUIREMENTS.md" 644 <<'__F20_1__'
# Build requirements: billing-service on a fresh RHEL/CentOS VM

 1. Non-root service account "billing" with no login shell.
 2. Ownership / permissions: nothing world-writable.
 3. Dependencies installed and PINNED (libfoo 1.4.2).
 4. systemd unit: runs as billing, restarts on failure, starts on boot.
 5. Firewall: ONLY the app port (8080/tcp), ONLY from 10.0.0.0/16.
 6. Log rotation: daily, keep 14, compressed.
 7. Nightly backup via a systemd timer (tar, excluding logs).
 8. SSH hardening: no root login, no password login.
 9. A "current" symlink pointing at the live release.
10. Hourly disk / inode monitoring that alerts on breach.

ORDER MATTERS: be ready to explain what breaks if two steps are swapped.
__F20_1__
}

# ensure_deliverables <n>
# Creates every DELIVERABLE file named in the ticket as a starter template, so
# `cat` always finds it. The file names are read from PROBLEM.md itself, so the
# ticket and the files can never drift apart. Existing files are NEVER
# overwritten - your work is safe.
ensure_deliverables() {
  local n="$1"
  local dir="$BASE/challenge$n"
  local prob="$dir/PROBLEM.md"
  [ -f "$prob" ] || die "challenge $n brief is missing: $prob"
  local rel f mode c
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    f="$dir/$rel"
    [ -e "$f" ] && continue
    mode=644
    case "$rel" in *.sh) mode=755 ;; esac
    case "$rel" in *.md) c='>' ;; *) c='#' ;; esac
    {
      echo "$c CHALLENGE $n DELIVERABLE: $rel"
      echo "$c $(title "$n")"
      echo "$c"
      echo "$c Replace this template with your answer. Brief: cat ~/linux-challenges/challenge$n/PROBLEM.md"
      echo "$c"
      echo "$c WORK REQUIRED (from the ticket):"
      awk '/^ WORK REQUIRED/{f=1;next} /^---/{if(f)exit} f' "$prob" | sed "s/^/$c /"
      echo "$c"
      echo "$c ---- start your answer below this line ----"
      echo
    } | write_file "$f" "$mode"
  done < <(awk '/^ DELIVERABLE/{f=1} /^ NEEDS/{f=0} f' "$prob" \
             | grep -o "challenge$n/[^ ,]*" | sed "s#^challenge$n/##")
  # verify every deliverable named in the ticket really exists
  while IFS= read -r rel; do
    [ -z "$rel" ] || [ -f "$dir/$rel" ] || die "deliverable missing after setup: $dir/$rel"
  done < <(awk '/^ DELIVERABLE/{f=1} /^ NEEDS/{f=0} f' "$prob" \
             | grep -o "challenge$n/[^ ,]*" | sed "s#^challenge$n/##")
}
valid_n() {
  [[ "${1:-}" =~ ^[0-9]+$ ]] || return 1
  local v=$((10#$1))
  (( v >= 1 && v <= TOTAL ))
}

list_challenges() {
  echo "Linux Challenges Simulator"
  echo "Available challenges:"
  local i
  for i in $(seq 1 "$TOTAL"); do
    printf '  %-3s%s\n' "$i" "$(title "$i")"
  done
  echo
  echo "Usage: $SELF <1-$TOTAL> | list | show <N> | clean <N|all>"
}

run_challenge() {
  local n=$((10#$1))
  local dir="$BASE/challenge$n"
  if [ -d "$dir" ] && [ -f "$dir/PROBLEM.md" ]; then
    echo "Workspace for challenge $n already exists - your work is untouched."
    echo "(Use '$SELF clean $n' if you want a fresh start.)"
    echo
  else
    setup_"$n"
  fi
  ensure_deliverables "$n"
  cat "$dir/PROBLEM.md"
  echo
  local shown="${dir/#"$HOME"/\~}"
  echo "Workspace:       $shown/"
  echo "Read the brief:  cat $shown/PROBLEM.md"
  echo "Files created:   ls $shown/"
  echo "Deliverable(s):  fill in the template file(s) named in the ticket above"
}

show_challenge() {
  local n=$((10#$1))
  local f="$BASE/challenge$n/PROBLEM.md"
  [ -f "$f" ] || die "challenge $n has not been built yet - run: $SELF $n"
  cat "$f"
}

clean_challenge() {
  local target="${1:-}"
  [ -n "$target" ] || die "usage: $SELF clean <1-$TOTAL|all>"
  if [ "$target" = "all" ]; then
    [ -n "$BASE" ] && [ "$BASE" != "/" ] || die "refusing to wipe '$BASE'"
    if [ ! -d "$BASE" ]; then echo "Nothing to wipe."; return 0; fi
    if [ -t 0 ]; then
      read -r -p "Delete ALL challenge workspaces under $BASE ? Type yes to confirm: " ans
      [ "$ans" = "yes" ] || { echo "Cancelled."; return 0; }
    fi
    rm -rf -- "$BASE" || die "could not remove everything (files owned by root? try: sudo rm -rf $BASE)"
    echo "Wiped all challenges."
  else
    valid_n "$target" || die "'$target' is not a challenge number (1-$TOTAL) or 'all'"
    local n=$((10#$target))
    rm -rf -- "$BASE/challenge$n" || die "could not remove challenge $n (files owned by root? try: sudo rm -rf $BASE/challenge$n)"
    echo "Wiped challenge $n."
  fi
}

case "${1:-list}" in
  list|-l|--list|help|-h|--help) list_challenges ;;
  show)  valid_n "${2:-}" || die "usage: $SELF show <1-$TOTAL>"; show_challenge "$2" ;;
  clean) clean_challenge "${2:-}" ;;
  *)     valid_n "$1" || { list_challenges >&2; exit 1; }
         run_challenge "$1" ;;
esac
