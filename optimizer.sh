#!/bin/bash
# 
# VPS OPtimizer Bash Script
# Author: github.com/opiran-club
#
# For more information and updates, visit github.com/opiran-club and @opiranclub on telegram.
CYAN="\e[96m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
BLUE="\e[94m"
MAGENTA="\e[95m"
WHITE="\e[97m"
NC="\e[0m"
BOLD=$(tput bold)
ask_bbr_version_1() {
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    echo && echo -e "${YELLOW}Installing and configuring BBRv1 + FQ...${NC}"
    sed -i '/^net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/^net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
        if [ $? -eq 0 ]; then
            echo && echo -e "${GREEN}Kernel parameter optimization for OpenVZ was successful.${NC}"
        else
            echo && echo -e "${RED}Optimization failed. Restoring original sysctl configuration.${NC}"
            mv /etc/sysctl.conf.bak /etc/sysctl.conf
        fi
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
    ) &
    tput civis
    echo -ne "  ${BOLD}${YELLOW}$title${BOLD} - ${YELLOW}["
    while true; do
        for ((i = 0; i < 18; i++)); do
            echo -ne "${RED}#"
            sleep 0.1
        done
        if [[ -e "$HOME/fim" ]]; then
            rm "$HOME/fim"
            break
        fi
        echo -e "${YELLOW}]"
        sleep 0.5
        tput cuu1
        tput el 
        echo -ne "  ${BOLD}${YELLOW}$title${BOLD} - ${YELLOW}["
    done
    echo -e "${YELLOW}]${WHITE} -${GREEN} DONE!${WHITE}"
    tput cnorm
}
if [ "$EUID" -ne 0 ]; then
echo && echo -e "\n ${RED}This script must be run as root.${NC}"
exit 1
fi

sourcelist() {
    clear
    title="Source List Adjustment to Official Repositories"
    logo 
    echo ""
    echo -e "${MAGENTA}$title${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""

    cp /etc/apt/sources.list /etc/apt/sources.list.bak || {
        echo && echo -e "${RED}Error backing up sources.list. Aborting.${NC}"
        return 1
    }

    if ! command -v jq >/dev/null 2>&1; then
        echo && echo -e "${YELLOW}jq not found, attempting to install...${NC}"
        if ! apt-get install -y jq; then
            echo && echo -e "${RED}Error installing jq. Aborting.${NC}"
            return 1
        fi
    fi

    get_release_codename() {
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            case "$ID" in
                "ubuntu")
                    release=$(lsb_release -cs)
                    ;;
                "debian")
                    release=$(lsb_release -cs)
                    ;;
                *)
                    echo && echo -e "${RED}Unsupported OS. Cannot determine release codename.${NC}"
                    return 1
                    ;;
            esac
            echo "$release"
        else
            echo && echo -e "${RED}Unable to detect OS. No changes made.${NC}"
            return 1
        fi
    }

    release=$(get_release_codename)
    if [ $? -ne 0 ]; then
        return 1
    fi

    update_ubuntu_sources() {
        local mirror_url
        if [ "$1" = "iran" ]; then
            mirror_url="http://mirror.arvancloud.ir/ubuntu"
        else
            mirror_url="http://archive.ubuntu.com/ubuntu"
        fi
        temp_file=$(mktemp)
        cat <<EOL > "$temp_file"
deb $mirror_url $release main restricted
deb $mirror_url $release-updates main restricted
deb $mirror_url $release universe
deb $mirror_url $release-updates universe
deb $mirror_url $release multiverse
deb $mirror_url $release-updates multiverse
deb $mirror_url $release-backports main restricted universe multiverse
deb $mirror_url $release-security main restricted
deb $mirror_url $release-security universe
deb $mirror_url $release-security multiverse
EOL
        mv "$temp_file" /etc/apt/sources.list || {
            echo && echo -e "${RED}Error writing to sources.list.  Changes not saved.${NC}"
            rm -f "$temp_file"
            return 1
        }
    }

    update_debian_sources() {
        local mirror_url
        local security_mirror_url
        if [ "$1" = "iran" ]; then
            mirror_url="http://mirror.arvancloud.ir/debian"
            security_mirror_url="http://mirror.arvancloud.ir/debian-security"
        else
            mirror_url="http://deb.debian.org/debian"
            security_mirror_url="http://security.debian.org/debian-security"
        fi
        temp_file=$(mktemp)
        cat <<EOL > "$temp_file"
deb $mirror_url $release main
deb $mirror_url $release-updates main
deb $mirror_url $release-backports main
deb $security_mirror_url $release-security main
EOL
        mv "$temp_file" /etc/apt/sources.list || {
            echo && echo -e "${RED}Error writing to sources.list. Changes not saved.${NC}"
            rm -f "$temp_file"
            return 1
        }
    }

    if [ -f /etc/os-release ]; then
        source /etc/os-release
        location_info=$(curl -s "http://ipwho.is")
        if [[ $? -ne 0 ]]; then
            echo && echo -e "${RED}Error fetching location information. Using default mirrors.${NC}"
            location="Unknown"
        else
            public_ip=$(echo "$location_info" | jq -r '.ip')
            location=$(echo "$location_info" | jq -r '.country')
        fi
        if [[ "$location" == "Iran" ]]; then
             echo && echo -ne "${YELLOW}Location detected as ${GREEN}Iran${YELLOW}. Update sources list to Iranian mirrors? ${GREEN}[SUGGESTED Y] ${YELLOW}[y/n]: ${NC}"
        else
            echo && echo -ne "${YELLOW}Location detected as ${GREEN}$location${YELLOW}. Update sources list to default mirrors? ${GREEN}[SUGGESTED Y] ${YELLOW}[y/n]: ${NC}"
        fi
        read -r update_choice

        case $update_choice in
            [Yy]*)
                case "$ID" in
                    "ubuntu")
                        update_ubuntu_sources "$([[ "$location" == "Iran" ]] && echo "iran" || echo "non-iran")"
                        echo && echo -e "${GREEN}Ubuntu sources list updated.${NC}"
                        ;;
                    "debian")
                        update_debian_sources "$([[ "$location" == "Iran" ]] && echo "iran" || echo "non-iran")"
                        echo && echo -e "${GREEN}Debian sources list updated.${NC}"
                        ;;
                    *)
                        echo && echo -e "${RED}Unsupported OS detected. No changes made.${NC}"
                        ;;
                esac
                ;;
            [Nn]*)
                echo && echo -e "${YELLOW}Skipping sources list update.${NC}"
                ;;
            *)
                echo && echo -e "${RED}Invalid input. No changes made.${NC}"
                ;;
        esac
    else
        echo && echo -e "${RED}Unable to detect OS. No changes made.${NC}"
    fi
    press_enter
}

