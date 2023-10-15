### VPS Optimizer One-click (V.1.1) with optional TCP congestion control (Tweaker, Westwood, BBR, BBRv3, Hybla)

##### Summurize configuration
 - Upgrade, Time setting, Install Useful Packages, Optimize the SYSCTL, Optimize SSH
 - TCP congestion control (Tweaker, Westwood, BBR, BBRv3, Hybla)
   
 ##### Details configuration
 - Enable Packages at Server Boot.
 - Create & Enable SWAP File. (Default is 2Gb)
 - Enable IPv6 Support.
 - Clean the Old SYSCTL Settings.
 - SWAP
 - Network
 - Back up the original sshd_config file
 - Disable DNS lookups for connecting clients
 - Enable compression for SSH connections
 - Remove less efficient encryption ciphers
 - Enable and Configure TCP keep-alive messages
 - Allow agent forwarding
 - Allow TCP forwarding
 - Enable gateway ports
 - Enable tunneling
   
---------------------------------------------------------------------------------------------------------------------------------------

###  ‼️ INSTRUCTION ‼️

#### 👉 Debian Base (Ubuntu & Debian)
   
```
apt install curl -y && bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/optimizer.sh --ipv4)
```

---------------------------------------------------------------------------------------------------------------------------------------

### Xanmod kernel and BBRv3 

##### kernel file uploaded by 👉 [superNG](https://github.com/SuperNG6/linux-setup.sh/releases)

![image](https://github.com/opiran-club/VPS-Optimizer/assets/130220895/edb14f2d-7558-4808-9ee6-f69e58cd863a)



###  ‼️ INSTRUCTION ‼️

#### 👉 UBUNTU / DEBIAN
   
```
bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
```

#### ‼️ Manually Instruction

نصب کرنل xanmod و bbrv3 بصورت دستی یا manuall

جهت دریافت لول سی پی یو cpu level
```
bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
```
یا از این اسکریپت استفاده کنید برای تعیین cpu level
```
bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/check.sh --ipv4)
```
خط بالا رو در ترمینال لینوکس پیست کنید و لول سی پی یو رو بهتون میده و سپس خارج بشید

و به ترتیب زیر مراحل را انجام بدید

```
apt update && apt upgrade -y
```

1- Register the PGP key:
```
wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
```

2- Add the repository:
```
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
```

3- Then update and install: 
```
sudo apt update && sudo apt install linux-xanmod-x64v*
```


برای کامند سوم تغییرات به نسبت سی پی یو لول خودتون
```
apt update && apt install linux-xanmod-x64v1

apt update && apt install linux-xanmod-x64v2

apt update && apt install linux-xanmod-x64v3

apt update && apt install linux-xanmod-x64v4
```

اگر دبیان بیس هستید اقدام کنید (اوبونتو یا دبیان)

4- Reboot.
after complete succesfully reboot VPS


برای حذف کردن کرنل و برگشت به حالت قبل

```
apt-get purge linux-xanmod-x64v*
```

که با شماره سی پی یو لول خودتون کامل کنید


---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
### Credits
 - credited by [OPIran](https://github.com/opiran-club)

### Contacts
 - Visit Me at [OPIran-Gap](https://t.me/opiranclub)

