
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
BLUE="\e[94m"
MAGENTA="\e[95m"
WHITE="\e[97m"
NC="\e[0m"
BOLD=$(tput bold)

backup() {
    local file="$1"
    echo -e "${YELLOW}Backing up $file...${NC}"
    cp "$file" "$file.bak"
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
    ) &

    tput civis  # Hide cursor
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
        sleep 0.5  # Reduced sleep time for smoother progress bar experience
        tput cuu1  # Move cursor up one line
        tput el    # Clear to the end of the line
        echo -ne "  ${BOLD}${YELLOW}$title${BOLD} - ${YELLOW}["
    done
    echo -e "${YELLOW}]${WHITE} -${GREEN} DONE!${WHITE}"
    tput cnorm  # Restore cursor
}


if [ "$EUID" -ne 0 ]; then
echo -e "\n ${RED}This script must be run as root.${NC}"
exit 1
fi

sourcelist() {
    clear
    title="Source List Adjustment to Official Repositories"
    logo
    echo ""
    echo -e "${CYAN}$title${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""

    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    apt-get install jq -y

    clear
    title="Source List Adjustment to Official Repositories"
    logo
    echo ""
    echo -e "${CYAN}$title${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""
    get_release_codename() {
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            case $ID in
                "ubuntu" | "debian")
                    release=$(lsb_release -cs)
                    ;;
                *)
                    echo -e "${RED}Unsupported OS. Cannot determine release codename.${NC}"
                    return 1
                    ;;
            esac
            echo "$release"
        else
            echo -e "${RED}Unable to detect OS. No changes made.${NC}"
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

        cat <<EOL > /etc/apt/sources.list
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
    }

    update_debian_sources() {
        local mirror_url
        local security_mirror_url
        if [ "$1" = "iran" ]; then
            mirror_url="http://mirror.arvancloud.ir/debian"
            security_mirror_url="http://mirror.arvancloud.ir/debian-security"
        else
            mirror_url="http://deb.debian.org/debian"
            security_mirror_url="http://deb.debian.org/debian-security"
        fi

        cat <<EOL > /etc/apt/sources.list
deb $mirror_url $release main
deb $mirror_url $release-updates main
deb $mirror_url $release-backports main
deb $security_mirror_url $release-security main
EOL
    }

    if [ -f /etc/os-release ]; then
        source /etc/os-release

        location_info=$(curl -s "http://ipwho.is")
        public_ip=$(echo "$location_info" | jq -r .ip)
        location=$(echo "$location_info" | jq -r .country)

        if [[ "$location" == "Iran" ]]; then
            echo -ne "${GREEN}Location detected as ${RED}Iran${GREEN}. Update sources list to Iranian mirrors? ${YELLOW}[SUGGESTED Y] ${GREEN}[y/n]: ${NC}"
        else
            echo -ne "${GREEN}Location detected as ${RED}$location${GREEN}. Update sources list to default mirrors? ${YELLOW}[SUGGESTED Y] ${GREEN}[y/n]: ${NC}"
        fi

        read -r update_choice

        case $update_choice in
            [Yy]*)
                case $ID in
                    "ubuntu")
                        update_ubuntu_sources "$([[ "$location" == "Iran" ]] && echo "iran" || echo "non-iran")"
                        echo -e "${GREEN}Ubuntu sources list updated.${NC}"
                        ;;
                    "debian")
                        update_debian_sources "$([[ "$location" == "Iran" ]] && echo "iran" || echo "non-iran")"
                        echo -e "${GREEN}Debian sources list updated.${NC}"
                        ;;
                    *)
                        echo -e "${RED}Unsupported OS detected. No changes made.${NC}"
                        ;;
                esac
                ;;
            [Nn]*)
                echo -e "${YELLOW}Skipping sources list update.${NC}"
                ;;
            *)
                echo -e "${RED}Invalid input. No changes made.${NC}"
                ;;
        esac
    else
        echo -e "${RED}Unable to detect OS. No changes made.${NC}"
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
    echo ""

    current_timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    printf "${YELLOW}Your current timezone is ${GREEN}%s${NC}\n" "$current_timezone"
    echo ""

    if ! command -v curl &> /dev/null; then
        printf "${RED}Error: curl is not installed. Please install curl to proceed.${NC}\n"
        return 1
    fi

    sources=(
        "http://ipwho.is"
        "http://ip-api.com/json"
    )

    location=""
    timezone=""
    public_ip=""

    for source in "${sources[@]}"; do
        content=$(curl -s "$source" || true)
        
        case $source in
            "http://ipwho.is")
                public_ip=$(echo "$content" | jq -r .ip)
                location=$(echo "$content" | jq -r .city)
                timezone=$(echo "$content" | jq -r '.timezone.id' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                ;;
            "http://ip-api.com/json")
                public_ip=$(echo "$content" | jq -r .ip)
                location=$(echo "$content" | jq -r .city)
                timezone=$(echo "$content" | jq -r '.timezone' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                ;;
        esac

        if [[ -n "$location" && -n "$timezone" ]]; then
            break
        fi
    done

    if [[ -n "$location" && -n "$timezone" ]]; then
        printf "${YELLOW}Your public IP is ${GREEN}%s${NC}\n" "$public_ip"
        printf "${YELLOW}Your location is ${GREEN}%s${NC}\n" "$location"
        printf "${YELLOW}Your timezone is ${GREEN}%s${NC}\n" "$timezone"

        date_time=$(TZ="$timezone" date "+%Y-%m-%d %H:%M:%S")
        printf "${YELLOW}The current date and time in your timezone is ${GREEN}%s${NC}\n" "$date_time"
    else
        printf "${RED}Error: Failed to fetch location and timezone information from all sources.${NC}\n"
    fi

        press_enter
}



