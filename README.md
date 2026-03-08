# 🚀 AutoLinux v2.0.1 — Unified Linux Auto Installer

![Version](https://img.shields.io/badge/version-2.0.1-green.svg)  
![License](https://img.shields.io/badge/License-GPLv3-blue.svg)  
![OS Support](https://img.shields.io/badge/OS-Debian%2011%20%7C%2012%20%7C%2013%20%7C%20Ubuntu%2022.04%20%7C%2024.04-red.svg)  
![Platform](https://img.shields.io/badge/Platform-BIOS%20%7C%20UEFI-orange.svg)  
![Language](https://img.shields.io/badge/language-bash-black.svg)

High-performance automated Linux reinstall tool for VPS and bare-metal servers.

AutoLinux is a unified Linux reinstall script focused on predictable behavior, fast execution, and practical compatibility across common VPS and server environments.

It supports both Debian and Ubuntu, works with legacy BIOS and modern UEFI systems, and is designed for operators who prefer a reinstall workflow that is transparent, deterministic, and field-tested.

AutoLinux follows an IPv4-first deployment model, with best-effort IPv6 restoration when valid IPv6 parameters can already be detected from the source system.

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
Default Credentials  
Tested Environments  
Operational Notes  
Security Notes  
Design Philosophy  
License  

---

# Overview

AutoLinux solves a common operational challenge: reliably reinstalling Linux servers across heterogeneous environments without relying on provider rescue systems.

Typical use cases include:

• VPS operating system reinstallation  
• migrating legacy distributions to modern Debian or Ubuntu  
• rebuilding servers without rescue images  
• automated infrastructure recovery  
• rapid server reprovisioning  

The script prioritizes deterministic behavior and avoids complex environment assumptions whenever possible.

---

# ⚡ Quick Start

Run as root.

Default installation (Debian 12):

bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh)

Install Debian 13 with custom SSH port and password:

bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh) -d 13 -p "YourPassword" --port 2222

Install Ubuntu 24.04:

bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh) -u 24

Install Ubuntu 22.04:

bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh) -u 22

---

⚠ DATA LOSS WARNING

This script will completely erase the primary system disk and reinstall the operating system.

All existing partitions, filesystems, and data will be permanently destroyed.

Use with caution.

---

# ✨ Key Features

Unified Debian and Ubuntu Installer

AutoLinux supports both Debian and Ubuntu installations through a single script interface.

Debian installations use the official Debian network installer, while Ubuntu installations use official Ubuntu cloud images for high-speed deployment.

---

BIOS and UEFI Compatibility

AutoLinux works in both legacy BIOS and modern UEFI environments.

Bootloader handling is automatically managed depending on the detected system environment.

---

Cross-Distribution Launcher

AutoLinux can be executed from many Linux distributions including:

Debian  
Ubuntu  
CentOS 7  
AlmaLinux  
Rocky Linux  
Fedora  

This allows reinstalling servers without requiring the source system to already run Debian or Ubuntu.

---

Official Upstream Sources

All installation assets are fetched directly from official upstream sources.

Debian components come from Debian infrastructure.

Ubuntu images come from the official Ubuntu cloud image servers.

No modified images or third-party mirrors are used.

---

Lightweight Hardware Detection

Before installation begins, AutoLinux automatically detects:

• primary non-removable system disk  
• active network interface  
• IPv4 address and prefix  
• default gateway  

If disk detection fails, the installer falls back to /dev/sda with a short abort window.

This detection model is intentionally simple and optimized for common VPS environments.

---

Deterministic Debian Installer Handoff

For Debian targets, AutoLinux performs:

1. download Debian netboot installer  
2. inject automated preseed configuration  
3. inject post-install configuration script  
4. create temporary GRUB boot entry  
5. reboot directly into the installer  

This provides a fully automated installation process using the official Debian installer.

---

High-Speed Ubuntu Deployment

Ubuntu installations avoid the traditional installer.

Instead, AutoLinux:

• downloads the official Ubuntu cloud image  
• attaches the image via qemu-nbd  
• mounts and modifies the filesystem offline  
• injects configuration directly  
• writes the prepared image to disk  

This approach significantly reduces deployment time.

---

Automatic SSH Configuration

AutoLinux ensures remote access after installation by enabling:

• root login  
• password authentication  
• configurable SSH port  

This design minimizes the risk of lockouts during automated reinstalls.

---

Network Performance Optimization

AutoLinux automatically enables modern TCP tuning:

• FQ queue discipline  
• TCP BBR congestion control  

These settings are widely used in high-performance networking environments.

---

Best-Effort IPv6 Restoration

AutoLinux does not automatically generate IPv6 configurations.

Instead, it restores IPv6 only when valid parameters already exist on the source system.

If IPv6 address, prefix, and gateway are detectable, the configuration will be restored in the installed system.

Otherwise the installer falls back to IPv4-only networking.

---

Legacy System Compatibility

AutoLinux detects certain end-of-life systems such as CentOS 7 and automatically enables Vault repositories to ensure required packages remain installable.

---

# 📂 Supported Operating Systems

Target Installation Systems

Debian

Debian 13 (Trixie)  
Debian 12 (Bookworm) — Default  
Debian 11 (Bullseye)

Ubuntu

Ubuntu 24.04 LTS (Noble) — Default  
Ubuntu 22.04 LTS (Jammy)

---

Supported Source Systems

The script can be launched from:

Debian  
Ubuntu  
CentOS 7  
AlmaLinux  
Rocky Linux  
Fedora  

---

# 🏗 Installation Architecture

AutoLinux uses different installation strategies depending on the target operating system.

---

Debian Installation Path

Debian installations use the official Debian network installer.

Process:

1. download official netboot installer  
2. inject automated preseed configuration  
3. inject post-install configuration script  
4. create temporary GRUB boot entry  
5. reboot into the installer  
6. perform automated installation  

This preserves Debian’s standard installer workflow while enabling full automation.

---

Ubuntu Installation Path

Ubuntu installations use official cloud images.

Process:

1. download Ubuntu cloud image  
2. attach image using qemu-nbd  
3. mount filesystem offline  
4. inject configuration and network settings  
5. seed cloud-init metadata  
6. write image directly to target disk  

This approach dramatically reduces installation time.

---

# 🌐 Network Provisioning Model

AutoLinux uses a deterministic network configuration strategy.

Deployment behavior:

IPv4 is always provisioned using static configuration.

IPv6 is restored only when valid parameters already exist.

Network logic:

Host network detected  
→ configure static IPv4

IPv6 detected  
→ attempt IPv6 restoration

IPv6 not detected  
→ IPv4-only configuration

This design prevents misconfigured IPv6 networking in environments where providers manage routing externally.

---

# 🔄 Installation Flow

Current Linux System  
↓  
AutoLinux Script Execution  
↓  
Detect Disk and Network  
↓  
Select Target OS  
↓  

Debian path → Netboot installer  
Ubuntu path → Cloud image deployment  

↓  
Automated system setup  
↓  
Reboot into installed system

---

# 🛠 Advanced Parameters

-d [11|12|13]  
Install Debian with specified version.

-u [22|24]  
Install Ubuntu with specified version.

-p password  
Set root password.

-port or --port N  
Set SSH port.

-h or --help  
Show help message.

Example:

bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh) -u 24 -p "SecurePassword" --port 2222

