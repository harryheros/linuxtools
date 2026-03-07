#!/usr/bin/env bash
# ==============================================================================
# Project: AutoLinux - Unified Linux Auto-Installer
# Version: 2.1.0
# Description: BIOS + UEFI compatible automated reinstall script for Debian
#              and Ubuntu. Debian uses preseed netboot; Ubuntu uses the
#              official live-server installer with autoinstall.
#
# Author: Harry / HarryLinux Tools
# License: GNU General Public License v3.0 (GPL-3.0)
# ==============================================================================

set -Eeuo pipefail

# --- Color and Formatting ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

# --- Defaults ---
OS_TYPE="debian"
RELEASE=""
SSH_PORT="22"
ROOT_PASS="Harry888"
VERSION="2.1.0"
DEFAULT_PASSWORD_USED=1
HOSTNAME_VALUE="autolinux"
DNS1="8.8.8.8"
DNS2="1.1.1.1"

WORKDIR="/var/tmp/autolinux"

# --- Helpers ---
die() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}Warning: $*${NC}" >&2
}

info() {
    echo -e "${CYAN}$*${NC}"
}

cleanup() {
    if mountpoint -q "${WORKDIR}/iso_mount" 2>/dev/null; then
        umount -lf "${WORKDIR}/iso_mount" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

require_root() {
    [ "$(id -u)" -eq 0 ] || die "Please run this script as root."
}

show_help() {
    echo -e "${CYAN}AutoLinux v${VERSION} - Unified Linux Auto-Installer${NC}"
    echo ""
    echo -e "${BOLD}Usage:${NC}"
    echo -e "  bash autolinux.sh [options]"
    echo ""
    echo -e "${BOLD}Options:${NC}"
    echo -e "  ${YELLOW}-d [11|12|13]${NC}       Install Debian (default: 12)"
    echo -e "  ${YELLOW}-u [22|24]${NC}           Install Ubuntu (default: 24)"
    echo -e "  ${YELLOW}-p password${NC}          Set root password (default: Harry888)"
    echo -e "  ${YELLOW}-port / --port N${NC}     Set SSH port (default: 22)"
    echo -e "  ${YELLOW}-h / --help${NC}          Show this help"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo -e "  bash autolinux.sh                  # Debian 12"
    echo -e "  bash autolinux.sh -d 13            # Debian 13"
    echo -e "  bash autolinux.sh -u               # Ubuntu 24.04"
    echo -e "  bash autolinux.sh -u 22            # Ubuntu 22.04"
    echo -e "  bash autolinux.sh -u 24 -p mypass --port 2222"
}

# --- Argument Parsing ---
DEBIAN_SET=0
UBUNTU_SET=0

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -d)
            if [ "$UBUNTU_SET" -eq 1 ]; then
                die "Cannot use -d and -u together."
            fi
            DEBIAN_SET=1
            OS_TYPE="debian"
            if [[ "${2:-}" =~ ^(11|12|13)$ ]]; then
                RELEASE="$2"
                shift 2
            elif [[ -z "${2:-}" || "${2:-}" == -* ]]; then
                RELEASE="12"
                shift 1
            else
                die "Unsupported Debian version '${2:-}'. Available: 11, 12, 13."
            fi
            ;;
        -u)
            if [ "$DEBIAN_SET" -eq 1 ]; then
                die "Cannot use -d and -u together."
            fi
            UBUNTU_SET=1
            OS_TYPE="ubuntu"
            if [[ "${2:-}" =~ ^(22|24)$ ]]; then
                RELEASE="$2"
                shift 2
            elif [[ -z "${2:-}" || "${2:-}" == -* ]]; then
                RELEASE="24"
                shift 1
            else
                die "Unsupported Ubuntu version '${2:-}'. Available: 22, 24."
            fi
            ;;
        -p)
            [ -n "${2:-}" ] || die "Password cannot be empty."
            ROOT_PASS="$2"
            DEFAULT_PASSWORD_USED=0
            shift 2
            ;;
        -port|--port)
            if [[ "${2:-}" =~ ^[0-9]+$ ]] && [ "$2" -ge 1 ] && [ "$2" -le 65535 ]; then
                SSH_PORT="$2"
                shift 2
            else
                die "Invalid port number '${2:-}' (1-65535)."
            fi
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            die "Invalid option '$1'"
            ;;
    esac