press_enter() {
    echo -e "\n ${MAGENTA}Press Enter to continue... ${NC}"
    read
}

ask_reboot() {
echo && echo -e "\n ${YELLOW}Reboot now? (Recommended) ${GREEN}[y/n]${NC}"
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
    echo && printf "${MAGENTA}%s ${NC}\n" "$title"
    echo && printf "\e[93m+-------------------------------------+\e[0m\n"
    current_timezone=$(timedatectl | awk '/Time zone/ {print $3}')
    echo && printf "${YELLOW}Your current timezone is ${GREEN}%s${NC}\n" "$current_timezone"
    if ! command -v curl &> /dev/null; then
        echo && printf "${RED}Error: curl is not installed. Please install curl to proceed.${NC}\n"
        return 1
    fi
    sources=("http://ipwho.is" "http://ip-api.com/json")
    for source in "${sources[@]}"; do
        content=$(curl -s "$source" 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            case "$source" in
                "http://ipwho.is")
                    public_ip=$(echo "$content" | jq -r '.ip' 2>/dev/null)
                    location=$(echo "$content" | jq -r '.city' 2>/dev/null)
                    timezone=$(echo "$content" | jq -r '.timezone.id' 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    ;;
                "http://ip-api.com/json")
                    public_ip=$(echo "$content" | jq -r '.query' 2>/dev/null)
                    location=$(echo "$content" | jq -r '.city' 2>/dev/null)
                    timezone=$(echo "$content" | jq -r '.timezone' 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                    ;;
            esac
            if [[ -n "$location" && -n "$timezone" && -n "$public_ip" ]]; then
                break
            fi
        fi
    done
    if [[ -n "$location" && -n "$timezone" && -n "$public_ip" ]]; then
        printf "${YELLOW}Your public IP is ${GREEN}%s${NC}\n" "$public_ip"
        printf "${YELLOW}Your location is ${GREEN}%s${NC}\n" "$location"
        printf "${YELLOW}Your detected timezone is ${GREEN}%s${NC}\n" "$timezone"
        date_time=$(TZ="$timezone" date "+%Y-%m-%d %H:%M:%S")
        echo && printf "${YELLOW}The current date and time in your detected timezone is ${GREEN}%s${NC}\n" "$date_time"
    else
        echo && printf "${RED}Error: Failed to fetch location and timezone information from all sources.${NC}\n"
    fi
    press_enter
}
logo1="     ______    _______    __      _______        __      _____  ___   "
logo2="    /      \  |   __  \  |  \    /       \      /  \     \    \|   \  "
logo3="   /  ____  \ (  |__)  ) |   |  |         |    /    \    |.\   \    | "
logo4="  /  /    )  )|   ____/  |   |  |_____/   )   /' /\  \   |: \   \   | "
logo5=" (  (____/  / (   /      |.  |   //      /   //  __'  \  |.  \    \.| "
logo6="  \        / /    \      /\  |\ |:  __   \  /   /  \\   \ |    \    \| "
logo7="   \_____/ (_______)    (__\_|_)|__|  \___)(___/    \___)\___|\____\) "

logo() {
echo -e "${BLUE}${logo1:0:24}${RED}${logo1:24:19}${WHITE}${logo1:43:14}${GREEN}${logo1:57}${NC}"
echo -e "${BLUE}${logo2:0:24}${RED}${logo2:24:19}${WHITE}${logo2:43:14}${GREEN}${logo2:57}${NC}"
echo -e "${BLUE}${logo3:0:24}${RED}${logo3:24:19}${WHITE}${logo3:43:14}${GREEN}${logo3:57}${NC}"
echo -e "${BLUE}${logo4:0:24}${RED}${logo4:24:19}${WHITE}${logo4:43:14}${GREEN}${logo4:57}${NC}"
echo -e "${BLUE}${logo5:0:24}${RED}${logo5:24:19}${WHITE}${logo5:43:14}${GREEN}${logo5:57}${NC}"
echo -e "${BLUE}${logo6:0:24}${RED}${logo6:24:19}${WHITE}${logo6:43:14}${GREEN}${logo6:57}${NC}"
echo -e "${BLUE}${logo7:0:24}${RED}${logo7:24:19}${WHITE}${logo7:43:14}${GREEN}${logo7:57}${NC}"
}

spin() {
    SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for i in $(seq 1 30); do
        c=${SPINNER:i%${#SPINNER}:1}
        echo -ne "${RED}${c}${NC}"
        sleep 0.1
        echo -ne "\b"
    done
}

fix_dns() {
    clear
    title="DNS Replacement"
    logo
    echo && echo -e "${MAGENTA}$title${NC}"
    echo && printf "\e[93m+-------------------------------------+\e[0m\n"
    interface_name=$(ip -o link show | awk '/state UP/ {print $2}' | sed 's/:$//')
    if [ -z "$interface_name" ]; then
        echo && echo -e "${RED}Error: Could not determine network interface.${NC}"
        return 1
    fi
    echo && echo -e "${YELLOW}Select DNS provider:${NC}"
    echo -e "$RED 1. $CYAN Google Public DNS (8.8.8.8, 8.8.4.4)${NC}"
    echo -e "$RED 2. $CYAN Cloudflare DNS (1.1.1.1, 1.1.1.2)${NC}"
    echo -e "$RED 3. $CYAN Quad9 DNS (9.9.9.9, 149.112.112.112)${NC}"
    echo -e "$RED 4. $CYAN 403 online DNS (Iranians anti tahrim) (10.202.10.202, 10.202.10.102)${NC}"
    echo && read -p "Enter your choice (1-4): " choice
    case $choice in
        1)
            dns_servers="nameserver 8.8.8.8\nnameserver 8.8.4.4"
            ;;
        2)
            dns_servers="nameserver 1.1.1.1\nnameserver 1.1.1.2"
            ;;
        3)
            dns_servers="nameserver 9.9.9.9\nnameserver 149.112.112.112"
            ;;
        4)
            dns_servers="nameserver 10.202.10.202\nnameserver 10.202.10.102"
            ;;
        *)
            echo && echo -e "${RED}Invalid choice.${NC}"
            return 1
            ;;
    esac
    if ! command -v resolvconf >/dev/null 2>&1; then
        echo && echo -e "${YELLOW}resolvconf not found, attempting to install...${NC}"
        if ! apt-get install -y resolvconf; then
            echo && echo -e "${RED}Error installing resolvconf.${NC}"
            return 1
        fi
    fi
    if command -v resolvconf >/dev/null 2>&1; then
        echo && echo -e "${YELLOW}Using resolvconf to configure DNS...${NC}"
        echo "$dns_servers" | resolvconf -a "$interface_name"
    else
        echo && echo -e "${YELLOW}resolvconf not found, using /etc/resolv.conf...${NC}"
        rm -rf /etc/resolv.conf && touch /etc/resolv.conf
        echo "$dns_servers" > /etc/resolv.conf
    fi
    spin & SPIN_PID=$!
    wait $SPIN_PID
    echo && echo -e "${GREEN}System DNS Optimized.${NC}"
    sleep 1
    press_enter
}

