### VPS Optimizer One-click (V.1.1) with optional TCP congestion control (Tweaker, Westwood, BBR, BBRv3, Hybla)

##### Summurize configuration
 - Upgrade, Time setting, Install Useful Packages, Optimize the SYSCTL, Optimize SSH
 - TCP congestion control (Tweaker, Westwood, BBR, BBRv3, Hybla)
 - Swap file + vm.swapiness value 
   
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

![image](https://github.com/opiran-club/VPS-Optimizer/assets/130220895/edb14f2d-7558-4808-9ee6-f69e58cd863a)



###  ‼️ INSTRUCTION ‼️

#### 👉 UBUNTU / DEBIAN
   
```
bash <(curl -s https://raw.githubusercontent.com/opiran-club/VPS-Optimizer/main/bbrv3.sh --ipv4)
```

---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
### Credits
 - credited by [OPIran](https://github.com/opiran-club)

### Contacts
 - Visit Me at [OPIran-Gap](https://t.me/opiranclub)

