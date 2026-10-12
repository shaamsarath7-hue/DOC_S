# 🛠️ DevOps Knowledge Series

> Practical, hands-on DevOps notes, challenges and debugging stories, shared openly with the community.

![Topics](https://img.shields.io/badge/Topics-Linux-blue)
![Format](https://img.shields.io/badge/Format-PDF%20%7C%20Shell%20Scripts%20%7C%20Markdown-green)
![Cadence](https://img.shields.io/badge/Cadence-Every%20Monday-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

## 📖 About This Repository

This repository is the companion to my **LinkedIn knowledge-sharing series**. Every post on LinkedIn has its full material here: downloadable PDFs, lab scripts, answer keys and cheat sheets.

The goal is simple: **learn by doing**. Linux is covered in two parts:

| # | Part | What you get |
|---|------|--------------|
| 1 | **Handbook** | A concise, practical reference covering core concepts and commands |
| 2 | **Challenges & Debugging** | Real-world, ITSM-style incident and request scenarios, including debugging war-stories, to solve in a lab |

---

## 🗂️ Repository Structure

```text
.
├── README.md
│
└── Linux/
    ├── 1_Linux_Handbook/
    └── 2_Linux_Challenges/
```

For now, this repository contains **Linux** only. More tools will be added in the future.

---

## 📚 Series Roadmap

Posts go live on LinkedIn **every Monday**. For now, the series covers **Linux only**. More tools will be added in the future.

| Topic | 1. Handbook | 2. Challenges & Debugging |
|-------|:-----------:|:-------------------------:|
| **Linux** | ✅ Published | ✅ Published |

**Legend:** ✅ Published  |  🚧 In progress  |  🔜 Upcoming

---

## 🔍 What's Inside Each Folder

### 1️⃣ Handbook
A quick-reference guide for Linux.
- 📄 PDF handbook (readable and shareable)
- 📝 Command cheat sheet (coming soon)

### 2️⃣ Challenges & Debugging
A lab-style simulator that mimics real operational tickets.
- 📄 PDF with all challenge statements (incident and request style)
- 🐚 Shell script that sets up the lab environment
- 🔑 Answer key with the expected solution
- 🖥️ Sample outputs to verify your work
- 🐧 Commands for both **RHEL-based** (RHEL, CentOS, Rocky, Alma) and **Debian-based** (Ubuntu, Debian) systems

---

## 🚀 How to Use This Repository

### Read the notes
1. Open the `1_Linux/` folder.
2. Pick a part, for example `1_Linux_Handbook/`.
3. Open the PDF directly from GitHub, or download it for offline reading.

### Run the challenges
1. Clone the repository:
   ```bash
   git clone https://github.com/shaamsarath7-hue/DOC_S.git
   cd DOC_S/1_Linux/2_Linux_Challenges
   ```
2. Make the setup script executable and run it:
   ```bash
   chmod +x <script-name>.sh
   ./<script-name>.sh 1
   ```
3. Read the challenge PDF and solve each task in your terminal.
4. Compare your work against the **answer key** and **sample outputs**.

> ⚠️ **Safety note:** Run the scripts only in a **disposable lab environment** such as a VM, container or cloud sandbox. Never run them on production or personal machines.

---

## 🧰 Prerequisites

| Requirement | Details |
|-------------|---------|
| **OS** | Any modern Linux distribution (RHEL-based or Debian-based) |
| **Access** | Terminal with `sudo` or root privileges (lab only) |
| **Tools** | `bash`, `git`, and a PDF reader |
| **Recommended** | A VM (VirtualBox, VMware, WSL2) or a free-tier cloud instance |

---

## 🎯 Who Is This For?

- Aspiring **DevOps, Cloud and SRE** engineers
- **Linux administrators** looking to sharpen their practical skills
- Professionals testing their skills with hands-on challenges
- Anyone who prefers **learning by doing** over passive reading

---

## 🤝 Contributing

Found a mistake or have a better solution? Contributions are welcome.

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-improvement`
3. Commit your changes: `git commit -m "Describe your change"`
4. Push and open a **Pull Request**

You can also open an **Issue** for suggestions or corrections.

---

## 👤 Author

**ShaamNatheshwar Sasikumar**
DevOps / Cloud Engineer | Chennai, India

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/shaamnatheshwar-sasikumar/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?logo=github&logoColor=white)](https://github.com/shaamsarath7-hue)

---

## 📌 Disclaimer

All content is shared for **educational purposes**. Commands and scripts are provided as-is, so please review them before running and use them only in safe, non-production environments.

---

⭐ If you find this useful, **star the repository** and follow along on LinkedIn for new posts every **Monday**.

