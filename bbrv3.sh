#!/bin/bash
#
# XanMod kernel and BBRv3 Bash Script
# Author: github.com/opiran-club
#
# It provides options to install required packages, configure XanMod kernel and BBRv3
# download the appropriate configuration and program.
#
# supported architectures: x86_64, amd64
# Supported operating systems: Ubuntu 18.04/20.04/22.04 , Debian 10/11
#
# Usage:
#   - Run the script with root privileges.
#   - Follow the on-screen prompts to install, configure, or uninstall
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
NC="\e[0m"

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

press_enter() {
    echo -e "\n ${RED}Press Enter to continue... ${NC}"
    read
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
echo -e "\033[1;94m$logo\033[0m"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "\n ${RED}This script must be run as root.${NC}"
    exit 1
fi

cpu_level() {
    os=""
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            "debian" | "ubuntu")
                os="Debian/Ubuntu"
                ;;
            "centos")
                os="CentOS"
                ;;
            "fedora")
                os="Fedora"
                ;;
            "arch")
                os="Arch"
                ;;
            *)
                os="Unknown"
                ;;
        esac
    fi

cpu_support_info=$(/usr/bin/awk -f <(wget -qO - https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/checkcpu.sh))
    if [[ $cpu_support_info == "CPU supports x86-64-v"* ]]; then
        cpu_support_level=${cpu_support_info#CPU supports x86-64-v}
        echo -e "${MAGENTA}Current CPU Level:${GREEN} x86-64 Level $cpu_support_level${NC}"
        return $cpu_support_level
    else
        echo -e "${RED}OS or CPU level is not supported by the XanMod kernel and cannot be installed.${NC}"
        return 0
    fi
}

install_xanmod() {
    clear
    cpu_support_info=$(/usr/bin/awk -f <(wget -qO - https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/checkcpu.sh))
    
    if [[ $cpu_support_info == "CPU supports x86-64-v"* ]]; then
        cpu_support_level=${cpu_support_info#CPU supports x86-64-v}
        echo -e "${CYAN}Current CPU Level: x86-64 Level $cpu_support_level${NC}"
    else
        echo -e "${RED}OS or CPU level is not supported by the XanMod kernel and cannot be installed.${NC}"
        return 1
    fi
    echo ""
    echo ""
    echo -e "${YELLOW}     Installing XanMod kernel${NC}"
    echo ""
    echo -e "${CYAN}Kernel official website: https://xanmod.org${NC}"
    echo -e "${CYAN}SourceForge: https://sourceforge.net/projects/xanmod/files/releases/lts/${NC}"
    echo ""
    echo ""
    echo -ne "${YELLOW}Do you want to continue downloading and installing the XanMod kernel? [y/n]:${NC}   "
    read continue

    if [[ $continue == [Yy] ]]; then
        echo ""
        echo ""
        wget -qO - https://gitlab.com/afrd.gpg | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
        echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list

        temp_folder=$(mktemp -d)
        cd $temp_folder

        case $cpu_support_level in
            1)
                apt-get update
                apt-get install linux-xanmod-x64v1 -y
                ;;
            2)
                apt-get update
                apt-get install linux-xanmod-x64v2 -y
                ;;
            3)
                apt-get update
                apt-get install linux-xanmod-x64v3 -y
                ;;
            4)
                apt-get update
                apt-get install linux-xanmod-x64v4 -y
                ;;
            *)
                echo -e "${RED}Your CPU is not supported by the XanMod kernel and cannot be installed.${NC}"
                return 1
                ;;
        esac

        echo -e "${GREEN}The XanMod kernel has been installed successfully.${NC}"
        press_enter
        sleep 0.5
        clear
        echo ""
        echo -e "${GREEN}       GRUB boot updating ${NC}"
        echo ""
        echo ""
        echo -ne "${YELLOW}Do you need to update the GRUB boot configuration? (y/n) [Default: y]:${NC}    "
        read grub

        case $grub in
            [Yy])
                update-grub
                echo ""
                echo -e "${GREEN}The GRUB boot configuration has been updated.${NC}"
                ;;
            [Nn])
                echo -e "${RED}It is not recommended, but the optimization has been aborted.${NC}"
                ;;
            *)
                echo -e "${RED}Invalid option, skipping GRUB boot configuration update.${NC}"
                ;;
        esac
    else
        echo -e "${RED}XanMod kernel installation failed.${NC}"
    fi
}

