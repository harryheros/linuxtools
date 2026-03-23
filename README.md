# 🚀 AutoLinux v2.0.3 — Unified Debian & Ubuntu Auto-Reinstall Tool

![Version](https://img.shields.io/badge/version-2.0.3-green.svg)
![License](https://img.shields.io/badge/license-GPLv3-blue.svg)
![OS Support](https://img.shields.io/badge/OS-Debian%2011%20%7C%2012%20%7C%2013%20%7C%20Ubuntu%2022.04%20%7C%2024.04-red.svg)
![Platform](https://img.shields.io/badge/platform-BIOS%20%7C%20UEFI-orange.svg)
![Language](https://img.shields.io/badge/language-bash-black.svg)

AutoLinux is a high-performance automated reinstall tool for VPS and bare-metal servers.

It provides a deterministic way to reinstall Debian or Ubuntu directly from the running system using official upstream resources, without requiring a rescue ISO or external recovery environment.

> ⚠️ Intended only for systems owned or managed by the operator.

---

## ⚡ Quick Start

> Requires Bash  
> Run as root

### Review script before execution

```bash
curl -fsSL -o autolinux.sh https://raw.githubusercontent.com/harryheros/linuxtools/main/os/autolinux.sh
less autolinux.sh
```

---

### Default installation (Debian 12)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtools/main/os/autolinux.sh)
```

---

### Debian 13 (custom password + SSH port)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtools/main/os/autolinux.sh) -d 13 -p "YourPassword" --port 2222
```

---

### Ubuntu 24.04

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtools/main/os/autolinux.sh) -u 24
```

---

### Ubuntu 22.04

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtools/main/os/autolinux.sh) -u 22
```

---

### Full example

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/harryheros/linuxtools/main/os/autolinux.sh) -u 24 -p "SecurePassword" --port 2222
```

---

## ⚠️ DATA LOSS WARNING

This tool will completely erase the primary disk and reinstall the operating system.

All existing data on the target disk will be permanently destroyed.

Use only on systems you own or are explicitly authorized to manage.

---

## ✨ Features

- Unified Debian and Ubuntu reinstall workflow
- Works on both BIOS and UEFI systems
- Cross-distribution execution support (Debian, Ubuntu, CentOS, etc.)
- Uses official upstream images and installer resources
- Debian installation via official netboot installer + preseed automation
- Ubuntu deployment via official cloud image + direct disk write
- Automatic disk and network detection
- Static IPv4 migration from current system
- Optional IPv6 carry-over when detected
- Automatic SSH root login configuration
- Custom SSH port support
- Automatic random root password generation when `-p` is not provided
- Built-in FQ + BBR network optimization
- Ubuntu EFI fallback boot path repair
- CentOS 7 Vault repo fallback for legacy dependency installation

---

## 📂 Supported Operating Systems

### Debian
- Debian 13 (Trixie)
- Debian 12 (Bookworm) — default
- Debian 11 (Bullseye)

### Ubuntu
- Ubuntu 24.04 LTS (Noble) — default
- Ubuntu 22.04 LTS (Jammy)

---

## 🏗 Installation Architecture

### Debian path
1. Detect current disk and network configuration
2. Download official Debian netboot installer
3. Inject `preseed.cfg` and post-install script into initrd
4. Create temporary GRUB boot entry
5. Reboot into automated Debian installer

### Ubuntu path
1. Detect current disk and network configuration
2. Download official Ubuntu cloud image
3. Mount image through `qemu-nbd`
4. Configure root password, SSH, sysctl, netplan, and cloud-init seed
5. Fix EFI fallback boot path if applicable
6. Write image directly to target disk
7. Force reboot into the new system

---

## 🛠 Parameters

```bash
-d [11|12|13]       Install Debian (default: 12)
-u [22|24]          Install Ubuntu (default: 24)
-p password         Set root password (optional)
-port / --port N    Set SSH port (default: 22)
-h / --help         Show help
```

---

## 🔐 Default Behavior

- If `-p` is not provided, a random root password is generated automatically
- The generated password is shown before reboot and must be saved by the operator
- SSH is configured to allow root login and password authentication
- The detected primary disk is used as the installation target
- Current network settings are reused for static configuration

---

## 🧪 Tested Environments

- KVM virtual machines
- Common cloud VPS providers
- BIOS systems
- UEFI systems

---

## ⚖️ License

GNU General Public License v3.0 (GPL-3.0)

---

## 🔗 Repository

https://github.com/harryheros/linuxtools
