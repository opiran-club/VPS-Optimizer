#!/bin/bash
#
# VPS OPtimizer Bash Script
# Author: github.com/opiran-club
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
BOLD=$(tput bold)

# Define a backup function
backup() {
    local file="$1"
    echo -e "${YELLOW}Backing up $file...${NC}"
    cp "$file" "$file.bak"
}

# Define a version comparison function
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

# Define a command existence check function
_exists() {
    local cmd
    cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Define a Hybla check function
check_Hybla() {
    local param=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    if [[ x"${param}" == x"hybla" ]]; then
        return 0
    else
        return 1
    fi
}

# Define a kernel version check function
kernel_version() {
    local kernel_version=$(uname -r | cut -d- -f1)
    if _version ${kernel_version} 4.9; then
        return 0
    else
        return 1
    fi
}

# Define an OS check function
check_os() {
    if _exists "virt-what"; then
        virt="$(virt-what)"
    elif _exists "systemd-detect-virt"; then
        virt="$(systemd-detect-virt)"
    fi
    if [ -n "${virt}" -a "${virt}" = "lxc" ]; then
        echo -e "${RED}Virtualization method is LXC, which is not supported.${NC}"
    fi
    if [ -n "${virt}" -a "${virt}" = "openvz" ] || [ -d "/proc/vz" ]; then
        echo -e "${RED}Virtualization method is OpenVZ, which is not supported.${NC}"
    fi
}

# Define a BBR installation function
ask_bbr_version_1() {
    wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh && chmod 755 /opt/bbr.sh && bash /opt/bbr.sh
}

fun_bar() {
  local title="$1"
  local command1="$2"
  local command2="$3"

  (
    [[ -e $HOME/fim ]] && rm $HOME/fim
    $command1 -y > /dev/null 2>&1
    $command2 -y > /dev/null 2>&1
    touch $HOME/fim
  ) > /dev/null 2>&1 &

  tput civis
  echo -ne "  ${BOLD}${YELLOW} $title   ${BOLD}- ${YELLOW}["
  while true; do
    for ((i=0; i<18; i++)); do
      echo -ne "${RED}#"
      sleep 0.1s
    done

    [[ -e "$HOME/fim" ]] && rm "$HOME/fim" && break
    echo -e "${YELLOW}]"
    sleep 1s
    tput cuu1
    tput dl1
    echo -ne "  ${BOLD}${YELLOW}$title...${BOLD}- ${YELLOW}["
  done
  echo -e "${YELLOW}]${WHITE} -${GREEN} DONE!${WHITE}"
  tput cnorm
}

if [ "$EUID" -ne 0 ]; then
echo -e "\n ${RED}This script must be run as root.${NC}"
exit 1
fi

sourcelist() {
    clear
    title="Source list adjustment to officials"
    logo
    echo ""
    echo -e "${CYAN}$title ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n"
    echo ""

    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            "ubuntu")
                echo ""
                if grep -q "archive.ubuntu.com" /etc/apt/sources.list; then
                    return
                else
                    echo -ne "${GREEN}Your source list is not archive.ubuntu, let's update it? [y/n]: ${NC}"
                    read source
                    case $source in
                        [Yy])
                            cp /etc/apt/sources.list /etc/apt/sources.list.bak
                            rm -rf /etc/apt/sources.list

                            arch=$(uname -m)

                            case $arch in
                                i?86)
                                    source_url="https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/Install/ubuntu-source"
                                    ;;
                                x86_64)
                                    source_url="https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/Install/ubuntu-source"
                                    ;;
                                arm*)
                                    source_url="https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/Install/arm64-ubuntu"
                                    ;;
                                *)
                                    echo -e "${RED}Unsupported architecture. No changes made.${NC}"
                                    return
                                    ;;
                            esac

                            if wget -N -4 /etc/apt/sources.list "$source_url"; then
                                echo -e "${GREEN}Your source list was updated successfully.${NC}"
                            else
                                echo -e "${RED}Failed to update your source list.${NC}"
                                cp /etc/apt/sources.list.bak /etc/apt/sources.list
                            fi
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
}


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
    printf "${CYAN}%s ${NC}\n" "$title"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n"
    public_ip=$(curl -s ipinfo.io/ip)

    if [[ $? -eq 0 ]]; then
        location=$(curl -s ipinfo.io/$public_ip/city)
        timezone=$(curl -s ipinfo.io/$public_ip/timezone)
        printf "${YELLOW}Your location is ${GREEN}%s${NC}\n" "$location"
        printf "${YELLOW}Your timezone is ${GREEN}%s${NC}\n" "$timezone"
        date_time=$(date --date="TZ=\"$timezone\"" "+%Y-%m-%d %H:%M:%S")
        printf "${YELLOW}The current date and time in your timezone is ${GREEN}%s${NC}\n" "$date_time"
    else
        printf "${RED}Error: Failed to fetch public IP address.${NC}\n"
    fi

    echo ""
    press_enter
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

    apt-get update
    apt-get upgrade -y
    apt-get autoremove -y
    apt-get clean -y
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
    apt-get install jq certbot nload nethogs autossh ssh iperf sshuttle software-properties-common apt-transport-https iptables lsb-release ca-certificates ubuntu-keyring gnupg2 apt-utils cron bash-completion curl git unzip zip ufw wget preload locales nano vim python3 jq qrencode socat busybox net-tools haveged htop curl -y
    apt-get install snapd -y
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
    swap_value=10
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