done

# --- Apply defaults ---
if [ "$OS_TYPE" = "debian" ] && [ -z "$RELEASE" ]; then
    RELEASE="12"
fi
if [ "$OS_TYPE" = "ubuntu" ] && [ -z "$RELEASE" ]; then
    RELEASE="24"
fi

require_root

clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}            AutoLinux Unified Installer v${VERSION}${NC}"
echo -e "${GREEN}                Copyright (C) 2026 HarryLinux Tools${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "\n${BOLD}${CYAN}Step: Pre-installing essential tools...${NC}"

export DEBIAN_FRONTEND=noninteractive

IS_CENTOS7=0
if [ -f /etc/centos-release ] && grep -q "CentOS Linux release 7" /etc/centos-release; then
    IS_CENTOS7=1
    warn "CentOS 7 detected (EOL). Enabling Vault 7.9.2009 repo..."

    cat >/etc/yum.repos.d/autolinux-vault-7.9.2009.repo <<'EOF'
[autolinux-vault-base]
name=AutoLinux Vault 7.9.2009 - Base
baseurl=http://vault.centos.org/7.9.2009/os/$basearch/
enabled=1
gpgcheck=0

[autolinux-vault-updates]
name=AutoLinux Vault 7.9.2009 - Updates
baseurl=http://vault.centos.org/7.9.2009/updates/$basearch/
enabled=1
gpgcheck=0

[autolinux-vault-extras]
name=AutoLinux Vault 7.9.2009 - Extras
baseurl=http://vault.centos.org/7.9.2009/extras/$basearch/
enabled=1
gpgcheck=0
EOF

    yum clean all >/dev/null 2>&1 || true
fi

if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y \
        util-linux wget curl ca-certificates openssl \
        kexec-tools tar gzip cpio grub2-common \
        python3 python3-yaml xz-utils

elif command -v dnf >/dev/null 2>&1; then
    dnf install -y \
        util-linux wget curl ca-certificates openssl \
        kexec-tools tar gzip cpio grub2 grub2-tools \
        python3 python3-pyyaml xz
    [ ! -f /usr/sbin/grub-probe ] && [ -f /usr/sbin/grub2-probe ] && ln -sf /usr/sbin/grub2-probe /usr/sbin/grub-probe

elif command -v yum >/dev/null 2>&1; then
    if [ "$IS_CENTOS7" -eq 1 ]; then
        yum --disablerepo="*" --enablerepo="autolinux-vault-*" install -y \
            util-linux wget curl ca-certificates openssl \
            kexec-tools tar gzip cpio grub2 grub2-tools \
            python3 xz
    else
        yum install -y \
            util-linux wget curl ca-certificates openssl \
            kexec-tools tar gzip cpio grub2 grub2-tools \
            python3 xz
    fi
    [ ! -f /usr/sbin/grub-probe ] && [ -f /usr/sbin/grub2-probe ] && ln -sf /usr/sbin/grub2-probe /usr/sbin/grub-probe

else
    die "Package manager not found."
fi

echo -e "\n${BOLD}${CYAN}Step: Detecting environment and network...${NC}"

detect_root_disk() {
    local root_src pkname candidate

    root_src="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
    if [ -n "$root_src" ]; then
        pkname="$(lsblk -no PKNAME "$root_src" 2>/dev/null | head -n1 || true)"
        if [ -n "$pkname" ]; then
            echo "/dev/$pkname"
            return 0
        fi
    fi

    candidate="$(lsblk -dpno NAME,TYPE | awk '$2=="disk"{print $1; exit}' || true)"
    if [ -n "$candidate" ]; then
        echo "$candidate"
        return 0
    fi

    return 1
}

REAL_DISK="$(detect_root_disk || true)"
if [ -z "${REAL_DISK:-}" ]; then
    REAL_DISK="/dev/sda"
    warn "Disk auto-detection failed, defaulting to /dev/sda"
    warn "If this is wrong, press Ctrl+C within 10 seconds to abort."
    sleep 10