---

# 🔐 Default Credentials

If no parameters are provided, AutoLinux uses:

OS: Debian 12  
Username: root  
Password: Harry888  
SSH Port: 22

You should change the password immediately after login.

---

# 🧪 Tested Environments

AutoLinux has been validated in typical server and VPS environments including:

KVM virtual machines  
common cloud VPS providers  
single-disk virtual servers  
BIOS and UEFI boot environments  
IPv4-only VPS networks  
dual-stack VPS networks  

The script is primarily optimized for single-disk VPS deployments.

---

# 📌 Operational Notes

AutoLinux is designed around common VPS assumptions:

• single primary system disk  
• one active primary network interface  
• IPv4 connectivity available during installation  

While the script may function in more complex environments, such configurations are outside the primary design scope.

Operators deploying on multi-disk or complex networking setups should review disk and network detection behavior before use.

---

# 🔒 Security Notes

AutoLinux enables root login and password authentication to avoid SSH lockouts during automated reinstall operations.

After installation it is recommended to:

• change the root password  
• configure SSH key authentication  
• disable password authentication if appropriate  
• restrict SSH access using firewall rules  

---

# 🏆 Design Philosophy

AutoLinux is not designed to be clever — it is designed to be reliable.

The project prioritizes:

deterministic behavior  
transparent execution  
broad VPS compatibility  
minimal environmental assumptions  
predictable installation flow  

It intentionally avoids:

hidden automation  
distribution-specific hacks  
overly complex environment detection  
unverified heuristics  

The goal is simple:

A Linux reinstall process that operators can understand, trust, and run anywhere.

---

# ⚖ License

Author: Harry

Project repository:

https://github.com/harryheros/LinuxTools

Licensed under the GNU General Public License v3.0 (GPLv3).

You are free to use, modify, and redistribute this project under the GPLv3 license, provided that derivative works retain attribution and remain open-sourced under the same license.