uninstall_xanmod() {
    clear
    current_kernel_version=$(uname -r)

    if [[ $current_kernel_version == *-xanmod* ]]; then
        echo -e "${CYAN}Current kernel: ${GREEN}$current_kernel_version${NC}"
        echo -e "${RED}Uninstalling XanMod Kernel...${NC}"
        echo ""
        echo -ne "${GREEN}Do you want to uninstall the XanMod kernel and restore the original kernel? (y/n): ${NC}"
        read confirm

        if [[ $confirm == [yY] ]]; then
            echo -e "${GREEN}Uninstalling XanMod kernel and restoring the original kernel...${NC}"
            for i in $(seq 1 4); do
            apt-get purge linux-xanmod-x64v$i -y
            done
            apt-get update
            apt-get autoremove -y
            update-grub

            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}The XanMod kernel has been uninstalled, and the original kernel has been restored.${NC}"
                echo -e "${GREEN}The GRUB boot configuration has been updated. Please reboot to take effect.${NC}"
            else
                echo ""
                echo -e "${RED}XanMod kernel uninstallation failed.${NC}"
            fi
        else
            echo ""
            echo -e "${RED}Canceled the uninstall operation.${NC}"
        fi
    else
        echo ""
        echo -e "${RED}The current kernel is not the XanMod kernel, and the uninstall operation cannot be performed.${NC}"
    fi
}

bbrv3() {
    clear
    echo -e "${CYAN}Are you sure you want to optimize kernel parameters for better network performance? (y/n): ${NC}"
    read optimize_choice

    case $optimize_choice in
        y|Y)
            clear
            echo -e "${YELLOW}Backing up original kernel parameter configuration... ${NC}"
            cp /etc/sysctl.conf /etc/sysctl.conf.bak
            echo -e "${YELLOW}Optimizing kernel parameters for better network performance... ${NC}"

            cat <<EOL >> /etc/sysctl.conf
# BBRv3 Optimization for Better Network Performance
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
EOL

            sysctl -p
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Kernel parameter optimization for better network performance was successful.${NC}"
            else
                echo -e "${RED}Kernel parameter optimization failed. Restoring the original configuration...${NC}"
                mv /etc/sysctl.conf.bak /etc/sysctl.conf
            fi
            ;;
        n|N)
            echo ""
            echo -e "${RED}Canceled kernel parameter optimization.${NC}"
            ;;
        *)
            echo ""
            echo -e "${RED}Invalid input. Optimization canceled.${NC}"
            ;;
    esac
}

while true; do
    linux_version=$(awk -F= '/^PRETTY_NAME=/{gsub(/"/, "", $2); print $2}' /etc/os-release)
    kernel_version=$(uname -r)
    tg_title="https://t.me/OPIranCluB"
    yt_title="youtube.com/@opiran-inistitute"
    clear
    logo
    echo -e "\e[93m╔═══════════════════════════════════════════════╗\e[0m"  
    echo -e "\e[93m║            \e[96mBBRv3 using xanmod kernel          \e[93m║\e[0m"   
    echo -e "\e[93m╠═══════════════════════════════════════════════╣\e[0m"
    echo ""
    echo -e "${CYAN}   ${tg_title}   ${NC}"
    echo -e "${CYAN}   ${yt_title}   ${NC}"
    echo ""
    printf "\e[93m+-----------------------------------------------+\e[0m\n" 
    echo ""
    echo -e "${MAGENTA}linux version Info：${GREEN}${linux_version}${NC}"
    echo -e "${MAGENTA}kernel Info：${GREEN}${kernel_version}${NC}"
    cpu_level
    echo ""
    echo -e "${RED} !! TIP !! ${NC}"
    echo ""
    echo -e "${CYAN}Supported OS: ${GREEN} Ubuntu / Debian ${NC}"
    echo -e "${CYAN}Supported CPU level ${GREEN} [1/2/3/4] ${NC}"
    echo ""
    printf "\e[93m+-----------------------------------------------+\e[0m\n" 
    echo ""
    echo -e "${GREEN} 1) ${NC} Install XanMod kernel & BBRv3 & Grub boot conf. ${NC}"
    echo -e "${GREEN} 2) ${NC} Uninstall XanMod kernel and restore to default ${NC}"
    echo ""
    echo -e "${GREEN} E) ${NC} Exit the menu${NC}"
    echo ""
    echo -ne "${GREEN}Select an option: ${NC}  "
    read choice

    case $choice in
 
        1)
            install_xanmod
            bbrv3
            ask_reboot
            ;;
        2)
            uninstall_xanmod
            ask_reboot
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
