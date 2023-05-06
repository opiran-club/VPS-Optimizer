#!/bin/bash
# Script Credit by opiranclub
# Support me Thanks
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
blue='\033[0;34m'
ungu='\033[0;35m'
Green="\033[32m"
Red="\033[31m"
WhiteB="\e[0;37m"
BlueCyan="\e[0;36m"
Green_background="\033[42;37m"
Red_background="\033[41;37m"
Suffix="\033[0m"
TO_HOST=90

function lane() {
echo -e " ${BlueCyan}————————————————————————————————————————${Suffix}"
}

function LOGO() {
  clear
	echo -e ""
	echo -e "${BlueCyan} ————————————————————————————————————————${Suffix}"
	echo -e "${ungu}            OPIran-Club            "
	echo -e "${BlueCyan} ————————————————————————————————————————${Suffix}"
	echo -e ""
}
function Credit_Potato() {
sleep 1
echo -e "" 
echo -e "${BlueCyan} ————————————————————————————————————————${Suffix}"
echo -e "${ungu}      Thank you for using-"
echo -e "         Script Credit by OPIran-Club"
echo -e "${BlueCyan} ————————————————————————————————————————${Suffix}"
echo -e ""
exit 0
}

function input_nameserver() {
  _Active=$(systemctl is-active systemd-resolved)
  if [[ "${_Active}" == "inactive" ]]; then
    systemctl enable systemd-resolved
    systemctl start systemd-resolved
    cf=$(cat /etc/resolv.conf | grep -w "nameserver 1.1.1.1")
    gg=$(cat /etc/resolv.conf | grep -w "nameserver 8.8.8.8")
    gg1=$(cat /etc/resolv.conf | grep -w "nameserver 8.8.4.4")
    if [[ "${cf}" == "" ]]; then
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    fi
    if [[ "${gg}" == "" ]]; then
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    fi
    if [[ "${gg1}" == "" ]]; then
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    fi
    systemctl restart systemd-resolved
  else
    cf=$(cat /etc/resolv.conf | grep -w "nameserver 1.1.1.1")
    gg=$(cat /etc/resolv.conf | grep -w "nameserver 8.8.8.8")
    gg1=$(cat /etc/resolv.conf | grep -w "nameserver 8.8.4.4")
    if [[ "${cf}" == "" ]]; then
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    fi
    if [[ "${gg}" == "" ]]; then
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    fi
    if [[ "${gg1}" == "" ]]; then
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    fi
    systemctl restart systemd-resolved
  fi
}
