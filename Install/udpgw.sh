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
    clear
    echo ""
    echo ""
    printf "Default Port is \e[33m7300\e[0m,"
    echo ""
    echo -ne "${YELLOW}Enter the UDPGW Port (e.g., 7100): ${NC}"
    read port_identifier
        
    if [[ ! "$port_identifier" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid numeric identifier. Please enter a valid number.${NC}"
        return
    fi
    
    new_port=$port_identifier

    if systemctl is-active --quiet "videocall-$port_identifier"; then
        echo -e "${RED}Port $new_port is already in use. Please choose a different identifier.${NC}"
        return
    fi

    apt-get update -y
    wget -O /bin/badvpn-udpgw "https://github.com/opiran-club/VPS-Optimizer/raw/main/Install/badvpn-udpgw"
    chmod +x /bin/badvpn-udpgw
    useradd videocall

    cat >  "/etc/systemd/system/videocall-$port_identifier.service" << ENDOFFILE
[Unit]
Description=UDP forwarding for extra BadVPN UDPGW
After=nss-lookup.target

[Service]
ExecStart=/bin/badvpn-udpgw --listen-addr 127.0.0.1:$port_identifier --max-clients 200
User=videocall

[Install]
WantedBy=multi-user.target
ENDOFFILE

    systemctl daemon-reload
    systemctl enable "videocall-$port_identifier"
    systemctl start "videocall-$port_identifier"

    echo -e "${GREEN}UDPGW Port $port_identifier added to BadVPN service${NC}"

}

change_badvpn_port() {
    clear
    echo -e "${GREEN}Active BadVPN UDPGW Ports:${NC}"
    
    active_ports=()
    
    for service in $(systemctl list-units --type=service --full --all | grep -o 'videocall-[0-9]*.service'); do
        port=$(echo $service | awk -F'-' '{print $3}')
        active_ports+=("$port")
        echo -e "${CYAN}Port $port${NC}"
    done

    if [ ${#active_ports[@]} -eq 0 ]; then
        echo -e "${CYAN}No active BadVPN UDPGW ports found.${NC}"
        return
    fi

    echo ""
    echo -ne "${YELLOW}Enter the port number to modify: ${NC}"
    read chosen_port

    if [[ ! "$chosen_port" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid port number. Please enter a valid number.${NC}"
        return
    fi

    if ! [[ " ${active_ports[@]} " =~ " $chosen_port " ]]; then
        echo -e "${RED}Port $chosen_port is not an active BadVPN UDPGW port. Please select an active port.${NC}"
        return
    fi

    echo -ne "${YELLOW}Enter the new port number for UDPGW (leave it blank to use the existing port $chosen_port): ${NC}"
    read new_port

    if [ -z "$new_port" ]; then
        new_port=$chosen_port
    fi

    # Stop and disable the old service
    systemctl stop videocall-$chosen_port
    systemctl disable videocall-$chosen_port
    systemctl reset-failed videocall-$chosen_port

    # Delete the old service file
    rm -f /etc/systemd/system/videocall-$chosen_port.service

    sed -i "s/--listen-addr 127.0.0.1:$chosen_port/--listen-addr 127.0.0.1:$new_port/" /etc/systemd/system/videocall-$new_port.service

    systemctl daemon-reload
    systemctl enable videocall-$new_port
    systemctl start videocall-$new_port

    echo -e "${GREEN}BadVPN UDPGW Port $chosen_port updated to $new_port${NC}"
}

add_extra_badvpn_port() {
    clear
    echo ""
    echo -ne "${YELLOW}Enter the UDPGW Port (e.g., 7100): ${NC}"
    read port_identifier
    
    if [[ ! "$port_identifier" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid numeric identifier. Please enter a valid number.${NC}"
        return
    fi
    
    new_port=$port_identifier

    if systemctl is-active --quiet "videocall-$port_identifier"; then
        echo -e "${RED}Port $new_port is already in use. Please choose a different identifier.${NC}"
        return
    fi

    cat >  "/etc/systemd/system/videocall-$port_identifier.service" << ENDOFFILE
[Unit]
Description=UDP forwarding for extra BadVPN UDPGW
After=nss-lookup.target

[Service]
ExecStart=/bin/badvpn-udpgw --loglevel none --listen-addr 127.0.0.1:$port_identifier --max-clients 200
User=videocall

[Install]
WantedBy=multi-user.target
ENDOFFILE

    systemctl daemon-reload
    systemctl enable "videocall-$port_identifier"
    systemctl start "videocall-$port_identifier"

    echo -e "${GREEN}Extra UDPGW Port $port_identifier added to BadVPN service${NC}"
}

uninstall_badvpn() {
    if systemctl is-active --quiet videocall; then
        systemctl stop videocall
        systemctl disable videocall
        systemctl reset-failed videocall
    fi

    for service in $(systemctl list-units --type=service --full --all | grep -o 'videocall-[0-9]*.service'); do
        systemctl stop $service
        systemctl disable $service
        systemctl reset-failed $service
    done

    if [[ -f /bin/badvpn-udpgw ]]; then
        rm -f /bin/badvpn-udpgw
    fi

    # Delete service files
    for service_file in /etc/systemd/system/videocall*.service; do
        if [[ -f "$service_file" ]]; then
            rm -f "$service_file"
        fi
    done

    echo -e "${GREEN}BadVPN uninstalled successfully.${NC}"
}

stop_badvpn() {
    if systemctl is-active --quiet videocall; then
        systemctl stop videocall
        echo -e "${GREEN}BadVPN service stopped.${NC}"
    else
        echo -e "${CYAN}BadVPN service is not currently running.${NC}"
    fi

    for service in $(systemctl list-units --type=service --full --all | grep -o 'videocall-[0-9]*.service'); do
        if systemctl is-active --quiet $service; then
            systemctl stop $service
            echo -e "${GREEN}Extra BadVPN service $service stopped.${NC}"
        fi
    done
}

status() {
    for service in $(systemctl list-units --type=service --full --all | grep 'videocall-[0-9]*.service' -o); do
        port=$(echo $service | awk -F'-' '{print $3}')
        if systemctl is-active --quiet $service; then
            echo -e "${CYAN}BadVPN Service (Port $port) Status:${GREEN} Running${NC}"
        else
            echo -e "${CYAN}BadVPN Service Status:${RED} Not Running${NC}"
        fi
    done
    echo ""
}

while true; do
    title_text="BADVPN (udpgw) "
    tg_title="https://t.me/OPIranCluB"
    yt_title="youtube.com/@opiran-institute"
    clear
    logo
    echo -e "\e[93m╔═══════════════════════════════════════════════╗\e[0m"  
    echo -e "\e[93m║            \e[94mBADVPN (udpgw)                     \e[93m║\e[0m"   
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
            while true; do
                clear
                echo ""
                echo -e "${GREEN} 1) ${NC} Modify port ${NC}"
                echo -e "${GREEN} 2) ${NC} Add extra port ${NC}"
                echo ""
                echo -e "${GREEN} 0) ${NC} Back to the main menu ${NC}"
                echo -ne "${GREEN}Select an option: ${NC}  "
                read choice2
        
                case $choice2 in
                    1)
                        change_badvpn_port
                        ;;
                    2)
                        add_extra_badvpn_port
                        ;;
                    0)
                        break
                        ;;
                esac

                echo -e "\n${RED}Press Enter to continue... ${NC}"
                read
            done
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
