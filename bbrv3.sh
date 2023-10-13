#!/bin/bash

CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
MAGENTA="\e[35m"
NC="\e[0m"

press_enter() {
    echo -e "\n ${RED}Press Enter to continue... ${NC}"
    read
}

logo() {
    echo -e "\n${BLUE}
      ::::::::  ::::::::: ::::::::::: :::::::::      :::     ::::    ::: 
    :+:    :+: :+:    :+:    :+:     :+:    :+:   :+: :+:   :+:+:   :+:  
   +:+    +:+ +:+    +:+    +:+     +:+    +:+  +:+   +:+  :+:+:+  +:+   
  +#+    +:+ +#++:++#+     +#+     +#++:++#:  +#++:++#++: +#+ +:+ +#+    
 +#+    +#+ +#+           +#+     +#+    +#+ +#+     +#+ +#+  +#+#+#     
#+#    #+# #+#           #+#     #+#    #+# #+#     #+# #+#   #+#+#      
########  ###       ########### ###    ### ###     ### ###    ####       
    ${NC}\n"
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

    cpu_support_level=1
    cpu_support_level=2
    cpu_support_level=3
    cpu_support_level=4

    while read -r line; do
        if [[ $line =~ "flags" ]]; then
            while read -r line; do
                case $line in
                    *"lm"* | *"cmov"* | *"cx8"* | *"fpu"* | *"fxsr"* | *"mmx"* | *"syscall"* | *"sse2"*)
                        cpu_support_level=1
                        ;;
                    *"cx16"* | *"lahf"* | *"popcnt"* | *"sse4_1"* | *"sse4_2"* | *"ssse3"*)
                        [ $cpu_support_level -eq 1 ] && cpu_support_level=2
                        ;;
                    *"avx"* | *"avx2"* | *"bmi1"* | *"bmi2"* | *"f16c"* | *"fma"* | *"abm"* | *"movbe"* | *"xsave"*)
                        [ $cpu_support_level -eq 2 ] && cpu_support_level=3
                        ;;
                    *"avx512f"* | *"avx512bw"* | *"avx512cd"* | *"avx512dq"* | *"avx512vl"*)
                        [ $cpu_support_level -eq 3 ] && cpu_support_level=4
                        ;;
                esac
            done
        fi
    done < /proc/cpuinfo

    if [[ $cpu_support_level -ge 1 && $cpu_support_level -le 4 ]]; then
        echo -e "${CYAN}Current OS : ${GREEN}$os${NC}"
        echo -e "${CYAN}Current CPU Level : ${GREEN}x86-64 Level $cpu_support_level${NC}"
        return $cpu_support_level
    else
        echo -e "${RED}OS or CPU level is not supported by the XanMod kernel and cannot be installed.${NC}"
        return 0
    fi
}

install_xanmod() {
    clear
    cpu_support_info=$(/usr/bin/awk -f <(wget -qO - https://github.com/opiran-club/VPS-Optimizer/raw/main/check_x86-64_psabi.sh))
    if [[ $cpu_support_info == "CPU supports x86-64-v"* ]]; then
        cpu_support_level=${cpu_support_info#CPU supports x86-64-v}
        echo -e "${CYAN}Current OS : ${GREEN}$os${NC}"
        echo -e "${CYAN}Current CPU Level : ${GREEN}x86-64 Level $cpu_support_level${NC}"
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

        temp_folder=$(mktemp -d)
        cd $temp_folder
        cpu_level
            case $cpu_support_level in
                1)
                    wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
                    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
                    sudo apt update && sudo apt install linux-xanmod-x64v1
                    ;;
                2)
                    headers_file="linux-headers-6.1.46-x64v2-xanmod1_6.1.46-x64v2-xanmod1-0.20230816.g11dcd23_amd64.deb"
                    image_file="linux-image-6.1.46-x64v2-xanmod1_6.1.46-x64v2-xanmod1-0.20230816.g11dcd23_amd64.deb"
                    headers_md5="45c85d1bcb07bf171006a3e34b804db0"
                    image_md5="63c359cef963a2e9f1b7181829521fc3"
                    ;;
                3)
                    headers_file="linux-headers-6.1.46-x64v3-xanmod1_6.1.46-x64v3-xanmod1-0.20230816.g11dcd23_amd64.deb"
                    image_file="linux-image-6.1.46-x64v3-xanmod1_6.1.46-x64v3-xanmod1-0.20230816.g11dcd23_amd64.deb"
                    headers_md5="6ae3e253a8aeabd80458df4cb4da70cf"
                    image_md5="d6ea43a2a6686b86e0ac23f800eb95a4"
                    ;;
                4)
                    headers_file="linux-headers-6.1.46-x64v4-xanmod1_6.1.46-x64v4-xanmod1-0.20230816.g11dcd23_amd64.deb"
                    image_file="linux-image-6.1.46-x64v4-xanmod1_6.1.46-x64v4-xanmod1-0.20230816.g11dcd23_amd64.deb"
                    headers_md5="9c41a4090a8068333b7dd56b87dd01df"
                    image_md5="7d30eef4b9094522fc067dc19f7cc92e"
                    ;;
                *)
                     echo -e "${RED}Your CPU is not supported by the XanMod kernel and cannot be installed.${NC}"
                        return 1
                        ;;
            esac

            wget "https://github.com/SuperNG6/linux-setup.sh/releases/download/0816/$headers_file"
            wget "https://github.com/SuperNG6/linux-setup.sh/releases/download/0816/$image_file"

            if [ "$(md5sum $headers_file | awk '{print $1}')" != "$headers_md5" ]; then
                echo -e "${RED}The downloaded ${YELLOW} $headers_file MD5 value does not match. The file may have been tampered with.${NC}"
                return 1
            fi

            if [ "$(md5sum $image_file | awk '{print $1}')" != "$image_md5" ]; then
                echo -e "${RED}The downloaded ${YELLOW} $image_file MD5 value does not match, the file may have been tampered with.${NC}"
                return 1
            fi

            dpkg -i linux-image-*xanmod*.deb linux-headers-*xanmod*.deb

            if [ $? -eq 0 ]; then
            echo -e "${GREEN}The XanMod kernel has been installed successfully.${NC}"
            echo -e "${YELLOW}Do you need to update the GRUB boot configuration? (y/n) [Default: y]:${NC}"
            read grub

            case $grub in
                [Yy])
                    update-grub
                    echo -e "${GREEN}The GRUB boot configuration has been updated.${NC}"
                    echo -e "${GREEN}To enable BBRv3, please restart and run the BBR optimization option.${NC}"
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

        rm -f "$image_file" "$headers_file"
    elif [[ $continue == [Nn] ]]; then
        echo ""
        echo -e "${RED}Installation of the XanMod kernel was aborted.${NC}"
    else
        echo ""
        echo -e "${RED}Invalid option.${NC}"
    fi
}