fi

INTERFACE="$(ip route | awk '/default/ {print $5; exit}')"
[ -n "${INTERFACE:-}" ] || die "Could not detect default network interface."

V_IP="$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)"
V_PREFIX="$(ip -4 addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d/ -f2 | head -n1)"
V_GATEWAY="$(ip route | awk '/default/ {print $3; exit}')"

[ -n "${V_IP:-}" ] || die "Could not detect IPv4 address."
[ -n "${V_PREFIX:-}" ] || die "Could not detect IPv4 prefix."
[ -n "${V_GATEWAY:-}" ] || die "Could not detect default gateway."

prefix_to_mask() {
    local prefix="$1"
    local full_octets=$((prefix / 8))
    local partial_octet=$((prefix % 8))
    local mask=""
    local i

    for ((i=0; i<4; i++)); do
        if [ "$i" -lt "$full_octets" ]; then
            mask+="255"
        elif [ "$i" -eq "$full_octets" ] && [ "$partial_octet" -ne 0 ]; then
            mask+=$((256 - 2**(8-partial_octet)))
        else
            mask+="0"
        fi
        [ "$i" -lt 3 ] && mask+="."
    done
    echo "$mask"
}
V_NETMASK="$(prefix_to_mask "$V_PREFIX")"

if [ "$OS_TYPE" = "debian" ]; then
    case "$RELEASE" in
        11) REL_NAME="bullseye" ;;
        12) REL_NAME="bookworm" ;;
        13) REL_NAME="trixie" ;;
        *) die "Unsupported Debian release '${RELEASE}'." ;;
    esac
    DISPLAY_NAME="Debian ${RELEASE} (${REL_NAME})"
else
    case "$RELEASE" in
        22) REL_NAME="jammy"; FULL_VER="22.04" ;;
        24) REL_NAME="noble"; FULL_VER="24.04" ;;
        *) die "Unsupported Ubuntu release '${RELEASE}'." ;;
    esac
    DISPLAY_NAME="Ubuntu ${FULL_VER} (${REL_NAME})"
fi

