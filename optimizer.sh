#!/bin/bash
#
# VPS OPtimizer Bash Script
# Author: github.com/opiran-club
#
# This script is designed to simplify the installation and configuration as a optimizer vps
# It provides options to install required packages, configure sysctl, ssh, swap.
# download the appropriate configuration and program.
#
# supported architectures: x86_64, amd64
# Supported operating systems: Ubuntu 18.04/20.04/22.04 , Debian 10/11, CentOS 7/8.
# Exceptions Ubuntu versions prior to 18.04 and Debian versions prior to 10 are untested.
#
# Usage:
#   - Run the script with root privileges.
#   - Follow the on-screen prompts to install, configure, or uninstall the tunnel.
#
# For more information and updates, visit github.com/opiran-club and @opiranclub on telegram.
#
# Disclaimer:
# This script comes with no warranties or guarantees. Use it at your own risk.

CYAN="\e[96m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
BLUE="\e[94m "
MAGENTA="\e[95m"
NC="\e[0m"

if [ "$EUID" -ne 0 ]; then
echo -e "\n ${RED}This script must be run as root.${NC}"
exit 1
fi

if [ -f /etc/os-release ]; then
    source /etc/os-release
    case $ID in
        "ubuntu")
        echo ""
        
        # Check the content of the sources.list
        if grep -q "archive.ubuntu.com" /etc/apt/sources.list; then
            echo -ne "${GREEN}Your sources.list is already using archive.ubuntu. Do you want to continue? [y/n]: ${NC}"
            read continue
            case $continue in
                [Yy])
                # Continue with the script
                ;;
                [Nn])
                return
                ;;
                *)
                return
                ;;
            esac
        else
            echo -ne "${GREEN}Do you want me to change your source list to archive.ubuntu? [y/n]: ${NC}"
            read source
            case $source in
                [Yy])
                rm -rf /etc/apt/sources.list && touch /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy main restricted" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy universe" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy-updates universe" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy multiverse" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy-updates multiverse" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy-security universe" >> /etc/apt/sources.list
                echo "deb http://archive.ubuntu.com/ubuntu/ jammy-security multiverse" >> /etc/apt/sources.list
                ;;
                [Nn])
                return
                ;;
                *)
                return
                ;;
            esac
        fi
        ;;
    esac
fi

press_enter() {
    echo -e "\n ${RED}Press Enter to continue... ${NC}"
    read
}

ask_reboot() {
echo ""
echo -e "\n ${YELLOW}Reboot now? (Recommended) ${GREEN}[y/n]${NC}"
echo ""
read reboot
case "$reboot" in
        [Yy]) 
        systemctl reboot
        ;;
        *) 
        return 
        ;;
    esac
exit
}

