# VPS Optimizer

Tlegram Channel
``https://t.me/opiranv2rayproxy``

to use this script ssh to your vps with root previllage then copy below ink and paste it to shell

## تغییر نیم سرور سرور به گوگل
با دستور زیر
```
rm -rf /etc/resolv.conf && touch /etc/resolv.conf && echo 'nameserver 8.8.8.8' >> /etc/resolv.conf && echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
```
## Install some Necessary Program
```
sudo apt install wget -y && apt install curl -y 
```

## بهینه سازی سرور TCP-Tweaker
نصب و حذف تنظیمات با دستور زیر 
```
bash <(curl -Ls https://raw.githubusercontent.com/OPIran-CluB/VPS-Optimizer/main/Tweaker.sh --ipv4)
```

# UDPGW for gaming and video call
با دستور زیر
```
bash <(curl -Ls https://raw.githubusercontent.com/OPIran-CluB/VPS-Optimizer/main/UDPGW.sh --ipv4)
```

## Install Stunnel Debian Base
با دستور زیر
```
bash <(curl -Ls https://raw.githubusercontent.com/OPIran-CluB/VPS-Optimizer/main/Stunnel.sh --ipv4)
```

# Apache Auto SSL For Subdomain or Wildcard
با دستور زیر
```
bash <(curl -Ls https://raw.githubusercontent.com/OPIran-CluB/VPS-Optimizer/main/AutoSSL.sh --ipv4)
```

# BBR Debian base
با دستور زیر
```
wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh && chmod 755 /opt/bbr.sh && bash /opt/bbr.sh
```

# BBR CentOS
```
wget "https://github.com/cx9208/bbrplus/raw/master/ok_bbrplus_centos.sh" && chmod +x ok_bbrplus_centos.sh && ./ok_bbrplus_centos.sh
```

# BBR open-vz VM
```
wget --no-check-certificate https://raw.githubusercontent.com/cloudstarry/google-bbr/master/bbrvz.sh && bash bbrvz.sh
```
then to Change Speed up for specific Port Range:
```
nano /root/lkl/run.sh
```
and search for 9000-9999 and change it optioanally then  if you have Natvps select your range 
```
nano /root/lkl/haproxy.cfg
```
and search for 9000-9999 and change it optioanally if you have Natvps select your range 


# Time-Setting
```
dpkg-reconfigure tzdata
```

# Speedtest Debian Base

first you need install snap
```
sudo apt install snapd
```
then
```
snap install speedtest-cli
```
or
```
snap install fast
```
# Snap in Centos
first you need install snap core in centos

```
yum install epel-release -y && install snapd -y
```
```
systemctl enable --now snapd.socket
```
```
ln -s /var/lib/snapd/snap /snap
```
```
snap install core && snap refresh core
```
now you can install anything with this "snap install"

# Automatically Install the latest version of the Docker Engine and Docker compose
```
bash <(curl -Ls https://raw.githubusercontent.com/OPIran-CluB/VPS-Optimizer/main/Docker-DockerCompose.sh --ipv4)
```