complete_update() {
    clear
    title="Update and upgrade packages"
    logo
    echo && echo -e "${CYAN}$title ${NC}"
    echo && printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo && echo -e "${RED}Please wait, it might take a couple of minutes${NC}" && echo
    apt-get update
    apt-get upgrade -y
    apt-get autoremove -y
    apt-get clean -y
    echo "140.82.114.4 github.com" | sudo tee -a /etc/hosts
    echo "185.199.108.133 raw.githubusercontent.com" | sudo tee -a /etc/hosts
    echo && echo -e "${GREEN}System update & upgrade completed.${NC}"
    sleep 1
    press_enter
}
installations() {
    clear
    title="Install necessary packages"
    logo
    echo && echo -e "${MAGENTA}$title ${NC}"
    echo && printf "\e[93m+-------------------------------------+\e[0m\n"
    echo && echo -e "${YELLOW}Please wait, it might take a while${NC}"
    apt-get install jq nload nethogs autossh ssh iperf software-properties-common apt-transport-https \
                    lsb-release ca-certificates gnupg2 bash-completion curl git unzip \
                    zip wget locales nano python3 net-tools haveged htop dnsutils iputils-ping -y
    echo && echo -e "${GREEN}Installation of useful and necessary packages completed.${NC}"
    sleep 1
    press_enter
}
swap_maker() {
    clear
    title="Setup and Configure Swap File to Boost Performance"
    logo
    echo && echo -e "${MAGENTA}$title${NC}"
    echo && printf "\e[93m+-------------------------------------+\e[0m\n"
    existing_swap=$(swapon -s | awk '$1 !~ /^Filename/ {print $1}')
    if [[ -n "$existing_swap" ]]; then
        echo -e "${YELLOW}Removing existing swap files...${NC}"
        for swap_file in $existing_swap; do
            swapoff "$swap_file" || {
                echo -e "${RED}Error turning off swap: $swap_file. Skipping.${NC}"
            }
            rm -f "$swap_file" || {
                echo -e "${RED}Error removing swap file: $swap_file. Skipping.${NC}"
            }
        done
    fi
    while true; do
        echo && echo -e "$RED TIP! $NC"
        echo -e "$CYAN It is just suggestion, Choose 2 GB if you have enough space and 512gb < RAM < 2gb  $NC"
        echo && echo -e "${YELLOW}Please select the swap file size (depends on your disk space and RAM):${NC}"
        echo && echo -e "${RED}1.${NC} 512MB"
        echo -e "${RED}2.${NC} 1GB"
        echo -e "${RED}3.${NC} 2GB"
        echo -e "${RED}4.${NC} 4GB"
        echo -e "${RED}5.${NC} Manually enter value"
        echo -e "${RED}6.${NC} No Swap"
        echo && read -r choice

        case $choice in
            1|2|3|4|5|6) break ;;
            *) echo && echo -e "${RED}Invalid choice.${NC}" ;;
        esac
    done

    case $choice in
        1) swap_size="512M" ;;
        2) swap_size="1G" ;;
        3) swap_size="2G" ;;
        4) swap_size="4G" ;;
        5)
            echo -ne "${YELLOW}Please enter the swap file size (e.g., 300M, 1.5G): ${NC}" 
            read swap_size
            ;;
        6)
            echo && echo -e "${RED}No swap file will be created. Exiting...${NC}"
            return 0
            ;;
    esac
    swap_file="/swapfile"
    if [[ $choice != 6 ]]; then
        count=$(echo "$swap_size" | awk -F'[GM]' '{print $1 * ( $2 == "G" ? 1024 : 1)}')
        dd if=/dev/zero of="$swap_file" bs=1M count="$count" status=progress 2>&1 || {
            echo && echo -e "${RED}Error creating swap file: $swap_file. Exiting...${NC}"
            return 1
        }
        chmod 600 "$swap_file" || {
            echo && echo -e "${RED}Error setting permissions on swap file. Exiting...${NC}"
            return 1
        }
        mkswap "$swap_file" || {
            echo && echo -e "${RED}Error setting up swap space. Exiting...${NC}"
            return 1
        }
        swapon "$swap_file" || {
            echo && echo -e "${RED}Error enabling swap file. Exiting...${NC}"
            return 1
        }
        echo "$swap_file none swap sw 0 0" >> /etc/fstab || {
            echo && echo -e "${RED}Error adding swap to fstab.  Manual addition required.${NC}"
        }
        echo && echo -e "${BLUE}Modifying swap usage threshold (vm.swappiness)...${NC}"
        echo && printf "\e[93m+-------------------------------------+\e[0m\n"
        swap_value=10
        sed -i "/^vm\.swappiness=/c vm.swappiness=$swap_value" /etc/sysctl.conf || {
            echo && echo -e "${RED}Error setting swappiness. Manual modification required.${NC}"
        }
        sysctl -p
        echo && echo -e "${GREEN}Swap file created and vm.swappiness set to ${RED}$swap_value${NC}."
    fi
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
remove_old_sysctl() {
    clear
    title=" Network Optimizing "
    logo
    echo && echo -e "${MAGENTA}$title${NC}"
    echo && echo -e "\e[93m+-------------------------------------+\e[0m"
    sed -i '/1000000/d' /etc/profile
cat <<EOL > /etc/sysctl.conf
# System Configuration Settings for Improved Performance and Security

# File limits
fs.file-max = 67108864

# Network core settings
net.core.default_qdisc = fq_codel
net.core.netdev_max_backlog = 32768
net.core.optmem_max = 262144
net.core.somaxconn = 65536
net.core.rmem_max = 33554432
net.core.rmem_default = 1048576
net.core.wmem_max = 33554432
net.core.wmem_default = 1048576

# Increase IP Fragmentation Timeout
net.ipv4.ipfrag_high_thresh = 524288
net.ipv4.ipfrag_low_thresh = 446464
net.ipv4.ipfrag_time = 60

# Memory Optimization
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500

# TCP settings
net.ipv4.tcp_rmem = 16384 1048576 33554432
net.ipv4.tcp_wmem = 16384 1048576 33554432
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fin_timeout = 25
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 7
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_max_orphans = 819200
net.ipv4.tcp_max_syn_backlog = 20480
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mem = 65536 1048576 33554432
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_notsent_lowat = 32768
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 0
net.ipv4.tcp_ecn = 1
net.ipv4.tcp_ecn_fallback = 1
net.ipv4.tcp_syncookies = 1

# UDP settings
net.ipv4.udp_mem = 65536 1048576 33554432

# IPv6 settings
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0

# Unix domain sockets
net.unix.max_dgram_qlen = 256

# VM settings
vm.min_free_kbytes = 65536
vm.swappiness = 10
vm.vfs_cache_pressure = 100

# Packet filtering
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

# ARP settings
net.ipv4.neigh.default.gc_thresh1 = 512
net.ipv4.neigh.default.gc_thresh2 = 2048
net.ipv4.neigh.default.gc_thresh3 = 16384
net.ipv4.neigh.default.gc_stale_time = 60
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2

# Kernel settings
kernel.printk = 4 4 1 7
kernel.panic = 1
vm.swappiness = 10
vm.dirty_ratio = 15
EOL

cat <<EOL > /etc/security/limits.conf
* soft nproc 655350
* hard nproc 655350
* soft nofile 655350
* hard nofile 655350
root soft nproc 655350
root hard nproc 655350
root soft nofile 655350
root hard nofile 655350
EOL
    sysctl -p
    echo && echo -e "${GREEN}Sysctl configuration and optimization complete.${NC}"
    press_enter
}
optimize_ssh_configuration() {
    clear
    SSH_PATH="/etc/ssh/sshd_config"
    title="Improve SSH Configuration and Optimize SSHD"
    logo
    echo && echo -e "${MAGENTA}$title${NC}\n"
    echo && echo -e "\e[93m+-------------------------------------+\e[0m\n"
    if [ -f "$SSH_PATH" ]; then
        cp "$SSH_PATH" "${SSH_PATH}.bak"
        echo && echo -e "${YELLOW}Backup of the original SSH configuration created at ${SSH_PATH}.bak${NC}"
    else
        echo && echo -e "${RED}Error: SSH configuration file not found at ${SSH_PATH}.${NC}"
        return 1
    fi
echo && cat <<EOL > "$SSH_PATH"
# Optimized SSH configuration for improved security and performance

Protocol 2
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519,ecdsa-sha2-nistp256,ssh-rsa
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-256,hmac-sha2-512
KexAlgorithms curve25519-sha256,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
UseDNS no
MaxSessions 10
Compression no
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 3
AllowAgentForwarding no
AllowTcpForwarding no
GatewayPorts no
PermitTunnel no
PermitRootLogin no
Banner /etc/ssh/banner
X11Forwarding no
PrintMotd no
PrintLastLog yes
MaxAuthTries 3
LoginGraceTime 1m
MaxStartups 10:30:60
EOL
    echo "WARNING: Unauthorized access to this system is prohibited." > /etc/ssh/banner
    if service ssh restart; then
        echo && echo -e "${GREEN}SSH and SSHD configuration and optimization complete.${NC}"
    else
        echo && echo -e "${RED}Failed to restart SSH service. Please check the configuration.${NC}"
        return 1
    fi
    press_enter
}

