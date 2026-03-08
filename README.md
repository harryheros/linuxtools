# 🚀 AutoLinux v2.0.1 — Unified Linux Auto Installer

[![Version](https://img.shields.io/badge/version-2.0.1-green.svg)](#)  
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)  
[![OS Support](https://img.shields.io/badge/OS-Debian%2011%20%7C%2012%20%7C%2013%20%7C%20Ubuntu%2022.04%20%7C%2024.04-red.svg)](#)  
[![Platform](https://img.shields.io/badge/Platform-BIOS%20%7C%20UEFI-orange.svg)](#)

**High-performance automated Linux reinstall tool for VPS and bare-metal servers.**

AutoLinux provides a unified installation workflow for Debian and Ubuntu, supports both legacy BIOS and modern UEFI environments, and focuses on deterministic behavior with minimal environmental assumptions.

It is built for operators who want a reinstall process that is predictable, transparent, fast, and portable across common hosting environments.

AutoLinux follows an **IPv4-first deterministic deployment model**, with **best-effort IPv6 restoration** when valid IPv6 parameters are already detectable on the source system.

---

# 📑 Table of Contents

- Overview
- Quick Start
- Key Features
- Supported Operating Systems
- Installation Architecture
- Network Provisioning Model
- Installation Flow
- Advanced Parameters
- Default Credentials
- Notes
- Security Notes
- Design Philosophy
- License

---

# Overview

AutoLinux is built to solve a common operational problem: reliably reinstalling Linux servers across heterogeneous hosting environments.

Typical use cases include:

- VPS operating system reinstallation
- migrating legacy distributions to modern Debian or Ubuntu
- rebuilding servers without rescue images
- automated infrastructure recovery
- clean system reprovisioning

The tool is intentionally designed to avoid unnecessary complexity and to prioritize predictable behavior over automation magic.

---

# 🛠 Quick Start

Run as root.

## Default Installation

Installs Debian 12 with SSH port 22 and the default root password.

    bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh)

## Install Debian

Example: Install Debian 13 with a custom password and SSH port.

    bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh) -d 13 -p "YourPassword" --port 7777

## Install Ubuntu

Example: Install Ubuntu 24.04.

    bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh) -u 24

## Default Version Behavior

- `-d` without a version defaults to Debian 12
- `-u` without a version defaults to Ubuntu 24.04

⚠ DATA LOSS WARNING

This script will completely erase the primary system disk and reinstall the operating system.

All existing partitions and data will be permanently destroyed.

---

# ✨ Key Features

## Unified Debian + Ubuntu Installer

AutoLinux supports both Debian and Ubuntu installations through a single script.

Debian installations use the official Debian network installer, while Ubuntu installations use official Ubuntu cloud images for fast deployment.

---

## BIOS + UEFI Compatibility

AutoLinux supports:

- legacy BIOS servers
- modern UEFI systems
- VPS environments with mixed boot configurations

Bootloader handling is deterministic and handled automatically.

---

## Cross-Distribution Launcher

AutoLinux can be executed from many Linux distributions including:

- Debian
- Ubuntu
- CentOS 7
- AlmaLinux
- Rocky Linux
- Fedora

This allows reinstalling a server without requiring the source system to already run Debian or Ubuntu.

---

## Official Upstream Sources

All installation assets are fetched directly from official upstream sources.

Debian installer components are downloaded from Debian infrastructure.

Ubuntu images are downloaded from the official Ubuntu cloud image servers.

No third-party mirrors or modified images are used.

---

## Lightweight Hardware Detection

Before installation begins, AutoLinux detects:

- the primary non-removable system disk
- the active network interface
- IPv4 address and prefix
- default gateway

If disk detection fails, the installer falls back to `/dev/sda` with a short abort window.

This detection model is intentionally simple and optimized for common VPS environments.

---

## Deterministic Debian Installer Handoff

For Debian targets, AutoLinux performs:

- netboot installer download
- automated preseed injection
- post-install configuration script injection
- creation of a temporary GRUB boot entry
- direct reboot into the installer

This ensures a fully automated and reproducible installation flow.

---

## High-Speed Ubuntu Deployment

Ubuntu installations avoid the traditional installer entirely.

Instead, AutoLinux:

- downloads the official Ubuntu cloud image
- attaches it using qemu-nbd
- mounts and modifies the filesystem offline
- writes the prepared image directly to disk

This approach is significantly faster than traditional network installers.

---

## Automatic SSH Configuration

After installation, AutoLinux ensures remote access by enabling:

- root login
- password authentication
- configurable SSH port

Ubuntu deployments additionally write an override configuration to guarantee consistent SSH behavior.

---

## Native Network Performance Optimization

AutoLinux enables modern TCP tuning automatically:

- FQ queue discipline
- TCP BBR congestion control

These settings are widely used in high-performance network environments.

---

## Best-Effort IPv6 Restoration

AutoLinux does not automatically provision IPv6 networking.

Instead, it attempts to **restore IPv6 configuration when usable parameters already exist on the source system**.

If a global IPv6 address and usable routing information are detected, the installer carries this configuration into the installed system.

Implementation differs by target system:

- Debian uses `/etc/network/interfaces`
- Ubuntu uses `netplan`

If the required IPv6 parameters are incomplete or unavailable, AutoLinux automatically falls back to IPv4-only networking.

---

## Legacy System Compatibility

AutoLinux detects certain end-of-life systems such as CentOS 7 and automatically enables CentOS Vault repositories so required packages can still be installed.

This improves reliability when migrating older servers to modern distributions.

---

# 📂 Supported Operating Systems

## Target Installation Systems

### Debian

- Debian 13 (Trixie)
- Debian 12 (Bookworm) — Default
- Debian 11 (Bullseye)

### Ubuntu

- Ubuntu 24.04 LTS (Noble) — Default
- Ubuntu 22.04 LTS (Jammy)

## Supported Source Systems

The script can be launched from:

- Debian
- Ubuntu
- CentOS 7
- AlmaLinux
- Rocky Linux
- Fedora

---

# 🏗 Installation Architecture

AutoLinux uses different installation strategies depending on the target operating system.

## Debian Installation Path

Debian installations use the official Debian network installer.

Process:

1. download official netboot installer
2. inject automated preseed configuration
3. inject post-install configuration script
4. create temporary GRUB boot entry
5. reboot directly into installer
6. perform automated installation

This preserves Debian’s official installer behavior while enabling fully automated provisioning.

---

## Ubuntu Installation Path

Ubuntu installations use official Ubuntu cloud images.

Process:

1. download official Ubuntu cloud image
2. attach image using qemu-nbd
3. mount filesystem directly
4. inject configuration into filesystem
5. optionally inject IPv6 configuration when detectable
6. seed cloud-init metadata for disk expansion
7. write image directly to target disk

This approach removes the need for a traditional installer and dramatically reduces deployment time.

---

# 🌐 Network Provisioning Model

AutoLinux follows a deterministic network configuration model.

Deployment behavior:

- IPv4 is always provisioned using static configuration
- IPv6 is only restored when valid parameters already exist

Network logic:

    Host Network State
            │
            ▼
    IPv4 detected → static IPv4 provisioning
            │
            ▼
    IPv6 detected?
        │
        ├─ yes → attempt IPv6 restoration
        │
        └─ no → IPv4-only configuration

This design prevents incorrect IPv6 provisioning on environments where IPv6 routing is incomplete or provider-managed.

---

# 🔄 Installation Flow

    Current Linux System
            │
            ▼
    AutoLinux Script Execution
            │
            ▼
    Detect Disk and Network
            │
            ▼
    Select Target OS
            │
      ┌─────┴─────┐
      ▼           ▼
    Debian      Ubuntu
    Netboot     Cloud Image
    Installer   Deployment
      ▼           ▼
    Automated System Setup
            │
            ▼
    Reboot into Installed System

---

# 🛠 Advanced Parameters

- `-d [11|12|13]`  
  Install Debian with the specified version.

- `-u [22|24]`  
  Install Ubuntu with the specified version.

- `-p password`  
  Set root password.

- `-port / --port N`  
  Set SSH port (1–65535).

- `-h / --help`  
  Show help information.

Example:

    bash <(curl -sSL https://raw.githubusercontent.com/harryheros/LinuxTools/main/super/autolinux.sh) -u 24 -p "SecurePassword" --port 2222

---

# 🔐 Default Credentials

If no parameters are provided, AutoLinux uses:

| Property | Default |
|---|---|
| OS | Debian 12 |
| Username | root |
| Password | Harry888 |
| SSH Port | 22 |

You should change the password immediately after login.

---

# Notes

- Installation is IPv4-first across all targets.
- IPv6 configuration is restored only when valid parameters are detectable.
- Static DNS servers `8.8.8.8` and `1.1.1.1` are written into generated network configuration.
- Debian networking uses `/etc/network/interfaces`.
- Ubuntu networking uses `netplan`.
- Disk detection is optimized for common single-disk VPS environments.
- Ubuntu cloud-image deployments include automatic first-boot disk expansion commands.

---

# 🔒 Security Notes

AutoLinux enables root login and password authentication to prevent lockout during automated reinstalls.

After installation it is recommended to:

- change the root password
- configure SSH key authentication
- disable password authentication if appropriate
- restrict SSH exposure using firewall rules

---

# 🏆 Design Philosophy

AutoLinux is not designed to be clever — it is designed to be reliable.

The project prioritizes:

- deterministic behavior
- transparent execution
- broad VPS compatibility
- minimal assumptions
- predictable installation flow

It intentionally avoids:

- hidden automation
- distribution-specific hacks
- complex environment detection
- unnecessary abstraction

The goal is simple:

A Linux reinstall process that operators can understand, trust, and run anywhere.

---

# ⚖ License

Author: Harry

Project repository:

https://github.com/harryheros/LinuxTools

Licensed under the GNU General Public License v3.0 (GPLv3).

You are free to use, modify, and redistribute this project under the GPLv3 license, provided that derivative works retain attribution and remain open-sourced under the same license.
