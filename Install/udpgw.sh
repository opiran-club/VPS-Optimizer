#!/bin/bash
CYAN="\e[96m"
GREEN="\e[92m"
YELLOW="\e[93m"
RED="\e[91m"
BLUE="\e[94m"
MAGENTA="\e[95m"
NC="\e[0m"

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
echo -e "\033[1;34m$logo\033[0m"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "\n ${RED}This script must be run as root.${NC}"
    exit 1
fi
install_badvpn() {
udpport=7300
echo ""
echo ""
printf "Default Port is \e[33m${udpport}\e[0m, let it blank to use this Port: "
echo ""
echo -ne "${YELLOW}input UDPGW Port :${NC}"
read udpport

apt update -y
wget -O /bin/badvpn-udpgw https://github.com/opiran-club/VPS-Optimizer/raw/main/Install/badvpn-udpgw &>/dev/null
chmod +x /bin/badvpn-udpgw

cat >  /etc/systemd/system/videocall.service << ENDOFFILE
[Unit]
Description=UDP forwarding for badvpn-tun2socks
After=nss-lookup.target

[Service]
ExecStart=/bin/badvpn-udpgw --loglevel none --listen-addr 127.0.0.1:${udpport} --max-clients 200
User=videocall

[Install]
WantedBy=multi-user.target
ENDOFFILE

systemctl enable videocall
systemctl start videocall

echo -e "${GREEN}Badvpn installed and started successfuly on port: ${YELLOW}$udpport ${NC}"
}

status() {
    if systemctl is-active --quiet videocall; then
        echo -e "${CYAN}Status: ${GREEN}Running${NC}"
    else
        echo -e "${CYAN}Status: ${RED}Not Running${NC}"
    fi
    echo ""
}

while true; do
    title_text="BADVPN (udpgw) "
    tg_title="https://t.me/OPIranCluB"
    yt_title="youtube.com/@opiran-inistitute"
    clear
    logo
    echo -e "\e[93m╔═══════════════════════════════════════════════╗\e[0m"  
    echo -e "\e[93m║            \e[94mBBRv3 using xanmod kernel          \e[93m║\e[0m"   
    echo -e "\e[93m╠═══════════════════════════════════════════════╣\e[0m"
    echo ""
    echo -e "${BLUE}   ${tg_title}   ${NC}"
    echo -e "${BLUE}   ${yt_title}   ${NC}"
    echo ""
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    status
    printf "\e[93m+-------------------------------------+\e[0m\n" 
    echo ""
    echo -e "${GREEN} 1) ${NC} Install Badvpn ${NC}"
    echo -e "${GREEN} 2) ${NC} Stop badvpn service ${NC}"
    echo -e "${GREEN} 3) ${NC} Uninstall badvpn ${NC}"
    echo ""
    echo -e "${GREEN} E) ${NC} Exit the menu${NC}"
    echo ""
    echo -ne "${GREEN}Select an option: ${NC}  "
    read choice

    case $choice in
 
        1)
            install_badvpn
            ;;
        2)
            badvpnpid="'$(ps x |grep badvpn |grep -v grep |awk '"{'"'print $1'"'})
            kill -9 "'"$badvpnpid" >/dev/null 2>/dev/null
            kill $badvpnpid > /dev/null 2> /dev/null
            kill "$badvpnpid" > /dev/null 2>/dev/null''
            kill $(ps x |grep badvpn |grep -v grep |awk '"{'"'print $1'"'})
            killall badvpn-udpgw
            ;;
        3)
            rm /bin/badvpn && rm /bin/badvpn-udpgw
            systemctl disable videocall
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