# Define logo segments
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

fix_dns() {
    clear
    title="DNS Replacement with Google"
    logo
    echo ""
    echo -e "${CYAN}$title${NC}"
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

    # Install resolvconf if not found
    if ! command -v resolvconf >/dev/null 2>&1; then
        echo -e "${YELLOW}resolvconf not found, attempting to install...${NC}"
        apt-get install -y resolvconf
    fi

    if command -v resolvconf >/dev/null 2>&1; then
        echo -e "${YELLOW}Using resolvconf to configure DNS...${NC}"
        # Corrected interface name retrieval
        interface_name=$(ip route get 8.8.8.8 | awk '{print $5; exit}')
        if [ -n "$interface_name" ]; then
            echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" | resolvconf -a "$interface_name"
        else
            echo -e "${RED}Failed to determine network interface. Falling back to direct /etc/resolv.conf modification...${NC}"
            echo 'nameserver 8.8.8.8' >>/etc/resolv.conf
            echo 'nameserver 8.8.4.4' >>/etc/resolv.conf
        fi
     fi

rm -rf /etc/resolv.conf && touch /etc/resolv.conf && echo 'nameserver 8.8.8.8' >> /etc/resolv.conf && echo 'nameserver 4.2.2.4' >> /etc/resolv.conf

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
    echo "140.82.114.4 github.com" | sudo tee -a /etc/hosts
    echo "185.199.108.133 raw.githubusercontent.com" | sudo tee -a /etc/hosts
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
    apt-get install jq nload nethogs autossh ssh iperf software-properties-common apt-transport-https \
                    lsb-release ca-certificates ubuntu-keyring gnupg2 bash-completion curl git unzip \
                    zip wget locales nano python3 net-tools haveged htop dnsutils iputils-ping -y

    echo ""
    echo -e "${GREEN}Installation of useful and necessary packages completed.${NC}"
    echo ""
    sleep 1
    press_enter
}


