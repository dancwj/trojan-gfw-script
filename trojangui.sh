#!/bin/bash
if [[ $(id -u) != 0 ]]; then
    echo Please run this script as root.
    exit 1
fi
#######color code############
ERROR="31m"      # Error message
SUCCESS="32m"    # Success message
WARNING="33m"   # Warning message
INFO="93m"     # Info message
LINK="95m"     # Share Link Message
#############################

colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}
#########Domain resolve verification###################
isresolved(){
    if [ $# = 2 ]
    then
        myip=$2
    else
        myip=`curl --silent http://dynamicdns.park-your-domain.com/getip`
    fi
    ips=(`nslookup $1 1.1.1.1 | grep -v 1.1.1.1 | grep Address | cut -d " " -f 2`)
    for ip in "${ips[@]}"
    do
        if [ $ip == $myip ]
        then
            return 0
        else
            continue
        fi
    done
    return 1
}
###############User input for option1################
userinput(){
domain=$(whiptail --inputbox --nocancel "朽木不可雕也，糞土之牆不可污也，快输入你的域名并按回车" 8 78 --title "Domain input" 3>&1 1>&2 2>&3)
password1=$(whiptail --passwordbox --nocancel "別動不動就爆粗口，你把你媽揣兜了隨口就說，快输入你想要的密码一并按回车" 8 78 --title "password1 input" 3>&1 1>&2 2>&3)
password2=$(whiptail --passwordbox --nocancel "你別逼我在我和你全家之間加動詞或者是名詞啊，快输入想要的密码二并按回车" 8 78 --title "password2 input" 3>&1 1>&2 2>&3)
}
###############OS detect####################
osdist(){

set -e
 if cat /etc/*release | grep ^NAME | grep CentOS; then
    dist=centos
 elif cat /etc/*release | grep ^NAME | grep Red; then
    dist=centos
 elif cat /etc/*release | grep ^NAME | grep Fedora; then
    dist=centos
 elif cat /etc/*release | grep ^NAME | grep Ubuntu; then
    dist=ubuntu
 elif cat /etc/*release | grep ^NAME | grep Debian; then
    dist=debian
 else
 	TERM=ansi whiptail --title "OS SUPPORT" --infobox "OS NOT SUPPORTED, couldn't install Trojan-gfw" 8 78
    exit 1;
 fi
}
###############Update system################
updatesystem(){
  if [[ $dist = centos ]]; then
    yum update -qq
 elif [[ $dist = ubuntu ]]; then
    apt-get update -qq
 elif [[ $dist = debian ]]; then
    apt-get update -qq
 else
  clear
  TERM=ansi whiptail --title "error can't update system" --infobox "error can't update system" 8 78
    exit 1;
 fi
}
##############Upgrade system optional########
upgradesystem(){
  if [[ $dist = centos ]]; then
    yum upgrade -q -y
 elif [[ $dist = ubuntu ]]; then
    export UBUNTU_FRONTEND=noninteractive 
    apt-get upgrade -q -y
    apt-get autoremove -qq -y > /dev/null
 elif [[ $dist = debian ]]; then
    export DEBIAN_FRONTEND=noninteractive 
    apt-get upgrade -q -y
    apt-get autoremove -qq -y > /dev/null
 else
  clear
  TERM=ansi whiptail --title "error can't upgrade system" --infobox "error can't upgrade system" 8 78
    exit 1;
 fi
}
#########Open ports########################
openfirewall(){
  iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
  iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
  iptables -I OUTPUT -j ACCEPT
}
##########install dependencies#############
installdependency(){
  echo "installing trojan-gfw nginx and acme"
  if [[ $dist = centos ]]; then
    yum install sudo curl socat xz-utils wget apt-transport-https gnupg gnupg2 dnsutils python3-qrcode python-pil unzip resolvconf -qq -y
 elif [[ $dist = ubuntu ]]; then
    apt-get install sudo curl socat xz-utils wget apt-transport-https gnupg gnupg2 dnsutils lsb-release python-pil unzip resolvconf -qq -y
    if [[ $(lsb_release -cs) == xenial ]]; then
    	TERM=ansi whiptail --title "Skipping generating QR code!" --infobox "Ubuntu 16.04 does not support python3-qrcode,Skipping generating QR code!" 8 78
      else
        apt-get install python3-qrcode -qq -y
    fi
 elif [[ $dist = debian ]]; then
    apt-get install sudo curl socat xz-utils wget apt-transport-https gnupg gnupg2 dnsutils lsb-release python3-qrcode python-pil unzip resolvconf -qq -y
 else
  clear
  TERM=ansi whiptail --title "error can't install dependency" --infobox "error can't install dependency" 8 78
    exit 1;
 fi
}
###install trojan-gfw from offical bash####
installtrojan-gfw(){
  bash -c "$(wget -O- https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
}
##########nginx install for cnetos#########
nginxyum(){
  yum install nginx -q -y > /dev/null
}
##########nginx install for debian################
nginxapt(){
  wget https://nginx.org/keys/nginx_signing.key -q
  apt-key add nginx_signing.key
  rm -rf nginx_signing.key
  touch /etc/apt/sources.list.d/nginx.list
  cat > '/etc/apt/sources.list.d/nginx.list' << EOF
deb https://nginx.org/packages/mainline/debian/ $(lsb_release -cs) nginx
deb-src https://nginx.org/packages/mainline/debian/ $(lsb_release -cs) nginx
EOF
  apt-get remove nginx-common -qq -y
  apt-get update -qq
  apt-get install nginx -q -y
}
##########nginx install for ubuntu###############
nginxubuntu(){
  wget https://nginx.org/keys/nginx_signing.key -q
  apt-key add nginx_signing.key
  rm -rf nginx_signing.key
  touch /etc/apt/sources.list.d/nginx.list
  cat > '/etc/apt/sources.list.d/nginx.list' << EOF
deb https://nginx.org/packages/mainline/ubuntu/ $(lsb_release -cs) nginx
deb-src https://nginx.org/packages/mainline/ubuntu/ $(lsb_release -cs) nginx
EOF
  apt-get remove nginx-common -qq -y
  apt-get update -qq
  apt-get install nginx -q -y
}
############install nginx########################
installnginx(){
  if [[ $dist = centos ]]; then
    nginxyum
 elif [[ $dist = ubuntu ]]; then
    nginxubuntu
 elif [[ $dist = debian ]]; then
    nginxapt
 else
  clear
  TERM=ansi whiptail --title "error can't install nginx" --infobox "error can't install nginx" 8 78
    exit 1;
 fi
}
#############install acme#####################
installacme(){
  curl -s https://get.acme.sh | sh
  sudo ~/.acme.sh/acme.sh --upgrade --auto-upgrade > /dev/null
  rm -rf /etc/trojan/
  mkdir /etc/trojan/
}
##################################################
issuecert(){
  systemctl start nginx
  rm -rf /etc/nginx/conf.d/*
  touch /etc/nginx/conf.d/default.conf
    cat > '/etc/nginx/conf.d/default.conf' << EOF
server {
    listen       80;
    server_name  $domain;

    #charset koi8-r;
    #access_log  /var/log/nginx/host.access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\.ht {
    #    deny  all;
    #}
}
EOF
  nginx -s reload
  sudo ~/.acme.sh/acme.sh --issue --nginx -d $domain -k ec-256 --force --log
}
##################################################
renewcert(){
  sudo ~/.acme.sh/acme.sh --issue --nginx -d $domain -k ec-256 --force --log
}
##################################################
installcert(){
  sudo ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/trojan/trojan.crt --keypath /etc/trojan/trojan.key --ecc
}
##################################################
installkey(){
  chmod +r /etc/trojan/trojan.key
}
##################################################
changepasswd(){
  cat > '/usr/local/etc/trojan/config.json' << EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "password1",
        "password2"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/etc/trojan/trojan.crt",
        "key": "/etc/trojan/trojan.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": true,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": true,
        "no_delay": true,
        "keep_alive": true,
        "fast_open": true,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF
  sed  -i "s/password1/$password1/g" /usr/local/etc/trojan/config.json
  sed  -i "s/password2/$password2/g" /usr/local/etc/trojan/config.json
}
########Nginx config for Trojan only##############
nginxtrojan(){
rm -rf /etc/nginx/sites-available/*
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/conf.d/*
touch /etc/nginx/conf.d/trojan.conf
  if [[ $dist != centos ]]; then
    nginxconf
 else
 	TERM=ansi whiptail --title "continuing..." --infobox "continuing..." 8 78
 fi
  cat > '/etc/nginx/conf.d/trojan.conf' << EOF
server {
  listen 127.0.0.1:80;
    server_name $domain;
    location / {
      root /usr/share/nginx/html/;
        index index.html;
        }
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}

server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://$domain;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 444;
}
EOF
nginx -s reload
}
##########Nginx conf####################
nginxconf(){
    cat > '/etc/nginx/nginx.conf' << EOF
user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events {
  worker_connections 1024;
  use epoll;
  multi_accept on;
}

http {
  aio threads;
  charset UTF-8;
  tcp_nodelay on;
  tcp_nopush on;
  server_tokens off;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  access_log /var/log/nginx/access.log;


  log_format  main  '@remote_addr - @remote_user [$time_local] "@request" '
    '@status $body_bytes_sent "@http_referer" '
    '"@http_user_agent" "@http_x_forwarded_for"';

  sendfile on;
  gzip on;

  include /etc/nginx/conf.d/*.conf; 
}
EOF
sed  -i 's/@/$/g' /etc/nginx/nginx.conf
}
##########Auto boot start###############
autostart(){
  systemctl start trojan
  systemctl enable nginx
  systemctl enable trojan
}
##########tcp-bbr#####################
tcp-bbr(){
  cat > '/etc/sysctl.d/99-sysctl.conf' << EOF
#
# /etc/sysctl.conf - Configuration file for setting system variables
# See /etc/sysctl.d/ for additional system variables.
# See sysctl.conf (5) for information.
#

#kernel.domainname = example.com

# Uncomment the following to stop low-level messages on console
#kernel.printk = 3 4 1 3

##############################################################3
# Functions previously found in netbase
#

# Uncomment the next two lines to enable Spoof protection (reverse-path filter)
# Turn on Source Address Verification in all interfaces to
# prevent some spoofing attacks
#net.ipv4.conf.default.rp_filter=1
#net.ipv4.conf.all.rp_filter=1

# Uncomment the next line to enable TCP/IP SYN cookies
# See http://lwn.net/Articles/277146/
# Note: This may impact IPv6 TCP sessions too
#net.ipv4.tcp_syncookies=1

# Uncomment the next line to enable packet forwarding for IPv4
#net.ipv4.ip_forward=1

# Uncomment the next line to enable packet forwarding for IPv6
#  Enabling this option disables Stateless Address Autoconfiguration
#  based on Router Advertisements for this host
#net.ipv6.conf.all.forwarding=1


###################################################################
# Additional settings - these settings can improve the network
# security of the host and prevent against some network attacks
# including spoofing attacks and man in the middle attacks through
# redirection. Some network environments, however, require that these
# settings are disabled so review and enable them as needed.
#
# Do not accept ICMP redirects (prevent MITM attacks)
#net.ipv4.conf.all.accept_redirects = 0
#net.ipv6.conf.all.accept_redirects = 0
# _or_
# Accept ICMP redirects only for gateways listed in our default
# gateway list (enabled by default)
# net.ipv4.conf.all.secure_redirects = 1
#
# Do not send ICMP redirects (we are not a router)
#net.ipv4.conf.all.send_redirects = 0
#
# Do not accept IP source route packets (we are not a router)
#net.ipv4.conf.all.accept_source_route = 0
#net.ipv6.conf.all.accept_source_route = 0
#
# Log Martian Packets
#net.ipv4.conf.all.log_martians = 1
#

###################################################################
# Magic system request Key
# 0=disable, 1=enable all
# Debian kernels have this set to 0 (disable the key)
# See https://www.kernel.org/doc/Documentation/sysrq.txt
# for what other values do
#kernel.sysrq=1

###################################################################
# Protected links
#
# Protects against creating or following links under certain conditions
# Debian kernels have both set to 1 (restricted) 
# See https://www.kernel.org/doc/Documentation/sysctl/fs.txt
#fs.protected_hardlinks=0
#fs.protected_symlinks=0

# Overrule forwarding behavior. Accept Router Advertisements
net.ipv6.conf.all.accept_ra = 2
# max open files
fs.file-max = 51200
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096
# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_max_syn_backlog = 12800
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
  sysctl -p
    cat > '/etc/systemd/system.conf' << EOF
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See systemd-system.conf(5) for details.

[Manager]
#LogLevel=info
#LogTarget=journal-or-kmsg
#LogColor=yes
#LogLocation=no
#DumpCore=yes
#ShowStatus=yes
#CrashChangeVT=no
#CrashShell=no
#CrashReboot=no
#CtrlAltDelBurstAction=reboot-force
#CPUAffinity=1 2
#RuntimeWatchdogSec=0
#ShutdownWatchdogSec=10min
#WatchdogDevice=
#CapabilityBoundingSet=
#NoNewPrivileges=no
#SystemCallArchitectures=
#TimerSlackNSec=
#DefaultTimerAccuracySec=1min
#DefaultStandardOutput=journal
#DefaultStandardError=inherit
#DefaultTimeoutStartSec=90s
DefaultTimeoutStopSec=30s
#DefaultRestartSec=100ms
#DefaultStartLimitIntervalSec=10s
#DefaultStartLimitBurst=5
#DefaultEnvironment=
#DefaultCPUAccounting=no
#DefaultIOAccounting=no
#DefaultIPAccounting=no
#DefaultBlockIOAccounting=no
#DefaultMemoryAccounting=yes
#DefaultTasksAccounting=yes
#DefaultTasksMax=
#DefaultLimitCPU=
#DefaultLimitFSIZE=
#DefaultLimitDATA=
#DefaultLimitSTACK=
#DefaultLimitCORE=
#DefaultLimitRSS=
#DefaultLimitNOFILE=1024:524288
#DefaultLimitAS=
#DefaultLimitNPROC=
#DefaultLimitMEMLOCK=
#DefaultLimitLOCKS=
#DefaultLimitSIGPENDING=
#DefaultLimitMSGQUEUE=
#DefaultLimitNICE=
#DefaultLimitRTPRIO=
#DefaultLimitRTTIME=
DefaultLimitCORE=infinity
DefaultLimitNOFILE=51200
DefaultLimitNPROC=51200
EOF
    cat > '/etc/security/limits.conf' << EOF
# /etc/security/limits.conf
#
#Each line describes a limit for a user in the form:
#
#<domain>        <type>  <item>  <value>
#
#Where:
#<domain> can be:
#        - a user name
#        - a group name, with @group syntax
#        - the wildcard *, for default entry
#        - the wildcard %, can be also used with %group syntax,
#                 for maxlogin limit
#        - NOTE: group and wildcard limits are not applied to root.
#          To apply a limit to the root user, <domain> must be
#          the literal username root.
#
#<type> can have the two values:
#        - "soft" for enforcing the soft limits
#        - "hard" for enforcing hard limits
#
#<item> can be one of the following:
#        - core - limits the core file size (KB)
#        - data - max data size (KB)
#        - fsize - maximum filesize (KB)
#        - memlock - max locked-in-memory address space (KB)
#        - nofile - max number of open file descriptors
#        - rss - max resident set size (KB)
#        - stack - max stack size (KB)
#        - cpu - max CPU time (MIN)
#        - nproc - max number of processes
#        - as - address space limit (KB)
#        - maxlogins - max number of logins for this user
#        - maxsyslogins - max number of logins on the system
#        - priority - the priority to run user process with
#        - locks - max number of file locks the user can hold
#        - sigpending - max number of pending signals
#        - msgqueue - max memory used by POSIX message queues (bytes)
#        - nice - max nice priority allowed to raise to values: [-20, 19]
#        - rtprio - max realtime priority
#        - chroot - change root to directory (Debian-specific)
#
#<domain>      <type>  <item>         <value>
#

#*               soft    core            0
#root            hard    core            100000
#*               hard    rss             10000
#@student        hard    nproc           20
#@faculty        soft    nproc           20
#@faculty        hard    nproc           50
#ftp             hard    nproc           0
#ftp             -       chroot          /ftp
#@student        -       maxlogins       4

# End of file
* soft nofile 51200
* hard nofile 51200
EOF
    cat > '/etc/profile' << EOF
# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).

if [ "${PS1-}" ]; then
  if [ "${BASH-}" ] && [ "$BASH" != "/bin/sh" ]; then
    # The file bash.bashrc already sets the default PS1.
    # PS1='\h:\w\$ '
    if [ -f /etc/bash.bashrc ]; then
      . /etc/bash.bashrc
    fi
  else
    if [ "`id -u`" -eq 0 ]; then
      PS1='# '
    else
      PS1='$ '
    fi
  fi
fi

if [ -d /etc/profile.d ]; then
  for i in /etc/profile.d/*.sh; do
    if [ -r $i ]; then
      . $i
    fi
  done
  unset i
fi
ulimit -SHn 51200
EOF
systemctl daemon-reload
}
##########iptables-persistent########
iptables-persistent(){
  if [[ $dist = centos ]]; then
    yum install iptables-persistent -q -y > /dev/null
 elif [[ $dist = ubuntu ]]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get install iptables-persistent -q -y > /dev/null
 elif [[ $dist = debian ]]; then
    export DEBIAN_FRONTEND=noninteractive 
    apt-get install iptables-persistent -q -y > /dev/null
 else
  clear
  TERM=ansi whiptail --title "error can't install iptables-persistent" --infobox "error can't install iptables-persistent" 8 78
    exit 1;
 fi
}
############DNSMASQ#################
dnsmasq(){
    if [[ $dist = centos ]]; then
    yum install dnsmasq -q -y > /dev/null
 elif [[ $dist = ubuntu ]]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get install dnsmasq -q -y > /dev/null
 elif [[ $dist = debian ]]; then
    export DEBIAN_FRONTEND=noninteractive 
    apt-get install dnsmasq -q -y > /dev/null
 else
  clear
  TERM=ansi whiptail --title "error can't install dnsmasq" --infobox "error can't install dnsmasq" 8 78
    exit 1;
 fi
 if [[ $dist = ubuntu ]]; then
   systemctl stop systemd-resolved
   systemctl disable systemd-resolved
 fi
 mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
 touch /etc/dnsmasq.conf
     cat > '/etc/dnsmasq.conf' << EOF
port=53
domain-needed
bogus-priv
no-resolv
server=8.8.4.4#53
server=1.1.1.1#53
interface=lo
bind-interfaces
listen-address=127.0.0.1
cache-size=10000
no-negcache
log-queries 
log-facility=/var/log/dnsmasq.log 
EOF
echo "nameserver 127.0.0.1" > '/etc/resolv.conf'
systemctl restart dnsmasq
systemctl enable dnsmasq
}
############Set UP V2ray############
v2input(){
domain=$(whiptail --inputbox --nocancel "朽木不可雕也，糞土之牆不可污也，快输入你的域名并按回车" 8 78 --title "Domain input" 3>&1 1>&2 2>&3)
password1=$(whiptail --passwordbox --nocancel "別動不動就爆粗口，你把你媽揣兜了隨口就說，快输入你想要的密码一并按回车" 8 78 --title "password1 input" 3>&1 1>&2 2>&3)
password2=$(whiptail --passwordbox --nocancel "你別逼我在我和你全家之間加動詞或者是名詞啊，快输入想要的密码二并按回车" 8 78 --title "password2 input" 3>&1 1>&2 2>&3)
path=$(whiptail --inputbox --nocancel "Put your thinking cap on.，快输入你的想要的Websocket路径并按回车" 8 78 /secret --title "Websocket path input" 3>&1 1>&2 2>&3)
}
installv2ray(){
  bash <(curl -L -s https://install.direct/go.sh) > /dev/null
  rm -rf /etc/v2ray/config.json
  uuid=$(/usr/bin/v2ray/v2ctl uuid)
  cat > "/etc/v2ray/config.json" << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
        {
            "sniffing": {
            "enabled": true,
            "destOverride": ["http","tls"]
        },
        "port": 10000,
        "listen":"127.0.0.1",
        "protocol": "vmess",
        "settings": {
            "clients": [
                {
                    "id": "$uuid",
                    "alterId": 64
                }
            ]
        },
        "streamSettings": {
            "network": "ws",
            "wsSettings": {
        "path": "$path"
        }
        }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "domain": [
        "baidu.com",
        "qq.com",
        "sina.com",
        "geosite:cn"
      ],
      "outboundTag": "blocked"
      }
    ]
  }
}
EOF
systemctl start v2ray
systemctl enable v2ray
}

nginxv2ray(){
rm -rf /etc/nginx/sites-available/
rm -rf /etc/nginx/sites-enabled/
rm -rf /etc/nginx/conf.d/default.conf
touch /etc/nginx/conf.d/trojan.conf
  if [[ $dist != centos ]]; then
    nginxconf
 else
 	TERM=ansi whiptail --title "continuing..." --infobox "continuing..." 8 78
 fi
  cat > '/etc/nginx/conf.d/trojan.conf' << EOF
server {
  listen 127.0.0.1:80;
    server_name $domain;
    location / {
      root /usr/share/nginx/html/;
        index index.html;
        }
    location $path {
        access_log off;
        proxy_intercept_errors on;
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Early-Data @ssl_early_data;
        proxy_set_header Upgrade @http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host @http_host;
        proxy_set_header X-Real-IP @remote_addr;
        proxy_set_header X-Forwarded-For @proxy_add_x_forwarded_for;
        }
  add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
}

server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://$domain;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 444;
}
EOF
sed  -i 's/@/$/g' /etc/nginx/conf.d/trojan.conf
nginx -s reload
}
###########Trojan Client Config#############
trojanclient(){
  touch /etc/trojan/client1.json
  touch /etc/trojan/client2.json
    cat > '/etc/trojan/client1.json' << EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$myip",
    "remote_port": 443,
    "password": [
        "$password1"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:RSA-AES128-GCM-SHA256:RSA-AES256-GCM-SHA384:RSA-AES128-SHA:RSA-AES256-SHA:RSA-3DES-EDE-SHA",
        "sni": "$domain",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": true,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": true,
        "fast_open_qlen": 20
    }
}
EOF
    cat > '/etc/trojan/client2.json' << EOF
{
    "run_type": "client",
    "local_addr": "127.0.0.1",
    "local_port": 1080,
    "remote_addr": "$myip",
    "remote_port": 443,
    "password": [
        "$password2"
    ],
    "log_level": 1,
    "ssl": {
        "verify": true,
        "verify_hostname": true,
        "cert": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:RSA-AES128-GCM-SHA256:RSA-AES256-GCM-SHA384:RSA-AES128-SHA:RSA-AES256-SHA:RSA-3DES-EDE-SHA",
        "sni": "$domain",
        "alpn": [
            "h2",
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": true,
        "curves": ""
    },
    "tcp": {
        "no_delay": true,
        "keep_alive": true,
        "fast_open": true,
        "fast_open_qlen": 20
    }
}
EOF
}
##########V2ray Client Config################
v2rayclient(){
  touch /etc/v2ray/client.json
  cat > '/etc/v2ray/client.json' << EOF
{
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 8001,
      "protocol": "http",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      }
    },
    {
      "port": 1081,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "settings": {
        "auth": "noauth",
        "udp": false
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "$domain",
            "port": 443,
            "users": [
              {
                "id": "$uuid",
                "alterId": 64,
                "security": "none" //使用TLS则无需二次加密
              }
            ]
          }
        ]
      },
      "streamSettings": {
      "network": "ws",
      "security": "tls",
      "wsSettings": {
        "path": "$path",
        "headers": {
          "Host": "$domain"
        }
      },
      "tlsSetting": {
        "allowInsecure": false,
        "alpn": ["http/1.1","h2"],
        "serverName": "$domain",
        "allowInsecureCiphers": false,
        "disableSystemRoot": false
      },
      "mux": {
        "enabled": false
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "adblock",
      "protocol" : "blackhole",
      "settings": {}
    }
  ],
  "dns": {
    "servers": [
      "8.8.8.8",
      {
        "address": "114.114.114.114",
        "port": 53,
        "domains": [
          "geosite:cn"
        ]
      }
    ]
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:private"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": [
          "geoip:cn"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "geosite:cn"
        ]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "protocol": [
          "bittorrent"
        ]
      },
      {
        "type" :"field",
        "outboundTag": "adblock",
        "domain": ["geosite:category-ads"]
      }
    ]
  }
}
EOF
}
##########Remove Trojan-Gfw##########
removetrojan(){
  systemctl stop trojan
  systemctl disable trojan
  rm -rf /usr/local/etc/trojan/*
  rm -rf /etc/trojan/*
  rm -rf /etc/systemd/system/trojan.service
  rm -rf ~/.acme.sh/$domain
}
##########Remove V2ray###############
removev2ray(){
  systemctl stop v2ray
  systemctl disable v2ray
  systemctl daemon-reload
  cd
  wget https://install.direct/go.sh -q
  sudo bash go.sh --remove
  rm go.sh
}
###########Remove Nginx dnsmasq and acme###############
removenginx(){
  systemctl stop nginx
  systemctl disable nginx
  apt purge nginx -p -y
  apt purge dnsmasq -p -y
  rm -rf /etc/apt/sources.list.d/nginx.list
  sudo ~/.acme.sh/acme.sh --uninstall
}
##########Check for update############
checkupdate(){
  cd
  wget https://install.direct/go.sh -q
  sudo bash go.sh --check
  rm go.sh
  bash -c "$(wget -O- https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
}
###########Trojan share link########
trojanlink(){
  cd
  if [[ $(lsb_release -cs) != xenial ]]; then
  wget https://github.com/trojan-gfw/trojan-url/raw/master/trojan-url.py -q
  chmod +x trojan-url.py
  #./trojan-url.py -i /etc/trojan/client.json
  ./trojan-url.py -q -i /etc/trojan/client1.json -o $password1.png
  ./trojan-url.py -q -i /etc/trojan/client2.json -o $password2.png
  cp $password1.png /usr/share/nginx/html/
  cp $password2.png /usr/share/nginx/html/
  colorEcho ${INFO} "Your Trojan-Gfw Share link1 is"
  colorEcho ${LINK} "trojan://$password1@$domain:443"
  colorEcho ${INFO} "Your Trojan-Gfw Share link2 is"
  colorEcho ${LINK} "trojan://$password2@$domain:443"
  colorEcho ${INFO} "Please visit the link below to get your QR code1"
  colorEcho ${LINK} "https://$domain/$password1.png"
  colorEcho ${INFO} "Please visit the link below to get your QR code2"
  colorEcho ${LINK} "https://$domain/$password2.png"
  rm -rf trojan-url.py
  rm -rf $password1.png
  rm -rf $password2.png
  else
    colorEcho ${ERROR} "QR generate Fail ! Because Ubuntu 16.04 does not support python3-qrcode,Please change your os!"
  fi
}
########V2ray share link############
v2raylink(){
  wget https://github.com/boypt/vmess2json/raw/master/json2vmess.py -q
  chmod +x json2vmess.py
  touch /etc/v2ray/$uuid.txt
  v2link=$(./json2vmess.py --addr $domain --filter ws --amend port:443 --amend tls:tls /etc/v2ray/config.json)
    cat > "/etc/v2ray/$uuid.txt" << EOF
$v2link
EOF
  cp /etc/v2ray/$uuid.txt /usr/share/nginx/html/
  colorEcho ${INFO} "Your v2ray share link is"
  cat /etc/v2ray/$uuid.txt
  colorEcho ${INFO} "Please visit the link below to download your v2ray share link"
  colorEcho ${LINK} "https://$domain/$uuid.txt"
  rm -rf json2vmess.py
  colorEcho ${INFO} "Please manually run cat /etc/v2ray/$uuid.txt to show share link again!"
}
##################################
clear
function advancedMenu() {
    ADVSEL=$(whiptail --title "Trojan-Gfw Script Menu" --menu --nocancel "Choose an option RTFM: https://www.johnrosen1.com/trojan/" 25 78 16 \
        "1" "正常安装" \
        "2" "扩展安装（包含V2ray Websocket三件套）" \
        "3" "检查更新" \
        "4" "完全卸载" \
        "5" "退出" 3>&1 1>&2 2>&3)
    case $ADVSEL in
        1)
        clear
        userinput
        if (whiptail --title "System Upgrade" --yesno --defaultno "System Upgrade?" 8 78); then
    	system_upgrade = 1
		else
    	system_upgrade = 0
		fi
		if (whiptail --title "Dnsmasq Install" --yesno --defaultno "This is an example of a yes/no box." 8 78); then
    	dnsmasq_install = 1
		else
    	dnsmasq_install = 0
		fi
        clear
        colorEcho ${INFO} "Detecting OS version"
        osdist
        colorEcho ${INFO} "Your os codename is $dist $(lsb_release -cs)"
        colorEcho ${INFO} "Updating system"
        updatesystem
        if [[ $system_upgrade = 1 ]]; then
		upgradesystem
		else
		:
		fi
       	if [[ $dnsmasq_install = 1 ]]; then
		dnsmasq
		else
		:
		fi
        clear
        colorEcho ${INFO} "installing dependency"
        installdependency       
        if isresolved $domain
        then
        :
        else 
        colorEcho ${ERROR} "Resolve error,Please check your domain DNS config and vps firewall !"
        exit -1
        clear
        fi
        colorEcho ${INFO} "configing firewall"
        openfirewall
        clear
        colorEcho ${INFO} "installing trojan-gfw"
        installtrojan-gfw
        clear
        colorEcho ${INFO} "installing nginx"
        installnginx
        clear
        colorEcho ${INFO} "installing acme"
        installacme
        clear
        colorEcho ${INFO} "issueing let\'s encrypt certificate"
        issuecert
        clear
        colorEcho ${INFO} "autoconfiging nginx"
        nginxtrojan
        clear
        colorEcho ${INFO} "issue complete,installing certificate"
        installcert
        clear
        colorEcho ${INFO} "certificate install complete!"
        colorEcho ${INFO} "giving private key read authority"
        installkey
        clear
        colorEcho ${INFO} "autoconfiging trojan-gfw"
        changepasswd
        clear
        colorEcho ${INFO} "starting trojan-gfw and nginx | setting up boot autostart"
        autostart
        clear
        colorEcho ${INFO} "Setting up tcp-bbr boost technology"
        tcp-bbr
        clear
        iptables-persistent
        clear
        trojanclient
        colorEcho ${INFO} "Your Trojan-Gfw client config profile 1"
        cat /etc/trojan/client1.json
        colorEcho ${INFO} "Your Trojan-Gfw client config profile 2"
        cat /etc/trojan/client2.json
        trojanlink
        colorEcho ${INFO} "https://github.com/trojan-gfw/trojan/wiki/Mobile-Platforms"
        colorEcho ${INFO} "https://github.com/trojan-gfw/trojan/releases/latest"        
        whiptail --title "Option 1" --msgbox "安装成功，享受吧！多行不義必自斃，子姑待之。RTFM: https://www.johnrosen1.com/trojan/" 8 78
        ;;
        2)    
        v2input
        if (whiptail --title "System Upgrade" --yesno --defaultno "System Upgrade?" 8 78); then
    	system_upgrade=1
		else
    	system_upgrade=0
		fi
		if (whiptail --title "Dnsmasq Install" --yesno --defaultno "Install dnsmasq?." 8 78); then
    	dnsmasq_install=1
		else
    	dnsmasq_install=0
		fi
        clear
        colorEcho ${INFO} "Detecting OS version"
        osdist
        colorEcho ${INFO} "Your os codename is $dist $(lsb_release -cs)"
        colorEcho ${INFO} "Updating system"
        updatesystem
        if [[ $system_upgrade = 1 ]]; then
		upgradesystem
		else
		:
		fi
       	if [[ $dnsmasq_install = 1 ]]; then
		dnsmasq
		else
		:
		fi
        clear
        colorEcho ${INFO} "installing dependency"
        installdependency
        if isresolved $domain
        then
        :
        else 
        colorEcho ${ERROR} "Resolve error,Please check your domain DNS config and vps firewall !"
        exit -1
        fi
        colorEcho ${INFO} "configing firewall"
        openfirewall
        clear
        colorEcho ${INFO} "installing trojan-gfw"
        installtrojan-gfw
        colorEcho ${INFO} "installing nginx"
        installnginx
        colorEcho ${INFO} "installing acme"
        installacme
        clear
        colorEcho ${INFO} "issueing let\'s encrypt certificate"
        issuecert
        colorEcho ${INFO} "issue complete,installing certificate"
        installcert
        colorEcho ${INFO} "certificate install complete!"
        colorEcho ${INFO} "configing nginx for v2ray vmess+tls+Websocket"
        nginxv2ray
        clear
        colorEcho ${INFO} "giving private key read authority"
        installkey
        changepasswd
        colorEcho ${INFO} "installing V2ray"
        installv2ray
        colorEcho ${INFO} "starting trojan-gfw v2ray and nginx | setting up boot autostart"
        autostart
        colorEcho ${INFO} "Setting up tcp-bbr boost technology"
        tcp-bbr
        iptables-persistent
        clear
        trojanclient
        colorEcho ${INFO} "Your Trojan-Gfw client config profile 1"
        cat /etc/trojan/client1.json
        colorEcho ${INFO} "Your Trojan-Gfw client config profile 2"
        cat /etc/trojan/client2.json
        trojanlink
        colorEcho ${INFO} "https://github.com/trojan-gfw/trojan/wiki/Mobile-Platforms"
        colorEcho ${INFO} "https://github.com/trojan-gfw/trojan/releases/latest"
        v2rayclient
        colorEcho ${INFO} "Your V2ray client config"
        cat /etc/v2ray/client.json
        v2raylink
        colorEcho ${INFO} "https://github.com/v2ray/v2ray-core/releases/latest"
        colorEcho ${INFO} "Install Success,Enjoy it!"
        whiptail --title "Option 1" --msgbox "安装成功,享受吧! 多行不義必自斃，子姑待之。 RTFM: https://www.johnrosen1.com/trojan/" 8 78
        ;;
       	3)
        checkupdate
	colorEcho ${SUCCESS} "RTFM: https://www.johnrosen1.com/trojan/"
        ;;
      	4)
        removetrojan
        removev2ray
        removenginx
        colorEcho ${SUCCESS} "Remove complete"
        ;;
        5)
        exit
        whiptail --title "脚本已退出" --msgbox "脚本已退出 RTFM: https://www.johnrosen1.com/trojan/" 8 78
        ;;
    esac
}
export LANG=C.UTF-8
advancedMenu
echo "Program terminated."
