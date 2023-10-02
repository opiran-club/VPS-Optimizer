# Optimizer One-click optimizer for servers

به مرور آپدیت میگردد هر مشکلی بود لطفا از طریق تلگرام یا گیتهاب اطلاع بدید

Tlegram Channel
https://t.me/opiranv2rayproxy

Gap Group
https://t.me/OPIranClub

to use this script ssh to your vps with root previllage then copy below ink and paste it to shell


# UBUNTU 
-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
# (V.1.0)
وظایف زیر را انجام می دهد:
 - Update, Upgrade, and Clean the server.
 Install Useful Packages.
 - Enable Packages at Server Boot.
 - Create & Enable SWAP File. (Default is 2Gb)
 - Enable IPv6 Support.
 - Clean the Old SYSCTL Settings.
 Optimize the SYSCTL Settings.
 - SWAP
 - Network
 - BBR & hybla
Optimize SSH.
 - Back up the original sshd_config file
 - Disable DNS lookups for connecting clients
 - Enable compression for SSH connections
 - Remove less efficient encryption ciphers
 - Enable and Configure TCP keep-alive messages
 - Allow agent forwarding
 - Allow TCP forwarding
 - Enable gateway ports
 - Enable tunneling
Optimize the System Limits.
 - nproc
 - nofile
Optimize UFW & Open Common Ports.
Reboot at the end.
### Prerequisites

 - Ubuntu server (16+) with root access.
 - curl
```
sudo apt install -y curl
```

```
bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/optimizer.sh --ipv4)
```

