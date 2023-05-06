#! /bin/bash
# Auto installer script for dropbear
# FREE-IRAN
#

clear
cd /tmp
echo "You Are Installing the Dropbear script for Debian and Ubuntu FREE-IRAN"
echo "================================================="
echo "" 
echo "update for the first time..."
apt-get update  > /dev/null 2>&1
echo ""
echo "Install Dropbear"
echo ""
apt-get -y install dropbear ssh
sed -i 's/NO_START\=1/NO_START\=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT\=22/DROPBEAR_PORT\=442/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS\=/DROPBEAR_EXTRA_ARGS\=\"\-p 442 \-p 80 \-p 8080 \-p 8484 \-p 143 \-p 109\"/g' /etc/default/dropbear
sed -i 's/#PermitRootLogin prohibit\-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin without\-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service dropbear start
service sshd restart
echo ""
echo ""
echo "Enjoy the Dropbear"
echo "Dropbear currently running port: 442, 80, 8080, 8484, 143, 109"
echo ""
sleep 5 ; reboot
