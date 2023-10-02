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

press_enter() {
    echo -e "\n ${RED}Press Enter to continue... ${NC}"
    read
}

display_fancy_progress() {
    local duration=$1
    local sleep_interval=0.1
    local progress=0
    local bar_length=40

    while [ $progress -lt $duration ]; do
        echo -ne "\r[${YELLOW}"
        for ((i = 0; i < bar_length; i++)); do
            if [ $i -lt $((progress * bar_length / duration)) ]; then
                echo -ne "▓"
            else
                echo -ne "░"
            fi
        done
        echo -ne "${RED}] ${progress}%"
        progress=$((progress + 1))
        sleep $sleep_interval
    done
    echo -ne "\r[${YELLOW}"
    for ((i = 0; i < bar_length; i++)); do
        echo -ne "#"
    done
    echo -ne "${RED}] ${progress}%"
    echo
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

SYS_PATH="/etc/sysctl.conf"
LIM_PATH="/etc/security/limits.conf"
PROF_PATH="/etc/profile"
SSH_PATH="/etc/ssh/sshd_config"
DNS_PATH="/etc/resolv.conf"

check_if_running_as_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "\n ${RED}This script must be run as root.${NC}"
    exit 1
fi
}

fix_dns() {
  clear
  title="Optimizing System DNS Settings"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
  echo ""
  display_fancy_progress 10
  sed -i '/nameserver/d' $DNS_PATH
  echo 'nameserver 8.8.8.8' >>$DNS_PATH
  echo 'nameserver 8.8.4.4' >>$DNS_PATH
  echo ""
  echo -e "${GREEN}System DNS Optimized.${NC}"
  echo ""
  sleep 1
  press_enter
}

complete_update() {
    clear
  title="Full update and upgrade server system"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
  echo ""
  echo ""
  echo -e "${RED}Please wait, it might couple of minutes${NC}"
  echo ""
  echo ""
  display_fancy_progress 40
  apt-get update > /dev/null 2>&1
  apt-get upgrade -y > /dev/null 2>&1
  sleep 1
    secs=10
    while [ $secs -gt 0 ]; do
        echo -ne "Continuing in $secs seconds\033[0K\r"
        sleep 1
        : $((secs--))
    done
  apt-get dist-upgrade -y > /dev/null 2>&1
  apt-get autoremove -y > /dev/null 2>&1
  apt-get autoclean -y > /dev/null 2>&1
  apt-get clean -y > /dev/null 2>&1
  echo ""
  echo -e "${GREEN}System update & upgrade completed.${NC}"
  echo ""
  sleep 1
  press_enter
}

installations() {
    clear
  title="Install usefull and neccessary packages"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
  echo ""
  echo -e "Please wait, it might take a while"
  echo ""
  sleep 1
    secs=4
    while [ $secs -gt 0 ]; do
        echo -ne "Continuing in $secs seconds\033[0K\r"
        sleep 1
        : $((secs--))
    done
  echo ""
  apt-get purge firewalld -y > /dev/null 2>&1
  apt-get install nload nethogs autossh ssh iperf sshuttle software-properties-common apt-transport-https iptables lsb-release ca-certificates ubuntu-keyring gnupg2 apt-utils cron bash-completion curl git unzip zip ufw wget preload locales nano vim python3 jq qrencode socat busybox net-tools haveged htop curl -y > /dev/null 2>&1
  display_fancy_progress 30
  apt-get install snapd -y > /dev/null 2>&1
  echo ""
  echo -e "${GREEN}Install usefull and neccessary packages completed.${NC}"
  echo ""
  sleep 1
  press_enter
}

enable_packages() {
  systemctl enable preload haveged snapd cron
  press_enter
}