swap_maker() {
    clear
    title="Setup and Configure Swap File to Boost Performance"
    swap_files=$(swapon -s | awk '{if($1!~"^Filename"){print $1}}')
    logo
    echo ""
    echo -e "${CYAN}$title${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n"
    echo ""
    
    remove_all_swap() {
        for item in $swap_files; do
            swapoff "$item"
            rm -f "$item"
        done
    }

    if [ -n "$swap_files" ]; then
        echo -e "${YELLOW}Removing existing swap files...${NC}"
        remove_all_swap
    fi

    echo -e "${YELLOW}Please select the swap file size (depends on your disk space and RAM):${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} 512MB"
    echo -e "${GREEN}2)${NC} 1GB"
    echo -e "${GREEN}3)${NC} 2GB"
    echo -e "${GREEN}4)${NC} 4GB"
    echo -e "${GREEN}5)${NC} Manually enter value"
    echo -e "${GREEN}6)${NC} No Swap"
    echo ""
    echo -ne "${CYAN}Enter your choice [1-6]: ${NC}"
    read choice

    case $choice in
        1) swap_size="512M";;
        2) swap_size="1G";;
        3) swap_size="2G";;
        4) swap_size="4G";;
        5)
            echo ""
            echo -ne "${YELLOW}Please enter the swap file size (e.g., 300M, 1.5G): ${NC}"
            read swap_size
            ;;
        6)
            echo -e "${RED}No swap file will be created. Exiting...${NC}"
            return 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting without changes.${NC}"
            return 1
            ;;
    esac

    swap_file="/swapfile"
    dd if=/dev/zero of=$swap_file bs=1M count=$(echo $swap_size | grep -oP '^\d+') status=progress

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error creating swap file. Exiting...${NC}"
        return 1
    fi

    chmod 600 $swap_file
    mkswap $swap_file

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error setting up swap space. Exiting...${NC}"
        return 1
    fi

    swapon $swap_file

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error enabling swap file. Exiting...${NC}"
        return 1
    fi

    echo "$swap_file swap swap defaults 0 0" >> /etc/fstab

    echo -e "${BLUE}Modifying swap usage threshold (vm.swappiness)...${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n"
    echo ""

    swap_value=10
    if grep -q "^vm.swappiness" /etc/sysctl.conf; then
        sed -i "s/^vm.swappiness=.*/vm.swappiness=$swap_value/" /etc/sysctl.conf
    else
        echo "vm.swappiness=$swap_value" >> /etc/sysctl.conf
    fi
    sysctl -p

    echo ""
    echo -e "${GREEN}Swap file created and vm.swappiness set to ${RED}$swap_value${NC}."
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

    cat <<EOL > /etc/sysctl.d/ip_forward.conf
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
EOL

    sysctl -p /etc/sysctl.d/ip_forward.conf

    if sysctl -a | grep -q 'disable_ipv6.*=.*1' || grep -q 'disable_ipv6.*=.*1' /etc/sysctl.{conf,d/*}; then
        sed -i '/disable_ipv6/d' /etc/sysctl.{conf,d/*}
        echo 'net.ipv6.conf.all.disable_ipv6 = 0' > /etc/sysctl.d/ipv6.conf
        sysctl -w net.ipv6.conf.all.disable_ipv6=0
    fi

    echo ""
    echo -e "${GREEN}IPv6 support enabled.${NC}"
    echo ""
}

remove_old_sysctl() {
    clear
    title="Optimizing System Configuration and Updating sysctl Configs"
    logo
    echo ""
    echo -e "${CYAN}$title${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""

    enable_ipv6_support

    sed -i '/1000000/d' /etc/profile

    cat <<EOL > /etc/sysctl.conf
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

    cat <<EOL > /etc/security/limits.conf
* soft     nproc          655350
* hard     nproc          655350
* soft     nofile         655350
* hard     nofile         655350
root soft  nproc          655350
root hard  nproc          655350
root soft  nofile         655350
root hard  nofile         655350
EOL

    sysctl -p

    echo ""
    echo -e "${GREEN}Sysctl configuration and optimization complete.${NC}"
    echo ""
    press_enter
}

grub_tuning() {
    clear
    title="GRUB Configuration and System Tuning"
    logo
    echo ""
    echo -e "${CYAN}$title${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m\n"
    echo ""
    
    echo -e "${YELLOW}Please select the profile for GRUB configuration:${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Gaming Profile"
    echo -e "${GREEN}2)${NC} Virtualization Profile"
    echo -e "${GREEN}3)${NC} Audio Production Profile"
    echo -e "${GREEN}4)${NC} Mobile Profile"
    echo -e "${GREEN}5)${NC} No Changes"
    echo ""
    echo -ne "${CYAN}Enter your choice [1-5]:${NC} "
    read choice

    case $choice in
        1)
            grub_cmdline="quiet splash preempt=full"
            ;;
        2)
            grub_cmdline="quiet splash preempt=full nohz_full=all"
            ;;
        3)
            grub_cmdline="quiet splash preempt=full nohz_full=all threadirqs"
            ;;
        4)
            grub_cmdline="quiet splash preempt=full rcu_nocbs=all rcutree.enable_rcu_lazy=1"
            ;;
        5)
            echo -e "${RED}No changes made to GRUB configuration.${NC}"
            return 0
            ;;
        *)
            echo -e "${RED}Invalid choice. No changes made.${NC}"
            return 1
            ;;
    esac

    cp /etc/default/grub /etc/default/grub.bak

    sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$grub_cmdline\"/" /etc/default/grub

    echo -e "${YELLOW}Updating GRUB configuration...${NC}"
    update-grub

    echo -e "${GREEN}GRUB configuration updated successfully!${NC}"
    echo -e "${YELLOW}Reboot your system to apply the changes.${NC}"
    echo ""
    press_enter
}

optimize_ssh_configuration() {
    clear
    SSH_PATH="/etc/ssh/sshd_config"
    title="Improve SSH Configuration and Optimize SSHD"
    logo
    echo -e "${CYAN}$title${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""
    
    if [ -f "$SSH_PATH" ]; then
        cp "$SSH_PATH" "${SSH_PATH}.bak"
        echo -e "${YELLOW}Backup of the original SSH configuration created at ${SSH_PATH}.bak${NC}"
    else
        echo -e "${RED}Error: SSH configuration file not found at ${SSH_PATH}.${NC}"
        return 1
    fi

    cat <<EOL > "$SSH_PATH"
# Optimized SSH configuration for improved security and performance

# Disable DNS lookups to speed up SSH logins
UseDNS no

# Enable compression for faster data transfer
Compression yes

# Strong encryption ciphers
Ciphers aes256-ctr,chacha20-poly1305@openssh.com

# Keep connections alive, preventing idle disconnects
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 3

# Allow forwarding and tunneling (modify as needed for security)
AllowAgentForwarding yes
AllowTcpForwarding yes
GatewayPorts no
PermitTunnel yes

# Disable root login for security (Uncomment to enable)
# PermitRootLogin no

# Custom banner for unauthorized access warning
Banner /etc/ssh/banner

# Disable X11 forwarding if not required
X11Forwarding no

# Disable printing of MOTD (Message of the Day) to reduce login clutter
PrintMotd no

# Log the last login for auditing purposes
PrintLastLog yes

# Limit the maximum number of authentication attempts (Uncomment to enable)
# MaxAuthTries 3

# Limit login grace time (Uncomment to enable)
# LoginGraceTime 1m

EOL

    echo "WARNING: Unauthorized access to this system is prohibited." > /etc/ssh/banner

    if service ssh restart; then
        echo -e "${GREEN}SSH and SSHD configuration and optimization complete.${NC}"
    else
        echo -e "${RED}Failed to restart SSH service. Please check the configuration.${NC}"
        return 1
    fi

    echo ""
    press_enter
}


ask_bbr_version() {
    clear
    title="Select a TCP Congestion Control"
    logo
    echo ""
    echo -e "${CYAN}${title}${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""
    echo -e "${RED}1. ${YELLOW}TCP-BBR (Basic BBR)${NC}"
    echo -e "${RED}2. ${YELLOW}XanMod & BBRv3${NC}"
    echo -e "${RED}3. ${YELLOW}OpenVZ BBR${NC}"
    echo ""
    echo -e "${RED}0. ${YELLOW}No TCP Congestion Control${NC}"
    echo ""
    echo -ne "${CYAN}Enter your choice [0-3]: ${NC}"
    read -r choice

    case $choice in
        1)
            echo -e "${YELLOW}Installing and configuring TCP-BBR...${NC}"
            wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh && chmod +x bbr.sh && ./bbr.sh
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Kernel parameter optimization for TCP-BBR was successful.${NC}"
            else
                echo -e "${RED}TCP-BBR installation failed. Please check the script or try again.${NC}"
            fi
            ;;
        2)
            echo -e "${YELLOW}Installing and configuring XanMod & BBRv3...${NC}"
            if [[ -f /etc/os-release && $(grep -Ei 'ubuntu|debian' /etc/os-release) ]]; then
                bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}XanMod & BBRv3 installation was successful.${NC}"
                else
                    echo -e "${RED}XanMod & BBRv3 installation failed. Please check the script or try again.${NC}"
                fi
            else
                echo -e "${RED}This script is intended for Ubuntu or Debian systems only.${NC}"
            fi
            ;;
        3)
            echo -e "${YELLOW}Optimizing kernel parameters for OpenVZ BBR...${NC}"
            if [ -d "/proc/vz" ] && [ -e /sys/class/net/venet0 ]; then
                cp /etc/sysctl.conf /etc/sysctl.conf.bak
                sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
                sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
                tc qdisc add dev venet0 root fq_codel
                sysctl -w net.ipv4.tcp_congestion_control=bbr
                sysctl -p
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}Kernel parameter optimization for OpenVZ was successful.${NC}"
                else
                    echo -e "${RED}Optimization failed. Restoring original sysctl configuration.${NC}"
                    mv /etc/sysctl.conf.bak /etc/sysctl.conf
                fi
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
            echo "Error: Supported package manager not found. You may need to install Speedtest manually."
            return 1
        fi

        if curl -s $speedtest_install_script | bash; then
            echo "Speedtest repository added successfully."
        else
            echo "Error: Failed to add the Speedtest repository."
            return 1
        fi

        $pkg_manager install -y speedtest
    fi

    if command -v speedtest &>/dev/null; then
        speedtest
    else
        echo "Error: Speedtest is not installed."
    fi
}

benchmark() {
    clear
    title="Benchmark (iperf test)"
    logo
    echo ""
    echo -e "${CYAN}${title}${NC}"
    echo ""
    echo -e "\e[93m+-------------------------------------+\e[0m"
    echo ""

    if ! command -v wget &>/dev/null; then
        apt-get install wget -y
    fi

    echo ""
    echo -e "${MAGENTA} TIP! ${NC}"
    echo -e "${YELLOW} THIS TEST TAKES A LONG TIME, SO PLEASE BE PATIENT ${NC}"
    echo ""
    echo -e "${GREEN}Valid Regions: ${YELLOW} na, sa, eu, au, asia, africa, middle-east, india, china, iran${NC}"
    echo -ne "Please type the destination: "
    read -r location

    echo ""

    if wget -qO- network-speed.xyz | bash -s -- -r "$location"; then
        echo -e "${GREEN}Benchmark test completed successfully.${NC}"
    else
        echo -e "${RED}Error: Failed to run the benchmark test.${NC}"
    fi

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
    yt_title="youtube.com/@opiran-institute"
    clear
    logo
    echo -e "\e[93m╔═══════════════════════════════════════════════╗\e[0m"  
    echo -e "\e[93m║            \e[94mVPS OPTIMIZER                      \e[93m║\e[0m"   
    echo -e "\e[93m╠═══════════════════════════════════════════════╣\e[0m"
    echo ""
    echo -e "${BLUE}   ${tg_title}   ${NC}"
    echo -e "${BLUE}   ${yt_title}   ${NC}"
    echo ""
    echo -e "\e[93m+-----------------------------------------------+\e[0m" 
    echo ""
    printf "${GREEN} 1) ${NC} Optimizer (1-click)${NC}\n"
    printf "${GREEN} 2) ${NC} Optimizer (step by step)${NC}\n"
    echo ""
    printf "${GREEN} 3) ${NC} Swap Menu${NC}\n"
    printf "${GREEN} 4) ${NC} BBR Menu${NC}\n"
    echo ""
    printf "${GREEN} 5) ${NC} GRUB Optimization Menu${NC}\n"
    echo ""
    printf "${GREEN} 6) ${NC} Speedtest${NC}\n"
    printf "${GREEN} 7) ${NC} Benchmark VPS${NC}\n"
    echo ""
    echo -e "\e[93m+-----------------------------------------------+\e[0m" 
    echo ""
    printf "${GREEN} E) ${NC} Exit the menu${NC}\n"
    echo ""
    echo -ne "${GREEN}Select an option: ${NC}"
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
        4)
            ask_bbr_version
            ;;
        5)
            grub_tuning
            ;;
        6)
            speedtestcli
            ;;
        7)
            benchmark
            ;;        
        E|e)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter a valid option.${NC}"
            ;;
    esac

    echo -e "\n${RED}Press Enter to continue...${NC}"
    read -r
done

done
