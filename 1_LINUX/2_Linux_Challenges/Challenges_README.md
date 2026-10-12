# 🧪 Linux Challenges Simulator

> 20 production-style Linux challenges, each delivered as an ITSM ticket. **Break it. Debug it. Fix it.**

![Challenges](https://img.shields.io/badge/Challenges-20-blue)
![Format](https://img.shields.io/badge/Format-Bash%20Simulator%20%7C%20PDF%20%7C%20Answer%20Key-green)
![Distros](https://img.shields.io/badge/Distros-RHEL%20%7C%20Ubuntu%20%7C%20Debian%20%7C%20SUSE-orange)
![Level](https://img.shields.io/badge/Level-Intermediate-lightgrey)

**Author:** Shaamnatheshwar Sasikumar, DevOps Engineer

---

## 📖 About

The **Linux Challenges Simulator** is a hands-on, bash-driven practice lab. Every challenge arrives the way work arrives in a real IT operations team: as an **ITSM ticket** (Incident, Service Request, Change Request or Problem record) with a ticket number, priority, caller, assignment group and affected configuration item.

You pick up the ticket, work it on a Linux VM, and close it with your own resolution notes. These are **challenges for testing your own skills** against realistic situations: a disk that is "full" with free space left, a service that is listening but unreachable, a script that fails only on certain mount points, a server crawling under swap pressure.

> All people, teams, servers and ticket numbers are fictional.

---

## 📦 Files in This Folder

| File | What it is |
|------|------------|
| 📄 **[Linux_Challenges.pdf](./Linux_Challenges.pdf)** | The full guide: all 20 tickets, worked solutions, Ubuntu / Debian blocks, cheat sheet and distro command map |
| 🐚 **[linux_challenge.sh](./linux_challenge.sh)** | The simulator script that builds each challenge's workspace and prints its ticket |
| 🔑 **[linux_challenge_answer.md](./linux_challenge_answer.md)** | Full answer key. Open it **only after** a genuine attempt |

---

## 🔁 How It Works: The 4-Step Loop

| Step | What you do |
|:----:|-------------|
| **1. Generate** | Run `./linux_challenge.sh <N>`. The scenario files and `PROBLEM.md` appear under `~/linux-challenges/challengeN/` |
| **2. Pick up the ticket** | Read the ticket: priority, what is broken or requested, and the work required |
| **3. Work it** | Solve it on a real Linux VM and verify with the tools the ticket points to |
| **4. Resolve and compare** | Write your resolution notes, then compare with the answer key |

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/shaamsarath7-hue/DOC_S.git
cd DOC_S/1_LINUX/2_Linux_Challenges

# 2. Make the simulator executable (once)
chmod +x linux_challenge.sh

# 3. See all 20 challenges
./linux_challenge.sh list

# 4. Build a challenge and print its ticket
./linux_challenge.sh 1
```

Run it with `./linux_challenge.sh` or `bash linux_challenge.sh`. **Do not use `sh`**, because the script needs bash features (on Ubuntu / Debian, `sh` is dash).

### Command reference

| Command | What it does |
|---------|--------------|
| `./linux_challenge.sh list` | Show all 20 challenge titles (also the default with no argument) |
| `./linux_challenge.sh <1-20>` | Build the workspace for that challenge and print its ticket |
| `./linux_challenge.sh show <1-20>` | Print an already-built ticket again |
| `./linux_challenge.sh clean <1-20>` | Wipe one challenge's workspace |
| `./linux_challenge.sh clean all` | Wipe **everything** under `~/linux-challenges/` (asks you to type `yes`) |

### Where your work lives

Each challenge is built under `~/linux-challenges/challengeN/` in your home directory, **not inside this repository**. Running a challenge that already exists **never overwrites your work**. The ticket names the deliverable file(s) to fill in, and every deliverable is created as a starter template so `cat` always finds it.

### Reading just one answer

```bash
sed -n '/^## 5\. /,/^## 6\. /p' linux_challenge_answer.md | less
```

Change `5` and `6` to the challenge you want and the one after it. For challenge 20, use `sed -n '/^## 20\. /,$p' linux_challenge_answer.md | less`.

---

## 🗂️ The 20 Challenges

| # | Ticket | Type | Topic | Where to run |
|:-:|--------|------|-------|--------------|
| 01 | INC0041831 | Incident | File Permissions & Ownership: chmod, chown & special bits | VM with sudo |
| 02 | RITM0010505 | Service Request | User & Group Management: useradd, sudoers & least privilege | VM with sudo |
| 03 | INC0041888 | Incident | Process Management: ps, kill, signals, nice & job control | Analysis |
| 04 | CHG0030636 | Change Request | systemd Service Management: writing a custom unit file | VM with sudo |
| 05 | INC0041904 | Incident | Disk & Filesystem Management: df, du, mount & /etc/fstab | VM with sudo |
| 06 | CHG0030686 | Change Request | LVM: extending a logical volume without downtime | VM with sudo |
| 07 | INC0041939 | Incident | Networking Fundamentals: ip, ss, DNS & connectivity troubleshooting | Analysis |
| 08 | RITM0010549 | Service Request | Firewall Management: firewalld / iptables least-privilege rules | VM with sudo |
| 09 | INC0041960 | Incident | Package Management: repos, dependency conflicts & pinning | VM with sudo |
| 10 | PRB0040095 | Problem | Shell Scripting Fundamentals: a real production-style script | Any shell |
| 11 | INC0041978 | Incident | Text Processing: grep, awk, sed & the Unix pipeline | Any shell |
| 12 | RITM0010568 | Service Request | Cron & Scheduled Tasks: crontab and systemd timers | VM with sudo |
| 13 | INC0041994 | Incident | Log Management: journalctl, /var/log & logrotate | VM with sudo |
| 14 | CHG0030734 | Change Request | SSH Configuration & Hardening: key-based auth done right | VM with sudo |
| 15 | CHG0030764 | Change Request | find & xargs: safe, efficient batch file operations | Any shell |
| 16 | INC0042027 | Incident | Symbolic & Hard Links: inodes and what can go wrong | Any shell |
| 17 | INC0042080 | Incident | Environment Variables & Shell Profiles: PATH and login shells | Any shell |
| 18 | RITM0010581 | Service Request | Archiving & Compression: tar, gzip & a real backup strategy | Any shell |
| 19 | INC0042117 | Incident | Performance Troubleshooting: load average, memory & I/O | Analysis |
| 20 | CHG0030778 | Change Request | **Capstone:** provision & harden a production Linux server | VM with sudo |

### Ticket types

| Prefix | Record | Meaning | Challenges |
|--------|--------|---------|------------|
| **INC** | Incident | Something is broken or degraded; restore service first | 1, 3, 5, 7, 9, 11, 13, 16, 17, 19 |
| **RITM** | Requested Item | A standard service request from the catalog | 2, 8, 12, 18 |
| **CHG** | Change Request | A planned modification (Standard, Normal or Emergency) | 4, 6, 14, 15, 20 |
| **PRB** | Problem | Root cause of a recurring issue | 10 |

Priority is shown as **P1 Critical, P2 High, P3 Moderate or P4 Low**.

### Where each challenge can run

| Environment | Challenges | What you need |
|-------------|------------|---------------|
| **Any Linux shell** | 10, 11, 15, 16, 17, 18 | Just bash and coreutils. Run and test everything for real, no root needed |
| **Analysis from a snapshot** | 3, 7, 19 | You read captured `ps`, `ss`, `uptime`, `free` and `vmstat` output and reason like an incident call |
| **Real VM with root / sudo** | 1, 2, 4, 5, 6, 8, 9, 12, 13, 14, 20 | A Linux VM with systemd, LVM tools, a package manager, firewalld or ufw, cron / at, sshd and sudo |

---

## 🐧 Distros Covered

Each solution shows **RHEL-family** commands first (RHEL, Rocky, Alma, CentOS Stream, Fedora), followed by an **Ubuntu / Debian** block for the same task. A **Distro Command Map** at the end of the PDF puts RHEL, Ubuntu / Debian and SUSE side by side.

The simulator script itself needs only **bash and GNU tools**, so it runs on all of these. It does not run on Alpine / BusyBox or macOS.

---

## 🧰 Prerequisites

| Requirement | Details |
|-------------|---------|
| **OS** | Any modern Linux distribution |
| **Shell** | bash |
| **Access** | `sudo` / root for the challenges marked "VM with sudo" |
| **Recommended** | A disposable VM (VirtualBox, VMware, WSL2, a cloud sandbox, or a hosted lab such as KodeKloud) |

> ⚠️ **Safety note:** The simulator only creates files under `~/linux-challenges/` and never touches the rest of your system. The **solutions**, however, change real system settings (users, firewall, SSH, fstab, LVM and so on). Work the root-level challenges **only on a disposable lab VM**, never on a production or personal machine.

---

## ✅ Ground Rules

- Read the ticket and `PROBLEM.md` and write your **own** commands first. Open the solution only afterwards.
- Explain **why**, not just what. Treat the **Closure criteria** on every ticket as your own scoring check.
- Write the deliverable file named in the ticket into the challenge's workspace folder.
- Repeat any challenge you could not finish without peeking: `./linux_challenge.sh clean <N>`, then run it again.
- The **Command Cheat Sheet** at the end of the PDF lists every command used, challenge by challenge.

---

## 🔬 What Was Tested

- Everything the script prints, and the outputs of challenges **1 (chmod / ls steps), 10, 11, 15, 16, 17 and 18**, were produced by actually running the commands against the files the script creates.
- The corrected Ubuntu / Debian steps in challenges **1, 2, 18 and 20** were tested on **Ubuntu 24.04**.
- Unit files were checked with `systemd-analyze verify` and the sudoers line with `visudo -cf`.
- Commands that need root, LVM, firewalld, yum / dnf or a real server (hostnames, UIDs, UUIDs and the fictional `libfoo` package) show **representative** output. Try them on your own VM.

---

## 🔗 Related

- 📘 **[Linux Handbook](../1_Linux_Handbook/)** is the reference to read alongside these challenges.
- 🏠 **[Back to the main repository](../../README.md)**

---

## 👤 Author

**Shaamnatheshwar Sasikumar**, DevOps Engineer, Chennai, India

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/shaamnatheshwar-sasikumar/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?logo=github&logoColor=white)](https://github.com/shaamsarath7-hue)

---

📌 *Shared for educational purposes. Always review commands before running them, and use a safe, non-production environment.*