swap_maker() {
    clear
  title="Configure swap file"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
  echo ""
  echo -e "Please wait, it might take a while"
  echo ""
  sleep 1
  echo ""
  display_fancy_progress 10
  SWAP_SIZE=2G
  SWAP_PATH="/swapfile"
  fallocate -l $SWAP_SIZE $SWAP_PATH
  chmod 600 $SWAP_PATH
  mkswap $SWAP_PATH
  swapon $SWAP_PATH
  echo "$SWAP_PATH   none    swap    sw    0   0" >>/etc/fstab
  echo ""
  echo -e "${GREEN}Swap file configured.${NC}"
  echo ""
  sleep 1
  press_enter
}

enable_ipv6_support() {
    clear
  title="Enabling IPV6 Support"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
  echo ""
  if [[ $(sysctl -a | grep 'disable_ipv6.*=.*1') || $(cat /etc/sysctl.{conf,d/*} | grep 'disable_ipv6.*=.*1') ]]; then
    sed -i '/disable_ipv6/d' /etc/sysctl.{conf,d/*}
    echo 'net.ipv6.conf.all.disable_ipv6 = 0' >/etc/sysctl.d/ipv6.conf
    sysctl -w net.ipv6.conf.all.disable_ipv6=0
  fi
  echo ""
  echo -e "${GREEN}IPV6 enables complete${NC}"
  echo ""
  press_enter
}

remove_old_sysctl() {
    clear
  title="OPtimizing system configuration (BBR, Hybla, Swap) and removing old sysctl configs"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
  echo ""
  sed -i '/fs.file-max/d' $SYS_PATH
  sed -i '/fs.inotify.max_user_instances/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_syncookies/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_fin_timeout/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_tw_reuse/d' $SYS_PATH
  sed -i '/net.ipv4.ip_local_port_range/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' $SYS_PATH
  sed -i '/net.ipv4.route.gc_timeout/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_syn_retries/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_synack_retries/d' $SYS_PATH
  sed -i '/net.core.somaxconn/d' $SYS_PATH
  sed -i '/net.core.netdev_max_backlog/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_timestamps/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_max_orphans/d' $SYS_PATH
  sed -i '/net.ipv6.conf.all.disable_ipv6/d' $SYS_PATH
  sed -i '/net.ipv6.conf.default.disable_ipv6/d' $SYS_PATH
  sed -i '/net.ipv6.conf.all.forwarding/d' $SYS_PATH
  sed -i '/soft/d' $LIM_PATH
  sed -i '/hard/d' $LIM_PATH
  sed -i '/net.core.default_qdisc/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_congestion_control/d' $SYS_PATH
  sed -i '/net.ipv4.tcp_ecn/d' $SYS_PATH
  sed -i '/1000000/d' $PROF_PATH
  sed -i '/vm.swappiness/d' $SYS_PATH
  sed -i '/vm.vfs_cache_pressure/d' $SYS_PATH
  echo 'vm.swappiness=10' >>$SYS_PATH
  echo 'vm.vfs_cache_pressure=50' >>$SYS_PATH
  sleep 1
  echo 'fs.file-max = 1000000' >>$SYS_PATH
  echo 'net.core.rmem_default = 1048576' >>$SYS_PATH
  echo 'net.core.rmem_max = 2097152' >>$SYS_PATH
  echo 'net.core.wmem_default = 1048576' >>$SYS_PATH
  echo 'net.core.wmem_max = 2097152' >>$SYS_PATH
  echo 'net.core.netdev_max_backlog = 16384' >>$SYS_PATH
  echo 'net.core.somaxconn = 32768' >>$SYS_PATH
  echo 'net.ipv4.tcp_fastopen = 3' >>$SYS_PATH
  echo 'net.ipv4.tcp_mtu_probing = 1' >>$SYS_PATH
  echo 'net.ipv4.tcp_retries2 = 8' >>$SYS_PATH
  echo 'net.ipv4.tcp_slow_start_after_idle = 0' >>$SYS_PATH
  echo 'net.ipv6.conf.all.disable_ipv6 = 0' >>$SYS_PATH
  echo 'net.ipv6.conf.default.disable_ipv6 = 0' >>$SYS_PATH
  echo 'net.ipv6.conf.all.forwarding = 1' >>$SYS_PATH
  echo 'net.core.default_qdisc = fq' >>$SYS_PATH
  echo 'net.ipv4.tcp_congestion_control = bbr' >>$SYS_PATH
  echo '* soft     nproc          655350' >>$LIM_PATH
  echo '* hard     nproc          655350' >>$LIM_PATH
  echo '* soft     nofile         655350' >>$LIM_PATH
  echo '* hard     nofile         655350' >>$LIM_PATH
  echo 'root soft     nproc          655350' >>$LIM_PATH
  echo 'root hard     nproc          655350' >>$LIM_PATH
  echo 'root soft     nofile         655350' >>$LIM_PATH
  echo 'root hard     nofile         655350' >>$LIM_PATH
  display_fancy_progress 10
  sysctl -p
  echo ""
  echo -e "${GREEN}Sysctl Configuration and optimization complete${NC}"
  echo ""
  press_enter
}

remove_old_ssh_conf() {
    clear
  title="OPtimizing SSH configuration to improve security and performance"
    logo
    echo ""
    echo -e "${BLUE}$title ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________${NC}"
  echo ""
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
  sed -i 's/#UseDNS yes/UseDNS no/' $SSH_PATH
  sed -i 's/#Compression no/Compression yes/' $SSH_PATH
  sed -i 's/Ciphers .*/Ciphers aes256-ctr,chacha20-poly1305@openssh.com/' $SSH_PATH
  sed -i '/MaxAuthTries/d' $SSH_PATH
  sed -i '/MaxSessions/d' $SSH_PATH
  sed -i '/TCPKeepAlive/d' $SSH_PATH
  sed -i '/ClientAliveInterval/d' $SSH_PATH
  sed -i '/ClientAliveCountMax/d' $SSH_PATH
  sed -i '/AllowAgentForwarding/d' $SSH_PATH
  sed -i '/AllowTcpForwarding/d' $SSH_PATH
  sed -i '/GatewayPorts/d' $SSH_PATH
  sed -i '/PermitTunnel/d' $SSH_PATH
  echo "TCPKeepAlive yes" | tee -a $SSH_PATH
  echo "ClientAliveInterval 3000" | tee -a $SSH_PATH
  echo "ClientAliveCountMax 100" | tee -a $SSH_PATH
  echo "PermitRootLogin yes" >>/etc/ssh/sshd_config
  echo "AllowAgentForwarding yes" | tee -a $SSH_PATH
  echo "AllowTcpForwarding yes" | tee -a $SSH_PATH
  echo "GatewayPorts yes" | tee -a $SSH_PATH
  echo "PermitTunnel yes" | tee -a $SSH_PATH
  display_fancy_progress 10
  service ssh restart
  echo ""
  echo -e "${GREEN}SSH and SSHD Configuration and optimization complete${NC}"
  echo ""
  press_enter
}
check_if_running_as_root
sleep 0.5
fix_dns
sleep 0.5
complete_update
sleep 0.5
installations
sleep 0.5
enable_packages
sleep 0.5
swap_maker
sleep 0.5
enable_ipv6_support
sleep 0.5
remove_old_sysctl
sleep 0.5
remove_old_ssh_conf
sleep 0.5
    clear
    logo
    echo ""
    echo -e "${YELLOW}______________________________________________________________${NC}"
    echo ""
    echo ""
    echo -e "${MAGENTA}Please reboot the system to take effect, by running the following command: ${GREEN}reboot${NC}"
    echo ""
    echo -e "${MAGENTA}Please visit me at: ${GREEN}@OPIranCluB ${NC}"
    echo ""
    echo -e "${YELLOW}______________________________________________________________${NC}"
    echo ""