grub_tuning() {
  clear
  logo
  title="CPU Optimizing and Tuning (GRUB)"
  echo && echo -e "${MAGENTA}$title${NC}"
  echo && echo -e "\e[93m+-------------------------------------+\e[0m\n"
  cp /etc/default/grub /etc/default/grub.bak
  echo && echo -e "${YELLOW}Backup of the original grub configuration created at /etc/default/grub.bak${NC}" && echo
  modify_grub_param() {
    param="$1"
    value="$2"
    sed -i "s/^\($param\)=.*/\1=$value/" /etc/default/grub || {
      echo && echo -e "${RED}Error modifying GRUB parameter: $param${NC}"
      return 1
    }
  }
  modify_grub_param "GRUB_CMDLINE_LINUX_DEFAULT" "quiet splash"
  if ! grep -q "intel_pstate" /etc/default/grub; then
    modify_grub_param "GRUB_CMDLINE_LINUX_DEFAULT" "$(grep -oP '(?<=GRUB_CMDLINE_LINUX_DEFAULT=").*(?=")' /etc/default/grub) intel_pstate=active"
  fi
  echo && echo -e "${YELLOW}Updating GRUB configuration...${NC}"
  update-grub || {
    echo && echo -e "${RED}Error updating GRUB configuration.${NC}"
    return 1
  }
  echo && echo -e "${GREEN}GRUB configuration updated successfully!${NC}"
  echo && echo -e "${YELLOW}Reboot your system to apply the changes.${NC}"
  press_enter
}
ask_bbr_version() {
    check_Hybla() {
        local param=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
        if [[ x"${param}" == x"hybla" ]]; then
            return 0
        else
            return 1
        fi
    }
   check_os() {
        # Check virtualization and warn if LXC or OpenVZ, as they may not support some features
        if _exists "virt-what"; then
            virt="$(virt-what)"
        elif _exists "systemd-detect-virt"; then
            virt="$(systemd-detect-virt)"
        fi
        if [ -n "${virt}" ] && [[ "${virt}" == "lxc" || "${virt}" == "openvz" ]]; then
            echo -e "${RED}Virtualization method ${virt} is not supported.${NC}"
        fi
    }

    queuing() {
        # Prompt for queuing algorithm choice and store it in 'algorithm'
        echo -e "${CYAN}Select Queuing Algorithm${NC}"
        echo -e "${RED}1. ${CYAN}FQ codel ${NC}"
        echo -e "${RED}2. ${CYAN}FQ ${NC}"
        echo -e "${RED}3. ${CYAN}Cake${NC}"
        echo -ne "${YELLOW}Enter your choice [0-3]: ${NC}"
        read -r choice

        case $choice in
            1) algorithm="FQ codel";;
            2) algorithm="FQ";;
            3) algorithm="cake";;
            0) return 0;;
            *) echo -e "${RED}Invalid choice. Enter 0-3.${NC}"; return 1;;
        esac
    }
    clear
    title="TCP Congestion Control Optimization"
    logo
    echo ""
    echo -e "${MAGENTA}${title}${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""
    echo -e "${RED} TIP ! $NC
    $GREEN FQ (Fair Queuing): $NC Provides fair bandwidth distribution among flows; ideal for reducing latency by smoothing out packet delivery.
    $GREEN FQ-CoDel: $NC Combines fair queuing with CoDel (Controlled Delay) to manage buffer bloat and reduce latency effectively. It’s suitable for most VPN and general-purpose networking cases.
    $GREEN CAKE: $NC An advanced queuing discipline that manages both bufferbloat and fair queueing . It’s effective for WAN connections but consumes more CPU.
    
    $YELLOW My Suggestion is : $GREEN Fq_codel & cake $NC"
    echo
    echo -e "${RED}1. ${CYAN} BBR + FQ codel / FQ / cake ${NC}"
    echo -e "${RED}2. ${CYAN} BBRv3 [XanMod kernel]${NC}"
    echo -e "${RED}3. ${CYAN} HYBLA + FQ codel / FQ / cake   ${NC}"
    echo ""
    echo -e "${RED}4. ${CYAN} BBR [OpenVZ] ${NC}"
    echo -e "${RED}0. ${CYAN} Without BBR ${NC}"
    echo ""
    echo -ne "${YELLOW}Enter your choice [0-3]: ${NC}"
    read -r choice