swap_maker_1() {
    remove_all_swap() {
    for item in $swap_files $swap_partitions; do
        swapoff "$item"
        rm -f "$item"
    done
    }
    remove_all_swap
    swap_size="512M"
    chmod 600 /swap
    mkswap /swap
    swapon /swap
    echo "/swap swap swap defaults 0 0" >> /etc/fstab
    swapon -s | grep '/swap'
    swap_value=10
    if grep -q "^vm.swappiness" /etc/sysctl.conf; then
        sed -i "s/^vm.swappiness=.*/vm.swappiness=$swap_value/" /etc/sysctl.conf
    else
        echo "vm.swappiness=$swap_value" >> /etc/sysctl.conf
    fi
    sysctl -p
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
net.core.default_qdisc = fq_codel
net.core.optmem_max = 65535
net.ipv4.tcp_rmem = 8192 1048576 16777216
net.core.rmem_default = 1048576
net.core.rmem_max = 2097152
net.core.wmem_default = 1048576
net.core.wmem_max = 2097152
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 32768
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_max_orphans = 819200
net.ipv4.tcp_max_syn_backlog = 20480
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mem = 65536 131072 262144
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.unix.max_dgram_qlen = 50
vm.min_free_kbytes = 65536
vm.vfs_cache_pressure=50
net.ipv4.ip_forward = 1
net.ipv4.tcp_wmem = 8192 1048576 16777216
net.ipv4.tcp_notsent_lowat = 16384
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

ask_bbr_version() {
    clear
    title="Select a TCP congestion control"
    logo
    echo ""
    printf "${CYAN}%s ${NC}\n" "$title"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    printf "${RED}1. ${YELLOW}TCP-Tweaker${NC}\n"
    printf "${RED}2. ${YELLOW}TCP-Westwood${NC}\n"
    printf "${RED}3. ${YELLOW}TCP-BBR${NC}\n"
    printf "${RED}4. ${YELLOW}XanMod & BBRv3${NC}\n"
    printf "${RED}5. ${YELLOW}TCP-Hybla${NC}\n"
    printf "${RED}6. ${YELLOW}OpenVZ${NC}\n"
    echo ""
    printf "${RED}7. ${YELLOW}No TCP congestion control${NC}\n"
    echo ""
    printf "${CYAN}Enter your choice [1-4]: ${NC}"
    read choice
    
    case $choice in
        1)
            clear
            echo ""
            # Use the backup function
            backup /etc/sysctl.conf
            echo ""
            printf "${YELLOW}Optimizing kernel parameters for TCP-Tweaker ${NC}\n"
            echo ""
cat <<EOL >> /etc/sysctl.conf
# Load the tcp_tweaker module
modprobe tcp_tweaker
# Set the congestion control algorithm to tweaker
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = tweaker
EOL
sysctl -p
            if [ $? -eq 0 ]; then
            echo ""
                printf "${GREEN}Kernel parameter optimization for TCP-Tweaker was successful.${NC}\n"
            else
            echo ""
                printf "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}\n"
                # Use the backup function
                backup /etc/sysctl.conf.bak
            fi
            ;;
        2)
            clear
            echo ""
            # Use the backup function
            backup /etc/sysctl.conf
            echo ""
            printf "${YELLOW}Optimizing kernel parameters for TCP-Westwood ${NC}\n"
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
                printf "${GREEN}Kernel parameter optimization for TCP-Westwood was successful.${NC}\n"
            else
                printf "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}\n"
                # Use the backup function
                backup /etc/sysctl.conf.bak
            fi
            ;;

        3)
            clear
            echo ""
            # Use the backup function
            backup /etc/sysctl.conf
            echo -e "${YELLOW}Optimizing kernel parameters for TCP-BBR ${NC}"
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
                # Use the backup function
                backup /etc/sysctl.conf.bak
            fi
            ;;
        4)
            clear
            echo ""
            printf "${YELLOW}If you have ubuntu or debian system, you can use this script to install and configure BBRv3. ${NC}\n"
            echo ""
            press_enter
            bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
            ;;
        5)
            clear
            echo ""
            printf "${YELLOW}Optimizing kernel parameters for TCP-Hybla ${NC}\n"
            echo ""
            echo ""
            # Use the backup function
            backup /etc/sysctl.conf
            check_Hybla
            kernel_version
            check_os
            sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
            sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