echo -e "      Target OS : ${YELLOW}${DISPLAY_NAME}${NC}"
echo -e "      Root Disk : ${YELLOW}${REAL_DISK}${NC}"
echo -e "      Interface : ${YELLOW}${INTERFACE}${NC}"
echo -e "      IP Config : ${YELLOW}${V_IP} / ${V_NETMASK}${NC}"
echo -e "      Gateway   : ${YELLOW}${V_GATEWAY}${NC}"
echo -e "      SSH Port  : ${YELLOW}${SSH_PORT}${NC}"

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# ==============================================================================
# DEBIAN INSTALLATION PATH
# ==============================================================================
install_debian() {
    echo -e "\n${BOLD}${CYAN}Step: Fetching Debian network installer...${NC}"

    local mirror kernel_append net_append
    mirror="https://deb.debian.org/debian/dists/${REL_NAME}/main/installer-amd64/current/images/netboot/"
    wget -O "${WORKDIR}/netboot.tar.gz" "${mirror}netboot.tar.gz"

    cat > "${WORKDIR}/post-install.sh" <<EOF
#!/bin/sh
set -eu

sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
grep -q '^PermitRootLogin yes$' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
grep -q '^PasswordAuthentication yes$' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

if grep -q '^#\\?Port ' /etc/ssh/sshd_config; then
    sed -i 's/^#\\?Port .*/Port ${SSH_PORT}/' /etc/ssh/sshd_config
else
    echo 'Port ${SSH_PORT}' >> /etc/ssh/sshd_config
fi

grep -q '^net.core.default_qdisc=fq$' /etc/sysctl.conf || echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
grep -q '^net.ipv4.tcp_congestion_control=bbr$' /etc/sysctl.conf || echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf

cat > /etc/network/interfaces <<NETEOF
auto lo
iface lo inet loopback

allow-hotplug ${INTERFACE}
auto ${INTERFACE}
iface ${INTERFACE} inet static
    address ${V_IP}
    netmask ${V_NETMASK}
    gateway ${V_GATEWAY}
    dns-nameservers ${DNS1} ${DNS2}
NETEOF
EOF
    chmod +x "${WORKDIR}/post-install.sh"

    cat > "${WORKDIR}/preseed.cfg" <<EOF
d-i debconf/priority string critical
d-i auto-install/enable boolean true
d-i debian-installer/locale string en_US.UTF-8
d-i console-setup/ask_detect boolean false
d-i keyboard-configuration/xkb-keymap select us

d-i netcfg/choose_interface select ${INTERFACE}
d-i netcfg/disable_autoconfig boolean true
d-i netcfg/get_ipaddress string ${V_IP}
d-i netcfg/get_netmask string ${V_NETMASK}
d-i netcfg/get_gateway string ${V_GATEWAY}
d-i netcfg/get_nameservers string ${DNS1} ${DNS2}
d-i netcfg/confirm_static boolean true
d-i netcfg/get_hostname string ${HOSTNAME_VALUE}
d-i netcfg/get_domain string local

d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

tasksel tasksel/first multiselect standard, ssh-server

d-i partman-auto/disk string ${REAL_DISK}
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean false
d-i grub-installer/bootdev string ${REAL_DISK}

d-i passwd/make-user boolean false
d-i passwd/root-password password ${ROOT_PASS}
d-i passwd/root-password-again password ${ROOT_PASS}

d-i clock-setup/utc boolean true
d-i time/zone string UTC

d-i finish-install/reboot_in_progress note

d-i preseed/late_command string \
    cp /post-install.sh /target/root/post-install.sh; \
    chmod +x /target/root/post-install.sh; \
    in-target /bin/sh /root/post-install.sh
EOF

    cd "$WORKDIR"
    tar -xzf netboot.tar.gz

    mkdir -p initrd_work
    cd initrd_work
    gzip -dc "../debian-installer/amd64/initrd.gz" | cpio -idmu >/dev/null 2>&1

    cp "${WORKDIR}/preseed.cfg" ./preseed.cfg
    cp "${WORKDIR}/post-install.sh" ./post-install.sh

    rm -f /boot/vmlinuz-*autolinux /boot/initrd-*autolinux* 2>/dev/null || true
    find . | cpio -H newc -o 2>/dev/null | gzip -1 > "/boot/initrd-debian${RELEASE}-autolinux.gz"
    cp "${WORKDIR}/debian-installer/amd64/linux" "/boot/vmlinuz-debian${RELEASE}-autolinux"

    KERNEL_PATH="/boot/vmlinuz-debian${RELEASE}-autolinux"
    INITRD_PATH="/boot/initrd-debian${RELEASE}-autolinux.gz"

    net_append="netcfg/choose_interface=${INTERFACE} netcfg/disable_autoconfig=true netcfg/get_ipaddress=${V_IP} netcfg/get_netmask=${V_NETMASK} netcfg/get_gateway=${V_GATEWAY} netcfg/get_nameservers=${DNS1} ${DNS2} netcfg/confirm_static=true"
    kernel_append="auto=true priority=critical file=/preseed.cfg locale=en_US.UTF-8 keyboard-configuration/xkb-keymap=us hostname=${HOSTNAME_VALUE} ${net_append} vga=788 --- quiet"

    KERNEL_APPEND="$kernel_append"
    GRUB_TITLE="AutoLinux-Debian${RELEASE}"
}