case $choice in
      1)
            # BBR with selected queuing algorithm
            cp /etc/sysctl.conf /etc/sysctl.conf.bak
            queuing
            # Apply the selected queuing algorithm and BBR settings
            sed -i '/^net.core.default_qdisc/d' /etc/sysctl.conf
            echo "net.core.default_qdisc=$algorithm" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
            sysctl -p || mv /etc/sysctl.conf.bak /etc/sysctl.conf
            ;;
    2)
        echo -e "${YELLOW}Installing and configuring XanMod & BBRv3...${NC}"
        if grep -Ei 'ubuntu|debian' /etc/os-release >/dev/null; then
            bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4) || { echo -e "${RED}XanMod & BBRv3 installation failed.${NC}"; exit 1; }
            echo -e "${GREEN}XanMod & BBRv3 installation was successful.${NC}"
        else
            echo -e "${RED}This script is intended for Ubuntu or Debian systems only.${NC}"
        fi
        ;;
    3)
        cp /etc/sysctl.conf /etc/sysctl.conf.bak
        check_Hybla
        queuing
        sed -i '/^net.core.default_qdisc/d' /etc/sysctl.conf
        echo "net.core.default_qdisc=$algorithm" >> /etc/sysctl.conf
        sed -i '/^net.ipv4.tcp_congestion_control=/c\net.ipv4.tcp_congestion_control=hybla' /etc/sysctl.conf
        # Additional sysctl settings here
        sysctl -p || { echo -e "${RED}Optimization failed. Restoring original sysctl configuration.${NC}"; mv /etc/sysctl.conf.bak /etc/sysctl.conf; }
        echo -e "${GREEN}Kernel parameter optimization for Hybla was successful.${NC}"
        ;;
    4)
        echo -e "${YELLOW}Optimizing kernel parameters for OpenVZ BBR...${NC}"
        if [[ -d "/proc/vz" && -e /sys/class/net/venet0 ]]; then
            cp /etc/sysctl.conf /etc/sysctl.conf.bak
            sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
            sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
            tc qdisc add dev venet0 root fq_codel
            sysctl -w net.ipv4.tcp_congestion_control=bbr || { echo -e "${RED}Optimization failed.${NC}"; mv /etc/sysctl.conf.bak /etc/sysctl.conf; exit 1; }
            sysctl -p
            echo -e "${GREEN}Kernel parameter optimization for OpenVZ was successful.${NC}"
        else
            echo -e "${RED}This system is not OpenVZ or lacks venet0 support. No changes were made.${NC}"
        fi
        ;;
    0)
        echo -e "${YELLOW}No TCP congestion control selected.${NC}"
        ;;
    *)
        echo -e "${RED}Invalid choice. Please enter a number between 0 and 3.${NC}"
        return 1
        ;;
