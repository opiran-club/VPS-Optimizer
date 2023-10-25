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

change_badvpn_port() {
    read -p "Enter the new UDPGW Port (leave it blank to use the default): " new_port
    if [ -z "$new_port" ]; then
        new_port=7300  # Default port
    fi

    # Update the BadVPN service configuration
    sed -i "s/--listen-addr 127.0.0.1:[0-9]*/--listen-addr 127.0.0.1:$new_port/" /etc/systemd/system/videocall.service

    # Restart the BadVPN service to apply the changes
    systemctl daemon-reload
    systemctl restart videocall

    echo -e "${GREEN}BadVPN UDPGW Port updated to $new_port${NC}"
}

add_extra_badvpn_port() {
    read -p "Enter the numeric identifier for the new extra UDPGW Port (e.g., 1, 2, 3, ...): " port_identifier
    if [[ ! "$port_identifier" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid numeric identifier. Please enter a valid number.${NC}"
        return
    }

    new_port=$((7100 + port_identifier))  # Calculate the port based on the identifier

    # Check if the new port is already in use
    if systemctl is-active --quiet videocall-extra-$port_identifier; then
        echo -e "${RED}Port $new_port is already in use. Please choose a different identifier.${NC}"
        return
    }

    # Create a new service unit file for the extra port
    cat >  "/etc/systemd/system/videocall-extra-$port_identifier.service" << ENDOFFILE
[Unit]
Description=UDP forwarding for extra BadVPN UDPGW
After=nss-lookup.target

[Service]
ExecStart=/bin/badvpn-udpgw --loglevel none --listen-addr 127.0.0.1:<new_port> --max-clients 200
User=videocall

[Install]
WantedBy=multi-user.target
    ENDOFFILE

    # Reload systemd and start the new service
    systemctl daemon-reload
    systemctl enable "videocall-extra-$port_identifier"
    systemctl start "videocall-extra-$port_identifier"

    echo -e "${GREEN}Extra UDPGW Port $new_port (Identifier $port_identifier) added to a separate BadVPN service${NC}"
}

uninstall_badvpn() {
    if systemctl is-active --quiet videocall; then
        systemctl stop videocall
        systemctl disable videocall
    fi
    
    for service in $(systemctl list-units --type=service --full --all | grep -o 'videocall-extra-[0-9]*.service'); do
        systemctl stop $service
        systemctl disable $service
        systemctl is-active --quiet $service && systemctl reset-failed $service
    done

    if [[ -f /bin/badvpn-udpgw ]]; then
        rm -f /bin/badvpn-udpgw
    }

    echo -e "${GREEN}BadVPN uninstalled successfully.${NC}"
}

stop_badvpn() {
    if systemctl is-active --quiet videocall; then
        systemctl stop videocall
        echo -e "${GREEN}BadVPN service stopped.${NC}"
    else
        echo -e "${CYAN}BadVPN service is not currently running.${NC}"
    fi

    for service in $(systemctl list-units --type=service --full --all | grep -o 'videocall-extra-[0-9]*.service'); do
        if systemctl is-active --quiet $service; then
            systemctl stop $service
            echo -e "${GREEN}Extra BadVPN service $service stopped.${NC}"
        fi
    done
}

status() {
    main_service="videocall"
    port_pattern="--listen-addr 127.0.0.1:"
    
    if systemctl is-active --quiet $main_service; then
        echo -e "${CYAN}Main Service Status:${GREEN} Running${NC}"
    else
        echo -e "${CYAN}Main Service Status:${RED} Not Running${NC}"
    fi

    for service in $(systemctl list-units --type=service --full --all | grep -o 'videocall-extra-[0-9]*.service'); do
        port=$(grep -oP "$port_pattern\K\d+" /etc/systemd/system/$service)
        if systemctl is-active --quiet $service; then
            echo -e "${CYAN}Extra BadVPN Service (Port $port) Status:${GREEN} Running${NC}"
        else
            echo -e "${CYAN}Extra BadVPN Service (Port $port) Status:${RED} Not Running${NC}"
        fi
    done
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
    echo -e "${GREEN} 4) ${NC} Add / Modify port ${NC}"
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
            stop_badvpn
            ;;
        3)
            uninstall_badvpn
            ;;
        4)
            clear
            echo ""
            echo -e "${GREEN} 1) ${NC} Modify port ${NC}"
            echo -e "${GREEN} 2) ${NC} Add extra port ${NC}"
            echo ""
            echo -e "${GREEN} 0) ${NC} Back to main menu ${NC}"
            echo -ne "${GREEN}Select an option: ${NC}  "
            read choice
        
            case $choice in
                 1)
                    change_badvpn_port
                    ;;
                2)
                    add_extra_badvpn_port
                    ;;
                0)
                    return
                    ;;
            esac
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