set_timezone() {
    clear
    title="Timezone Adjustment"
    logo
    echo ""
    echo -e "${CYAN}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 

    
    regions=("Asia/Tehran" "Europe/Istanbul" "America/Los_Angeles")
    
    additional_timezones=("Asia/Tokyo" "Europe/London" "Australia/Sydney")
    
    timezones=("${regions[@]}" "${additional_timezones[@]}")
    
    for ((i = 0; i < ${#timezones[@]}; i++)); do
        echo -e "${RED}$((i+1)). ${YELLOW}${timezones[i]}${NC}"
    done

    echo -e "${RED}$((i+1)). ${YELLOW}NO CHANGE TIMEZONE${NC}"
    echo ""
    echo -ne "${CYAN}Enter your choice [1-$((i+1))]:${NC} "
    read choice
    
    if [ "$choice" -ge 1 ] && [ "$choice" -le $((i+1)) ]; then
        if [ "$choice" -eq $((i+1)) ]; then
            echo -e "${RED}No changes made, press enter to continue optimization${NC}"
            press_enter
        else
            timezone="${timezones[choice-1]}"
            sudo timedatectl set-timezone $timezone
            echo ""
            echo -e "${YELLOW}Timezone has been set to ${GREEN}$timezone.${NC}"
            echo ""
            press_enter
        fi
    else
        echo -e "${RED}Invalid choice. No changes made.${NC}"
        press_enter
        return 1
    fi
}

logo=$(cat << "EOF"
    ______    _______   __      _______        __      _____  ___  
   /    " \  |   __ "\ |" \    /"      \      /""\    (\"   \|"  \ 
  // ____  \ (. |__) :)||  |  |:        |    /    \   |.\\   \    |
 /  /    ) :)|:  ____/ |:  |  |_____/   )   /' /\  \  |: \.   \\  |
(: (____/ // (|  /     |.  |   //      /   //  __'  \ |.  \    \. |
 \        / /|__/ \    /\  |\ |:  __   \  /   /  \\  \|    \    \ |
  \"_____/ (_______)  (__\_|_)|__|  \___)(___/    \___)\___|\____\)
EOF
)

logo() {
echo -e "\033[1;34m$logo\033[0m"
}

fix_dns() {
    clear
    DNS_PATH="/etc/resolv.conf"
    title="DNS replacement with Google"
    logo
    echo ""
    echo -e "${CYAN}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    spin() {
        local i
        for i in $(seq 1 30); do
            local c
            c=${SPINNER:i%${#SPINNER}:1}
            echo -ne "${RED}${c}${NC}"
            sleep 0.1
            echo -ne "\b"
        done
    }

    sed -i '/nameserver/d' $DNS_PATH
    echo 'nameserver 8.8.8.8' >>$DNS_PATH
    echo 'nameserver 8.8.4.4' >>$DNS_PATH
    spin & SPIN_PID=$!

    wait $SPIN_PID
    echo ""
    echo -e "${GREEN}System DNS Optimized.${NC}"
    echo ""
    sleep 1
    press_enter
}

complete_update() {
    clear
    title="Update and upgrade packages"
    logo
    echo ""
    echo -e "${CYAN}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    echo ""
    echo -e "${RED}Please wait, it might take a couple of minutes${NC}"
    echo ""
    echo ""
    
    SPINNER="░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"

    spin() {
        local i
        for i in $(seq 1 30); do
            local c
            c="${SPINNER:i%${#SPINNER}:1}"
            echo -ne "${GREEN}${SPINNER:0:i}${RED}${SPINNER:i}${NC}"
            sleep 0.1
            echo -ne "\r"
        done
    }

    spin & SPIN_PID=$!

    apt-get update > /dev/null 2>&1
    wait $SPIN_PID
    apt-get upgrade -y
    spin & SPIN_PID=$!
    apt-get dist-upgrade -y > /dev/null 2>&1
    apt-get autoremove -y > /dev/null 2>&1
    apt-get autoclean -y > /dev/null 2>&1
    apt-get clean -y
    wait $SPIN_PID
    echo ""
    echo -e "${GREEN}System update & upgrade completed.${NC}"
    echo ""
    sleep 1
    press_enter
}


installations() {
    clear
    title="Install necessary packages"
    logo
    echo ""
    echo -e "${CYAN}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n"
    echo ""
    echo -e "${RED}Please wait, it might take a while${NC}"
    echo ""

    SPINNER="░░░░░░░░░░░░░░░░░░░░░░░░░░░░░"

    spin() {
        local i
        for i in $(seq 1 30); do
            local c
            c="${SPINNER:i%${#SPINNER}:1}"
            echo -ne "${GREEN}${SPINNER:0:i}${RED}${SPINNER:i}${NC}"
            sleep 0.1
            echo -ne "\r"
        done
    }

    spin & SPIN_PID=$!

    apt-get purge firewalld -y > /dev/null 2>&1
    apt-get install certbot nload nethogs autossh ssh iperf sshuttle software-properties-common apt-transport-https iptables lsb-release ca-certificates ubuntu-keyring gnupg2 apt-utils cron bash-completion curl git unzip zip ufw wget preload locales nano vim python3 jq qrencode socat busybox net-tools haveged htop curl -y > /dev/null 2>&1

    wait $SPIN_PID
    apt-get install snapd -y > /dev/null 2>&1

    echo ""
    echo -e "${GREEN}Install useful and necessary packages completed.${NC}"
    echo ""
    sleep 1
    press_enter
}

enable_packages() {
    echo -e "${GREEN}Enable snap and cron service as well.${NC}"
    systemctl enable preload haveged snapd cron
    press_enter
}

swap_maker() {
    clear
    title="Setup and Configure swap file to boost performance"
    swap_files=$(swapon -s | awk '{if($1!~"^Filename"){print $1}}')
    swap_partitions=$(grep -E '^\S+\s+\S+\sswap\s+' /proc/swaps | awk '{print $1}')
    logo
    echo ""
    echo -e "${CYAN}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    echo ""

    remove_all_swap() {
    for item in $swap_files $swap_partitions; do
        swapoff "$item"
        rm -f "$item"
    done
    }

    if [ -n "$swap_files" ]; then
        remove_all_swap
    fi

    echo -e "${YELLOW}Please select the swap file size: ${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} 512M"
    echo -e "${GREEN}2)${NC} 1GB"
    echo -e "${GREEN}3)${NC} 2GB"
    echo -e "${GREEN}4)${NC} 4GB"
    echo -e "${GREEN}5)${NC} Manually enter values"
    echo ""
    echo -ne "${CYAN}Enter your choice [1-6]:${NC} "
    read choice

    case $choice in
        1)
            swap_size="512M"
            ;;
        2)
            swap_size="1G"
            ;;
        3)
            swap_size="2G"
            ;;
        4)
            swap_size="4G"
            ;;
        5)
            echo ""
            echo -ne "${YELLOW}Please enter the virtual memory size (e.g. 300M, 1.5G): ${NC}   "
            read swap_size_input
            swap_size="$swap_size_input"
            ;;
        *)
            echo -e "${RED}Invalid choice, No changes made.${NC}"
            return 1
            ;;
    esac

    case $swap_size in
        *M)
            swap_size_kb=$(( ${swap_size//[^0-9]/} * 1024 ))
            ;;
        *G)
            swap_size_kb=$(( ${swap_size//[^0-9]/} * 1024 * 1024 ))
            ;;
        *)
            echo -e "${RED}Invalid choice, No changes made.${NC}"
            return 1
            ;;
    esac

    dd if=/dev/zero of=/swap bs=1k count=$swap_size_kb

    if [ $? -eq 0 ]; then
        chmod 600 /swap
        mkswap /swap
        swapon /swap

        if [ $? -eq 0 ]; then
            echo "/swap swap swap defaults 0 0" >> /etc/fstab
            swapon -s | grep '/swap'
        else
            return 1
        fi
    else
        return 1
    fi

    echo -e "${BLUE}Modifying swap usage threshold... ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    echo ""
    swap_value=60
    if grep -q "^vm.swappiness" /etc/sysctl.conf; then
        sed -i "s/^vm.swappiness=.*/vm.swappiness=$swap_value/" /etc/sysctl.conf
    else
        echo "vm.swappiness=$swap_value" >> /etc/sysctl.conf
    fi
    sysctl -p

    echo ""
    echo -e "${GREEN}Swap file created and vm.swappiness value has been set to ${RED} $swap_value ${NC}"
    echo ""
    sleep 1
    press_enter
}

enable_ipv6_support() {
    sysctl -w net.ipv4.ip_forward=1
    sysctl -w net.ipv6.conf.all.forwarding=1
    sysctl -w net.ipv6.conf.default.forwarding=1
    echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/ip_forward.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.d/ip_forward.conf
    echo "net.ipv6.conf.default.forwarding = 1" >> /etc/sysctl.d/ip_forward.conf
    sysctl -p /etc/sysctl.d/ip_forward.conf
    if [[ $(sysctl -a | grep 'disable_ipv6.*=.*1') || $(cat /etc/sysctl.{conf,d/*} | grep 'disable_ipv6.*=.*1') ]]; then
    sed -i '/disable_ipv6/d' /etc/sysctl.{conf,d/*}
    echo 'net.ipv6.conf.all.disable_ipv6 = 0' >/etc/sysctl.d/ipv6.conf
    sysctl -w net.ipv6.conf.all.disable_ipv6=0
    fi
    echo ""
    echo -e "${GREEN}IPV6 enabled.${NC}"
    echo ""
}

remove_old_sysctl() {
    clear
    title="Optimizing system configuration and updating sysctl configs"
    logo
    echo ""
    echo -e "${CYAN}$title ${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""
    enable_ipv6_support
    sed -i '/1000000/d' /etc/profile
    cat <<EOL > "/etc/sysctl.conf"
# System Configuration Settings for Improved Performance and Security

fs.file-max = 1000000
net.core.rmem_default = 1048576
net.core.rmem_max = 2097152
net.core.wmem_default = 1048576
net.core.wmem_max = 2097152
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 32768
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.all.forwarding = 1
EOL
  
    cat <<EOL >"/etc/security/limits.conf"
* soft     nproc          655350
* hard     nproc          655350
* soft     nofile         655350
* hard     nofile         655350
root soft     nproc          655350
root hard     nproc          655350
root soft     nofile         655350
root hard     nofile         655350
EOL

    sysctl -p

    echo -e "${GREEN}Sysctl configuration and optimization complete${NC}"
    echo ""
    press_enter
}

optimize_ssh_configuration() {
    clear
    SSH_PATH="/etc/ssh/sshd_config"
    title="Improve SSH conf. and optimize SSHD"
    logo
    echo -e "${CYAN}$title ${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    cat <<EOL > "/etc/ssh/sshd_config"
# SSH configuration settings for improved security and performance

UseDNS no
Compression yes
Ciphers aes256-ctr,chacha20-poly1305@openssh.com
TCPKeepAlive yes
ClientAliveInterval 3000
ClientAliveCountMax 100
PermitRootLogin yes
AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts yes
PermitTunnel yes
Banner /etc/ssh/banner
X11Forwarding yes
PrintMotd no
PrintLastLog yes
EOL

echo "WARNING: Unauthorized access is prohibited." > /etc/ssh/banner

    service ssh restart
    echo ""
    echo -e "${GREEN}SSH and SSHD Configuration and optimization complete${NC}"
    echo ""
    press_enter
}

_version() {
    local ver1 ver2
    ver1="$1"
    ver2="$2"
    if dpkg --compare-versions "$ver1" ge "$ver2"; then
        return 0
    else
        return 1
    fi
}

_exists() {
    local cmd
    cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_Hybla() {
    local param=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    if [[ x"${param}" == x"hybla" ]]; then
        return 0
    else
        return 1
    fi
}

kernel_version() {
    local kernel_version=$(uname -r | cut -d- -f1)
    if _version ${kernel_version} 4.9; then
        return 0
    else
        return 1
    fi
}

check_os() {
    if _exists "virt-what"; then
        virt="$(virt-what)"
    elif _exists "systemd-detect-virt"; then
        virt="$(systemd-detect-virt)"
    fi
    if [ -n "${virt}" -a "${virt}" = "lxc" ]; then
        echo -e "${RED} Virtualization method is LXC, which is not supported. ${NC}"
    fi
    if [ -n "${virt}" -a "${virt}" = "openvz" ] || [ -d "/proc/vz" ]; then
        echo -e "${RED}Virtualization method is OpenVZ, which is not supported. ${NC}"
    fi
}

ask_bbr_version() {
    clear
    title="Select a TCP congestion control"
    logo
    echo ""
    echo -e "${CYAN}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    echo -e "${RED}1. ${YELLOW}TCP-Tweaker${NC}"
    echo -e "${RED}2. ${YELLOW}TCP-Westwood${NC}"
    echo -e "${RED}3. ${YELLOW}TCP-BBR${NC}"
    echo -e "${RED}4. ${YELLOW}XanMod & BBRv3${NC}"
    echo -e "${RED}5. ${YELLOW}TCP-Hybla${NC}"
    echo ""
    echo -e "${RED}6. ${YELLOW}No TCP congestion control${NC}"
    echo ""
    echo -ne "${CYAN}Enter your choice [1-4]: ${NC}"
    read choice
    
    case $choice in
        1)
            clear
            echo ""
            echo -e "${YELLOW}Backing up original kernel parameter configuration... ${NC}"
            echo ""
            cp /etc/sysctl.conf /etc/sysctl.conf.bak
            echo ""
            echo -e "${YELLOW}Optimizing kernel parameters for TCP-Tweaker ${NC}"
            echo ""
cat <<EOL >> /etc/sysctl.conf
#PH56
net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOL
sysctl -p
            if [ $? -eq 0 ]; then
            echo ""
                echo -e "${GREEN}Kernel parameter optimization for TCP-Tweaker was successful.${NC}"
            else
            echo ""
                echo -e "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}"
                mv /etc/sysctl.conf.bak /etc/sysctl.conf
            fi
            ;;
        2)
            clear
            echo ""
            echo -e "${YELLOW}Backing up original kernel parameter configuration... ${NC}"
            echo ""
            echo ""
            cp /etc/sysctl.conf /etc/sysctl.conf.bak
            echo -e "${YELLOW}Optimizing kernel parameters for TCP-Westwood ${NC}"
            echo ""
cat <<EOL >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = westwood
net.ipv4.tcp_moderate_rcvbuf = 0
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
EOL
sysctl -p
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Kernel parameter optimization for TCP-Westwood was successful.${NC}"
            else
                echo -e "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}"
                mv /etc/sysctl.conf.bak /etc/sysctl.conf
            fi
            ;;

        3)
            clear
            echo ""
            echo -e "${YELLOW}Backing up original kernel parameter configuration... ${NC}"
            echo ""
            echo ""
            cp /etc/sysctl.conf /etc/sysctl.conf.bak
            echo -e "${YELLOW}Optimizing kernel parameters for TCP-BBR (Bottleneck Bandwidth and Round-Trip Propagation Time) ${NC}"
            echo ""
cat <<EOL >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOL
sysctl -p
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Kernel parameter optimization for TCP-BBR was successful.${NC}"
            else
                echo -e "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}"
                mv /etc/sysctl.conf.bak /etc/sysctl.conf
            fi
            ;;
        4)
            clear
            echo ""
            echo -e "${YELLOW}If you have ubuntu or debian system, you can use this script to install and configure BBRv3. ${NC}"
            echo ""
            press_enter
            bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
            ;;
        5)
            clear
            echo ""
            echo -e "${YELLOW}    Optimizing kernel parameters for TCP-Hybla    ${NC}"
            echo ""
            echo ""
            echo -e "${YELLOW}Backing up original kernel parameter configuration... ${NC}"
            echo ""
            cp /etc/sysctl.conf /etc/sysctl.conf.bak
            check_Hybla
            kernel_version
            check_os
            sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
            sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
cat <<EOL >> /etc/sysctl.conf
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = hybla
net.ipv4.tcp_ecn = 2
net.ipv4.tcp_frto = 2
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
EOL
sysctl -p >/dev/null 2>&1

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Kernel parameter optimization for TCP-Hybla was successful.${NC}"
            else
                echo -e "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}"
                mv /etc/sysctl.conf.bak /etc/sysctl.conf
            fi
            ;;
        6)
            clear
            echo ""
            echo -e "${YELLOW}No TCP congestion control selected.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid choice.${NC}"
            return 1
            ;;
    esac
    press_enter
}
    set_timezone
    fix_dns
    complete_update
    installations
    enable_packages
    swap_maker
    remove_old_sysctl
    remove_old_ssh_conf
    ask_bbr_version
clear
logo
echo ""
echo -e "    ${MAGENTA} Your server fully optimized successfully${NC}"
printf "\e[93m+-------------------------------------+\e[0m\n" 
echo ""
echo ""
echo -e "${MAGENTA}Please reboot the system to take effect, by running the following command: ${GREEN}reboot${NC}"
echo ""
echo -e "${MAGENTA}Please visit me at: ${GREEN}https://t.me/OPIranCluB ${NC}"
echo ""
printf "\e[93m+-------------------------------------+\e[0m\n" 
echo ""
ask_reboot