esac
press_enter
}
speedtestcli() {
if ! command -v speedtest &>/dev/null; then
    local pkg_manager=""
    local speedtest_install_script=""
if command -v dnf &>/dev/null; then
    pkg_manager="dnf"
    speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh"
elif command -v yum &>/dev/null; then
    pkg_manager="yum"
    speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh"
elif command -v apt-get &>/dev/null; then
    pkg_manager="apt-get"
    speedtest_install_script="https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh"
else
    echo && echo -e "$RED Error: Supported package manager not found. You may need to install Speedtest manually. $NC"
    return 1
fi
if curl -s $speedtest_install_script | bash; then
    echo && echo -e "$GREEN Speedtest repository added successfully. $NC"
else
    echo && echo -e "$RED Error: Failed to add the Speedtest repository.$NC"
    return 1
fi
    $pkg_manager install -y speedtest
fi
if command -v speedtest &>/dev/null; then
    speedtest
else
    echo && echo -e "$RED Error: Speedtest is not installed.$NC"
fi
}
benchmark() {
    clear
    title="Benchmark (iperf test)"
    logo
    echo && echo -e "${MAGENTA}${title}${NC}"
    echo && echo -e "\e[93m+-------------------------------------+\e[0m"
    if ! command -v wget &>/dev/null; then
        apt-get install wget -y
    fi
    echo && echo -e "${MAGENTA} TIP! ${NC}"
    echo -e "${YELLOW} THIS TEST TAKES A LONG TIME, SO PLEASE BE PATIENT ${NC}"
    echo && echo -e "${GREEN}Valid Regions: ${YELLOW} na, sa, eu, au, asia, africa, middle-east, india, china, iran${NC}"
    echo && echo -ne "Please type the destination: "
    read -r location
    if wget -qO- network-speed.xyz | bash -s -- -r "$location"; then
        echo && echo -e "${GREEN}Benchmark test completed successfully.${NC}"
    else
        echo && echo -e "${RED}Error: Failed to run the benchmark test.${NC}"
    fi
    press_enter
}
final() {
clear
logo
echo && echo -e "    ${MAGENTA} Your server fully optimized successfully${NC}"
printf "\e[93m+-------------------------------------+\e[0m\n" 
echo && echo -e "${MAGENTA}Please reboot the system to take effect, by running the following command: ${GREEN}reboot${NC}"
echo && echo -e "${MAGENTA}Please visit me at: ${GREEN}https://t.me/OPIranCluB ${NC}"
echo && printf "\e[93m+-------------------------------------+\e[0m\n" 
echo && ask_reboot
}
while true; do
    clear
    tg_title="https://t.me/OPIranCluB"
    yt_title="youtube.com/@opiran-institute"
    clear
    logo
    echo -e "\e[93m╔═══════════════════════════════════════════════╗\e[0m"  
    echo -e "\e[93m║            \e[94mVPS OPTIMIZER                      \e[93m║\e[0m"   
    echo -e "\e[93m╠═══════════════════════════════════════════════╣\e[0m"
    echo && echo -e "${BLUE}   ${tg_title}   ${NC}"
    echo -e "${BLUE}   ${yt_title}   ${NC}"
    echo && echo -e "\e[93m+-----------------------------------------------+\e[0m" 
    echo && printf "${GREEN} 1) ${NC} Optimizer (1-click)${NC}\n"
    printf "${GREEN} 2) ${NC} Optimizer (step by step)${NC}\n"
    echo && printf "${GREEN} 3) ${NC} Swap Management${NC}\n"
    printf "${GREEN} 4) ${NC} Grub Tuning ${NC}\n"
    printf "${GREEN} 5) ${NC} BBR Optimization${NC}\n"
    echo && printf "${GREEN} 6) ${NC} Speedtest${NC}\n"
    printf "${GREEN} 7) ${NC} Benchmark VPS${NC}\n"
    echo && echo -e "\e[93m+-----------------------------------------------+\e[0m" 
    echo && printf "${GREEN} E) ${NC} Exit the menu${NC}\n"
    echo && echo -ne "${GREEN}Select an option: ${NC}"
    read -r choice
    case $choice in
        1)
            clear
            fun_bar "Updating and replacing DNS nameserver" fix_dns
            fun_bar "Complete system update and upgrade" complete_update
            fun_bar "Installing useful packages" installations
            fun_bar "Creating swap file with 512MB" swap_maker_1
            fun_bar "Updating sysctl configuration" remove_old_sysctl
            fun_bar "Updating and modifying SSH configuration" remove_old_ssh_conf
            ask_bbr_version
            final
            ;;
        2)
            sourcelist
            complete_update
            installations
            fix_dns
            set_timezone
            swap_maker
            remove_old_sysctl
            grub_tuning
            remove_old_ssh_conf
            ask_bbr_version
            final
            ;;
        3)
            swap_maker
            ;;
        5)
            ask_bbr_version
            ;;
        4)
            grub_tuning
            ;;
        6)
            speedtestcli
            ;;
        7)
            benchmark
            ;;        
        E|e)
            echo && echo -e "$RED Exiting...$NC"
            exit 0
            ;;
        *)
            echo && echo -e "${RED}Invalid choice. Please enter a valid option.${NC}"
            ;;
    esac
    echo && echo -e "\n${RED}Press Enter to continue...${NC}"
    read -r
done
done
