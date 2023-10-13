### Xanmod kernel and BBRv3 

##### kernel file uploaded by 👉 [superNG](https://github.com/SuperNG6/linux-setup.sh/releases)

![image](https://github.com/opiran-club/VPS-Optimizer/assets/130220895/4ba8e535-5d4a-435d-8e0f-62216da06367)


###  ‼️ INSTRUCTION ‼️

#### 👉 UBUNTU / DEBIAN
   
```
bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
```

#### Manually Instruction

نصب کرنل xanmod و bbrv3 بصورت دستی یا manuall

جهت دریافت لول سی پی یو cpu level
```
bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
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

### VPS Optimizer One-click (V.1.0)

##### Description
 - Update, Upgrade, and Clean the server.
   
 ##### Install Useful Packages.
 - Enable Packages at Server Boot.
 - Create & Enable SWAP File. (Default is 2Gb)
 - Enable IPv6 Support.
 - Clean the Old SYSCTL Settings.
   
 ##### Optimize the SYSCTL Settings.
 - SWAP
 - Network
 - BBR & hybla
   
##### Optimize SSH.
 - Back up the original sshd_config file
 - Disable DNS lookups for connecting clients
 - Enable compression for SSH connections
 - Remove less efficient encryption ciphers
 - Enable and Configure TCP keep-alive messages
 - Allow agent forwarding
 - Allow TCP forwarding
 - Enable gateway ports
 - Enable tunneling
   
##### Optimize the System Limits.
 - nproc
 - nofile
   
---------------------------------------------------------------------------------------------------------------------------------------

###  ‼️ INSTRUCTION ‼️

#### 👉 UBUNTU
 - Ubuntu server (16+) with root access.
   
```
apt install curl -y && bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/optimizer.sh --ipv4)
```

#### 👉 CentOS

[VISIT HERE](https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/centos.md)

-------------------------------------------------------

![image](https://github.com/opiran-club/VPS-Optimizer/assets/130220895/62af50c5-9b7c-48c1-b8a8-8dbe47ad21b1)

![image](https://github.com/opiran-club/VPS-Optimizer/assets/130220895/d583e73b-fa4f-45ec-8a14-9bc1e0d5dfd3)

![image](https://github.com/opiran-club/VPS-Optimizer/assets/130220895/5632b209-86a3-4bd4-827a-ad4f8f52cd34)

![image](https://github.com/opiran-club/VPS-Optimizer/assets/130220895/015b3e29-d36b-478c-b63e-fb09e42d969e)

![image](https://github.com/opiran-club/VPS-Optimizer/assets/130220895/20445d26-b5cb-40a9-af2a-f3d8e6819f44)

---------------------------------------------------------------------------------------------------------------------------------------

### Credits
 - credited by [OPIran](https://github.com/opiran-club)

### Contacts
 - Visit Me [Telegram-Group](https://t,me/OPIranCluB)


---------------------------------------------------------------------------------------------------------------------------------------


#### 🎁 Donate OPIran 🎁


[👉🏼 Buy Me Coffee 👈🏼](https://hamibash.com/OPIran)