# ==============================================================================
# UBUNTU INSTALLATION PATH
# ==============================================================================
install_ubuntu() {
    echo -e "\n${BOLD}${CYAN}Step: Preparing Ubuntu live-server autoinstall...${NC}"

    local mirror iso_file iso_url hashed_pass
    mirror="https://releases.ubuntu.com/${REL_NAME}/"

    info "Resolving latest Ubuntu ${FULL_VER} ISO filename..."
    iso_file="$(wget -qO- "${mirror}SHA256SUMS" | grep -oE "ubuntu-${FULL_VER}\.[0-9]+-live-server-amd64\.iso" | sort -V | tail -n1 || true)"
    [ -n "${iso_file:-}" ] || die "Could not resolve Ubuntu ${FULL_VER} ISO filename from ${mirror}SHA256SUMS"

    info "Latest ISO: ${iso_file}"
    iso_url="${mirror}${iso_file}"

    wget -O "${WORKDIR}/${iso_file}" "${iso_url}"

    mkdir -p "${WORKDIR}/iso_mount"
    mount -o loop,ro "${WORKDIR}/${iso_file}" "${WORKDIR}/iso_mount"

    [ -f "${WORKDIR}/iso_mount/casper/vmlinuz" ] || die "Missing casper/vmlinuz in ISO."
    [ -f "${WORKDIR}/iso_mount/casper/initrd" ] || die "Missing casper/initrd in ISO."

    hashed_pass="$(openssl passwd -6 "${ROOT_PASS}")"

    cat > "${WORKDIR}/autoinstall.yaml" <<EOF
autoinstall:
  version: 1
  locale: en_US.UTF-8

  keyboard:
    layout: us

  ssh:
    install-server: true
    allow-pw: true

  identity:
    hostname: ${HOSTNAME_VALUE}
    username: admin
    password: "${hashed_pass}"

  storage:
    layout:
      name: direct

  network:
    version: 2
    ethernets:
      ${INTERFACE}:
        dhcp4: false
        addresses:
          - ${V_IP}/${V_PREFIX}
        routes:
          - to: default
            via: ${V_GATEWAY}
        nameservers:
          addresses:
            - ${DNS1}
            - ${DNS2}

  late-commands:
    - curtin in-target -- bash -c "echo 'root:${ROOT_PASS}' | chpasswd"
    - curtin in-target -- passwd -u root || true

    - curtin in-target -- sed -ri 's/^[#[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    - curtin in-target -- grep -q '^PermitRootLogin yes$' /etc/ssh/sshd_config || echo 'PermitRootLogin yes' >> /target/etc/ssh/sshd_config

    - curtin in-target -- sed -ri 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    - curtin in-target -- grep -q '^PasswordAuthentication yes$' /etc/ssh/sshd_config || echo 'PasswordAuthentication yes' >> /target/etc/ssh/sshd_config

    - curtin in-target -- bash -c "grep -q '^Port ${SSH_PORT}$' /etc/ssh/sshd_config && sed -ri 's/^Port .*/Port ${SSH_PORT}/' /etc/ssh/sshd_config || echo 'Port ${SSH_PORT}' >> /etc/ssh/sshd_config"

    - curtin in-target -- bash -c "grep -q '^net.core.default_qdisc=fq$' /etc/sysctl.conf || echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf"
    - curtin in-target -- bash -c "grep -q '^net.ipv4.tcp_congestion_control=bbr$' /etc/sysctl.conf || echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf"
EOF

    mkdir -p "${WORKDIR}/initrd_repack"
    cd "${WORKDIR}/initrd_repack"

    # Extract original initrd without patching casper.
    if command -v unmkinitramfs >/dev/null 2>&1; then
        if ! unmkinitramfs "${WORKDIR}/iso_mount/casper/initrd" . >/dev/null 2>&1; then
            gzip -dc "${WORKDIR}/iso_mount/casper/initrd" | cpio -idmu >/dev/null 2>&1
        fi
    else
        gzip -dc "${WORKDIR}/iso_mount/casper/initrd" | cpio -idmu >/dev/null 2>&1
    fi

    # Inject autoinstall config into installer root.
    cp "${WORKDIR}/autoinstall.yaml" ./autoinstall.yaml

    rm -f /boot/vmlinuz-*autolinux /boot/initrd-*autolinux* 2>/dev/null || true
    find . | cpio -H newc -o 2>/dev/null | gzip -9 > "/boot/initrd-ubuntu${RELEASE}-autolinux.gz"
    cp "${WORKDIR}/iso_mount/casper/vmlinuz" "/boot/vmlinuz-ubuntu${RELEASE}-autolinux"

    umount -lf "${WORKDIR}/iso_mount" >/dev/null 2>&1 || true

    KERNEL_PATH="/boot/vmlinuz-ubuntu${RELEASE}-autolinux"
    INITRD_PATH="/boot/initrd-ubuntu${RELEASE}-autolinux.gz"

    # Official live-server installer still needs url=<ISO>.
    # autoinstall.yaml is provided from installer root via subiquity.autoinstallpath.
    KERNEL_APPEND="root=/dev/ram0 ramdisk_size=1500000 ip=${V_IP}::${V_GATEWAY}:${V_NETMASK}:${HOSTNAME_VALUE}:${INTERFACE}:none:${DNS1}:${DNS2} url=${iso_url} autoinstall subiquity.autoinstallpath=/autoinstall.yaml cloud-config-url=/dev/null fsck.mode=skip ---"
    GRUB_TITLE="AutoLinux-Ubuntu${RELEASE}"
}

