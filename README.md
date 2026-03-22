# 🚀 AutoLinux v2.0.1 — Unified Linux Provisioning & Reinstall Tool

![Version](https://img.shields.io/badge/version-2.0.1-green.svg)  
![License](https://img.shields.io/badge/License-GPLv3-blue.svg)  
![OS Support](https://img.shields.io/badge/OS-Debian%2011%20%7C%2012%20%7C%2013%20%7C%20Ubuntu%2022.04%20%7C%2024.04-red.svg)  
![Platform](https://img.shields.io/badge/Platform-BIOS%20%7C%20UEFI-orange.svg)  
![Language](https://img.shields.io/badge/language-bash-black.svg)

AutoLinux is a high-performance Linux provisioning and reinstall tool designed for VPS and bare-metal servers.

It provides a deterministic and automated way to reinstall Debian or Ubuntu systems using official upstream resources, without requiring provider rescue environments.

> This tool is intended for use on systems owned or managed by the operator.

---

# 📑 Table of Contents

Overview  
Quick Start  
Key Features  
Supported Operating Systems  
Installation Architecture  
Network Provisioning Model  
Installation Flow  
Advanced Parameters  
Security Model  
Tested Environments  
Operational Notes  
Design Philosophy  
License  

---

# 📘 Overview

AutoLinux addresses a common infrastructure problem: reliably reprovisioning Linux systems across heterogeneous environments.

Typical use cases include:

• VPS operating system reinstallation  
• migration to modern Debian or Ubuntu releases  
• rebuilding servers without rescue images  
• automated infrastructure recovery  
• rapid reprovisioning workflows  

The tool is designed to be transparent, predictable, and suitable for operators managing their own infrastructure.

---

# ⚡ Quick Start

> Requires bash (process substitution support).  
Run as root on the target system.

### Review script before execution

```bash
curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtool/main/os/autolinux.sh
```

---

## Default installation (Debian 12)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtool/main/os/autolinux.sh)
```

---

## Install Debian 13 with custom SSH port and password

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtool/main/os/autolinux.sh) -d 13 -p "YourPassword" --port 2222
```

---

## Install Ubuntu 24.04

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtool/main/os/autolinux.sh) -u 24
```

---

## Install Ubuntu 22.04

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtool/main/os/autolinux.sh) -u 22
```

---

## Full example

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtool/main/os/autolinux.sh) -u 24 -p "SecurePassword" --port 2222
```

---

⚠ DATA LOSS WARNING

This tool will completely erase the primary system disk and reinstall the operating system.  
All existing data will be permanently destroyed.  

Use only on systems you own or are authorized to manage.

---

# ✨ Key Features

Unified Debian and Ubuntu Installer  

AutoLinux supports both Debian and Ubuntu installation workflows through a single interface.  

Debian uses the official network installer, while Ubuntu uses official cloud images for faster deployment.

---

BIOS and UEFI Compatibility  

Works across both legacy BIOS and modern UEFI systems.  

Bootloader configuration is handled automatically.

---

Cross-Distribution Execution  

Can be executed from multiple Linux distributions, including:

Debian  
Ubuntu  
CentOS 7  
AlmaLinux  
Rocky Linux  
Fedora  

---

Official Upstream Sources  

All installation assets are downloaded from official upstream sources:

• Debian infrastructure  
• Ubuntu cloud image servers  

No modified images or third-party mirrors are used.

---

Deterministic Deployment Model  

AutoLinux prioritizes predictable execution:

• simple disk detection  
• explicit network configuration  
• minimal assumptions  

---

High-Speed Ubuntu Deployment  

Ubuntu installation uses cloud images:

• download official image  
• modify filesystem offline  
• write directly to disk  

---

Automated SSH Access Setup  

AutoLinux configures SSH access during installation to ensure remote accessibility after provisioning.

---

Network Optimization  

• FQ queue discipline  
• TCP BBR congestion control  

---

IPv6 Handling  

IPv6 is restored only if valid parameters are detected.  

---

# 📂 Supported Operating Systems

Target Systems:

Debian 13 (Trixie)  
Debian 12 (Bookworm) — Default  
Debian 11 (Bullseye)  

Ubuntu 24.04 LTS (Noble) — Default  
Ubuntu 22.04 LTS (Jammy)  

---

# 🏗 Installation Architecture

Debian Path:

1. download official netboot installer  
2. inject automated configuration  
3. reboot into installer  

Ubuntu Path:

1. download official cloud image  
2. mount via qemu-nbd  
3. write to disk  

---

# 🛠 Advanced Parameters

-d [11|12|13]  
-u [22|24]  
-p password  
--port N  
-h, --help  

---

## Example usage

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtool/main/os/autolinux.sh) -u 24 -p "SecurePassword" --port 2222
```

---

# 🔐 Security Model

• no embedded credentials  
• operator-controlled execution  
• local system only  

---

# 🧪 Tested Environments

KVM  
cloud VPS  
BIOS / UEFI  

---

# ⚖ License

Author: Harry  

Repository:  
https://github.com/harryheros/linuxtool  

GPLv3
