# 📘 The Complete Linux Engineering Handbook

> Foundations to DevOps Internals, covering 28 modules in one practical reference.

![Modules](https://img.shields.io/badge/Modules-28-blue)
![Parts](https://img.shields.io/badge/Parts-5-green)
![Format](https://img.shields.io/badge/Format-PDF-red)
![Level](https://img.shields.io/badge/Level-Beginner%20to%20Advanced-orange)

**Prepared by:** Shaam Natheshwar, DevOps Engineer

---

## 📖 About This Handbook

A hands-on Linux reference built for DevOps, Cloud and SRE work. It starts with the basics and goes down to kernel, container and troubleshooting internals. Every module includes:

- **Concept explanations:** what it is and why it matters in production
- **Command-line blocks:** formatted exactly as they appear in a terminal
- **Flow diagrams:** ASCII diagrams for the boot process, LVM stack, container internals and the troubleshooting flow
- **Practical notes:** gotchas, defaults and things that matter on the job

Read it top to bottom as a course, or use the table of contents as a lookup while you work.

---

## 📥 Download

👉 **[LinuxHandbook.pdf](./LinuxHandbook.pdf)** (80 pages)

On GitHub, open the file and click **Download raw file** to save it for offline reading.

---

## 🗂️ What's Inside

| Part | Focus | Modules |
|------|-------|:-------:|
| **1. Foundations** | Linux basics, installation and boot process, filesystem hierarchy | 1 – 3 |
| **2. Command Line Mastery** | Shell, files, text processing, redirection, shell scripting | 4 – 9 |
| **3. System Administration** | Users, permissions, processes, systemd, packages, storage, networking, security, logging, scheduling, network services | 10 – 20 |
| **4. Advanced Linux** | Kernel, containers and virtualization, high availability, performance tuning, hardening | 21 – 25 |
| **5. Linux for DevOps** | Containers and Kubernetes, automation, troubleshooting methodology | 26 – 28 |

### Module Index

<details>
<summary><b>Part 1: Foundations</b></summary>

1. Linux Fundamentals
2. Linux Installation & Boot Process
3. Linux Filesystem Hierarchy

</details>

<details>
<summary><b>Part 2: Command Line Mastery</b></summary>

4. Shell & Terminal Basics
5. File & Directory Operations
6. File Content Operations
7. Text Processing: grep, sed, awk
8. I/O Redirection & Pipes
9. Shell Scripting

</details>

<details>
<summary><b>Part 3: System Administration</b></summary>

10. User & Group Management
11. File Permissions & Access Control
12. Process Management
13. Service Management with systemd
14. Package Management
15. Storage & Filesystem Management
16. Networking in Linux
17. Linux Security
18. Logging & Monitoring
19. Scheduling & Automation
20. Network Services Administration

</details>

<details>
<summary><b>Part 4: Advanced Linux</b></summary>

21. Kernel Management
22. Linux Containers & Virtualization
23. High Availability & Clustering
24. Performance Tuning
25. Linux Hardening & Best Practices

</details>

<details>
<summary><b>Part 5: Linux for DevOps</b></summary>

26. Linux for Containers & Kubernetes
27. Linux Automation for DevOps
28. Linux Troubleshooting Methodology

</details>

---

## ✨ Highlights

- 🐧 Commands for both **RHEL-family** (`dnf`, `rpm`, `firewalld`, SELinux) and **Debian-family** (`apt`, `dpkg`, `ufw`, AppArmor) systems
- 🔍 Deep-dive tooling: `strace`, `lsof`, `tcpdump`, `perf`, `bpftrace`
- 📦 Container internals: namespaces, cgroups, overlayfs, and how Docker and Kubernetes use them
- 🛠️ A structured troubleshooting flow with playbooks for boot failures, disk full, high CPU, high memory, network issues and service failures
- 🔐 Hardening: SSH, SELinux, auditd, CIS benchmark concepts and kernel `sysctl` settings

---

## 🎯 Who Is This For?

- Aspiring **DevOps, Cloud and SRE** engineers
- **Linux administrators** who want a quick, practical reference
- Anyone working toward **RHCSA, CKA or similar** hands-on Linux skills
- Professionals who learn best by running real commands

---

## 🧪 Suggested Way to Use It

1. Read **Parts 1 and 2** to get comfortable with the shell and scripting.
2. Practise each module's commands on a **VM or disposable lab**. Never use production.
3. Keep **Module 28 (Troubleshooting)** open as a go-to guide.
4. Test yourself with the hands-on **[Linux Challenges](../2_Linux_Challenges/)**.

---

## 🔗 Related

- 📁 **[Linux Challenges](../2_Linux_Challenges/)** puts these concepts to work in lab-style scenarios.
- 🏠 **[Back to the main repository](../../README.md)**

---

## 👤 Author

**ShaamNatheshwar Sasikumar**, DevOps / Cloud Engineer, Chennai, India

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/shaamnatheshwar-sasikumar/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?logo=github&logoColor=white)](https://github.com/shaamsarath7-hue)

---

📌 *Shared for educational purposes. Always test commands in a safe, non-production environment.*