# --- Run installer path ---
if [ "$OS_TYPE" = "debian" ]; then
    install_debian
else
    install_ubuntu
fi

# ==============================================================================
# GRUB CONFIGURATION
# ==============================================================================
echo -e "\n${BOLD}${CYAN}Step: Patching GRUB bootloader...${NC}"

BOOT_UUID="$(
    /usr/sbin/grub-probe --target=fs_uuid /boot 2>/dev/null \
    || grub-probe --target=fs_uuid /boot 2>/dev/null \
    || true
)"
[ -n "${BOOT_UUID:-}" ] || die "Could not determine /boot filesystem UUID."

cat > /etc/grub.d/40_custom <<EOF
#!/bin/sh
exec tail -n +3 \$0

menuentry '${GRUB_TITLE}' --class gnu-linux {
    load_video
    insmod all_video
    insmod gzio
    insmod part_gpt
    insmod part_msdos
    insmod ext2
    search --no-floppy --fs-uuid --set=root ${BOOT_UUID}
    if [ -f ${KERNEL_PATH} ]; then
        linux ${KERNEL_PATH} ${KERNEL_APPEND}
        initrd ${INITRD_PATH}
    else
        linux ${KERNEL_PATH##/boot} ${KERNEL_APPEND}
        initrd ${INITRD_PATH##/boot}
    fi
}
EOF
chmod +x /etc/grub.d/40_custom

if grep -q '^GRUB_DEFAULT=' /etc/default/grub 2>/dev/null; then
    sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"${GRUB_TITLE}\"|" /etc/default/grub
else
    echo "GRUB_DEFAULT=\"${GRUB_TITLE}\"" >> /etc/default/grub
fi

if grep -q '^GRUB_TIMEOUT=' /etc/default/grub 2>/dev/null; then
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
else
    echo 'GRUB_TIMEOUT=3' >> /etc/default/grub
fi

sed -i '/^GRUB_DISABLE_OS_PROBER=/d' /etc/default/grub || true
echo 'GRUB_DISABLE_OS_PROBER=true' >> /etc/default/grub

echo -e "\n${BOLD}${CYAN}Step: Updating GRUB configuration...${NC}"
if command -v update-grub >/dev/null 2>&1; then
    update-grub
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    GRUB_CFG_PATH="$(find /boot/grub2 /boot/grub /etc -name grub.cfg 2>/dev/null | head -n1 || true)"
    [ -n "${GRUB_CFG_PATH:-}" ] || GRUB_CFG_PATH="/boot/grub2/grub.cfg"
    grub2-mkconfig -o "$GRUB_CFG_PATH"
else
    die "Could not find update-grub or grub2-mkconfig."
fi

echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[✔] Ready! (v${VERSION})${NC}  Target: ${CYAN}${DISPLAY_NAME}${NC}"
echo -e "    Disk     : ${YELLOW}${REAL_DISK}${NC}"
echo -e "    IP       : ${YELLOW}${V_IP}${NC}"
echo -e "    SSH Port : ${YELLOW}${SSH_PORT}${NC}"

if [ "$DEFAULT_PASSWORD_USED" -eq 1 ]; then
    echo -e "\n${YELLOW}Default root password is being used. Change it after first login.${NC}"
fi

echo -e "${RED}${BOLD}The system will reboot and start the unattended installer.${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -ne "\nRebooting in "
for i in {10..1}; do
    echo -n "$i... "
    sleep 1
done
echo -e "\n${RED}${BOLD}Rebooting now!${NC}"

sync
reboot -f