uninstall_xanmod() {
    clear
    current_kernel_version=$(uname -r)
    cpu_level

    if [[ $current_kernel_version == *-xanmod* ]]; then
        echo -e "${CYAN}Current kernel: ${GREEN}$current_kernel_version${NC}"
        echo -e "${RED}Uninstalling XanMod Kernel...${NC}"
        echo ""
        echo -e "${GREEN}Do you want to uninstall the XanMod kernel and restore the original kernel? (y/n): ${NC}"
        read confirm

        if [[ $confirm == [yY] ]]; then
            echo -e "${GREEN}Uninstalling XanMod kernel and restoring the original kernel...${NC}"
            apt-get purge linux-image-*xanmod* linux-headers-*xanmod* -y
            apt-get purge linux-xanmod-x64v1
            apt-get autoremove -y
            update-grub

            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}The XanMod kernel has been uninstalled, and the original kernel has been restored.${NC}"
                echo -e "${GREEN}The Grub boot configuration has been updated. Please reboot to take effect.${NC}"
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
    echo -e "${CYAN}Are you sure you want to optimize kernel parameters? (y/n): ${NC}"
    read optimize_choice

    case $optimize_choice in
        y|Y)
            clear
            echo -e "${YELLOW}Backing up original kernel parameter configuration... ${NC}"
            cp /etc/sysctl.conf /etc/sysctl.conf.bak
            echo -e "${YELLOW}Optimizing kernel parameters... ${NC}"
            
            cat <<EOL >> /etc/sysctl.conf
# BBRv3 Optimization
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_notsent_lowat=16384
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOL

            sysctl -p
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Kernel parameter optimization was successful.${NC}"
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
    title_text="BBRv3 Optimization Script using xanmod kernel"
    tg_title="TG-Group @OPIranCluB"
    yt_title="youtube.com/@opiran-inistitute"
    clear
    echo -e "                 ${MAGENTA}${title_text}${NC}"
    echo -e "${YELLOW}______________________________________________________${NC}"
    logo
    echo -e ""
    echo -e "${BLUE}$tg_title ${NC}"
    echo -e "${BLUE}$yt_title  ${NC}"
    echo -e "${YELLOW}______________________________________________________${NC}"
    echo ""
    echo -e "${CYAN}linux version Info：${GREEN}${linux_version}${NC}"
    echo -e "${CYAN}kernel Info：${GREEN}${kernel_version}${NC}"
    cpu_level
    echo ""
    echo -e "${RED} !! TIP !! ${NC}"
    echo -e "${CYAN}Supported OS: ${GREEN}Ubuntu / Debian ${CYAN} CPU level ${GREEN} [1/2/3/4] ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
    echo ""
    echo -e "${GREEN} 1) ${NC} Install grub boot & xanmod kernel (Neccessary for BBRv3)${NC}"
    echo -e "${GREEN} 2) ${NC} BBRv3 optimization${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
    echo ""
    echo -e "${GREEN} 3) ${NC} Rolling back and restore the original kernel${NC}"
    echo -e "${GREEN} E) ${NC} Exit the menu${NC}"
    echo ""
    echo -ne "${GREEN}Select an option ${RED}[1-3]: ${NC}"
    read choice

    case $choice in
 
        1)
            install_xanmod
            ;;
        2)
            bbrv3
            ;;
        3)
            uninstall_xanmod
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