cat <<EOL >> /etc/sysctl.conf
# Use SFQ as the qdisc for eth0
tc qdisc add dev eth0 root sfq
# Set the congestion control algorithm to hybla
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
                printf "${GREEN}Kernel parameter optimization for TCP-Hybla was successful.${NC}\n"
            else
                printf "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}\n"
                # Use the backup function
                backup /etc/sysctl.conf.bak
            fi
            ;;
        6)
            clear
            echo ""
            printf "${YELLOW}Optimizing kernel parameters for Open-vz ${NC}\n"
            echo ""
            # Check the virtualization method and the kernel support
            if [ -n "${virt}" -a "${virt}" = "openvz" ] || [ -d "/proc/vz" ]; then
                if [ -e /sys/class/net/venet0 ]; then
                    # Use the backup function
                    backup /etc/sysctl.conf
                    # Delete any existing lines related to qdisc and congestion control
                    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
                    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
                    # Set the qdisc to fq_codel for venet0
                    tc qdisc add dev venet0 root fq_codel
                    # Set the congestion control to bbr for venet0
                    sysctl -w net.ipv4.tcp_congestion_control=bbr
                    # Reload the sysctl file
                    sysctl -p
                    # Check the return value
                    if [ $? -eq 0 ]; then
                        printf "${GREEN}Kernel parameter optimization for Open-vz was successful.${NC}\n"
                    else
                        printf "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}\n"
                        # Use the backup function
                        backup /etc/sysctl.conf.bak
                    fi
                else
                    printf "${RED}Your kernel does not support the venet0 interface. No changes made.${NC}\n"
                fi
            else
                printf "${RED}Your virtualization method is not Open-vz. No changes made.${NC}\n"
            fi
            ;;  

        7)
            clear
            echo ""
            printf "${YELLOW}No TCP congestion control selected.${NC}\n"
            ;;
        *)
            printf "${RED}Invalid choice.${NC}\n"
            return 1
            ;;
    esac
    press_enter
}

final() {
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
}

while true; do
clear
    tg_title="https://t.me/OPIranCluB"
    yt_title="youtube.com/@opiran-inistitute"
    clear
    logo
    echo -e "\e[93m╔═══════════════════════════════════════════════╗\e[0m"  
    echo -e "\e[93m║            \e[94mVPS OPTIMIZER                       \e[93m║\e[0m"   
    echo -e "\e[93m╠═══════════════════════════════════════════════╣\e[0m"     
    echo ""
    echo -e "${BLUE}   ${tg_title}   ${NC}"
    echo -e "${BLUE}   ${yt_title}   ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    echo ""
    echo -e "${GREEN} 1) ${NC} Optimizer (1 click) ${NC}"
    echo -e "${GREEN} 2) ${NC} Optimizer (step by step) ${NC}"
    echo ""
    echo -e "${GREEN} E) ${NC} Exit the menu${NC}"
    echo ""
    echo -ne "${GREEN}Select an option: ${NC}  "
    read choice

    case $choice in
 
        1)
        clear
            fun_bar "Update and replace DNS nameserver" fix_dns
            fun_bar "Complete update and upgrade" complete_update
            fun_bar "Install usefull packages" installations
            fun_bar "Enable some services" enable_packages
            fun_bar "Create swap file with 512mb" swap_maker_1
            fun_bar "Updating sysctl configuration" remove_old_sysctl
            fun_bar "Updating and Modifying SSH configuration" remove_old_ssh_conf
            fun_bar "(Press Enter) TCP BBR common script (Press Enter) " ask_bbr_version_1
            final
            ;;
        2)
            sourcelist
            set_timezone
            fix_dns
            complete_update
            installations
            enable_packages
            swap_maker
            remove_old_sysctl
            remove_old_ssh_conf
            ask_bbr_version
            final
            ;;
        E|e)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid option."
            ;;
    esac

    echo -e "\n${RED}Press Enter to continue... ${NC}"
    read
done
