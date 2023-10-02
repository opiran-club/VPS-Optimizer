
# Centos

## Changing Nameservers to Google
## تغییر نیم سرور سرور به گوگل
با دستور زیر
```
rm -rf /etc/resolv.conf && touch /etc/resolv.conf && echo 'nameserver 8.8.8.8' >> /etc/resolv.conf && echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
```
-------------------------------------------------------------------------------------------------------------------------------------------------
# TCP-Tweaker & BBR

## بهینه سازی سرور TCP-Tweaker
نصب و حذف تنظیمات با دستور زیر 
```
bash <(curl -Ls https://raw.githubusercontent.com/OPIran-CluB/VPS-Optimizer/main/Tweaker.sh --ipv4)
```
## Hybla 

دستور زیر را اجرا کنید:

```
nano /etc/security/limits.conf
```
دو خط زیر را به انتهای فایل باز شده اضافه کنید.

```
* soft nofile 51200 
* hard nofile 51200
```
به ترتیب با زدن دکمه‌های ctrl + x و y و enter تغییرات را ذخیره کرده و فایل را ببندید. و دستور زیر را اجرا کنید:

```
ulimit -n 51200
```
دستور زیر را اجرا کنید:
```
nano /etc/sysctl.conf
```
خطوط زیر را در انتهای فایل اضافه کنید:

```
fs.file-max = 51200 
net.core.netdev_max_backlog = 250000 
net.core.rmem_max = 67108864 
net.core.somaxconn = 4096 
net.core.wmem_max = 67108864 
net.ipv4.ip_forward=1 
net.ipv4.ip_local_port_range = 10000 65000 
net.ipv4.tcp_congestion_control = hybla 
net.ipv4.tcp_fastopen = 3 
net.ipv4.tcp_fin_timeout = 30 
net.ipv4.tcp_keepalive_time = 1200 
net.ipv4.tcp_max_syn_backlog = 8192 
net.ipv4.tcp_max_tw_buckets = 5000 
net.ipv4.tcp_mem = 25600 51200 102400 
net.ipv4.tcp_mtu_probing = 1 
net.ipv4.tcp_rmem = 4096 87380 67108864 
net.ipv4.tcp_syncookies = 1 
net.ipv4.tcp_tw_recycle = 0 
net.ipv4.tcp_tw_reuse = 1 
net.ipv4.tcp_wmem = 4096 65536 67108864
```
بعد از سیو کردن فایل بالا سرور را ریبوت کنید
-----------------------------------------------------------------------------------------------------------------------------------------------------------
## BBR CentOS
```
wget "https://github.com/cx9208/bbrplus/raw/master/ok_bbrplus_centos.sh" && chmod +x ok_bbrplus_centos.sh && ./ok_bbrplus_centos.sh
```
-----------------------------------------------------------------------------------------------------------------------------------------------------------

## A) UDPGW for gaming and video call
با دستور زیر
```
bash <(curl -Ls https://raw.githubusercontent.com/OPIran-CluB/VPS-Optimizer/main/UDPGW.sh --ipv4)
```

## D) Time-Setting
```
dpkg-reconfigure tzdata
```

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

# BBR For OPENVZ VM

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

