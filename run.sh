#!/bin/bash
#
# Docker script to configure and start an IPsec VPN server
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS ONLY MEANT TO BE RUN
# IN A DOCKER CONTAINER!
#
# Copyright (C) 2016 Lin Song
# Based on the work of Thomas Sarlandie (Copyright 2012)
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

if [ ! -f /.dockerenv ]; then
  echo 'This script should ONLY be run in a Docker container! Aborting.'
  exit 1
fi

if [ ! -f /sys/class/net/eth0/operstate ]; then
  echo "Network interface 'eth0' is not available. Aborting."
  exit 1
fi

if [ -z "$VPN_IPSEC_PSK" ] && [ -z "$VPN_USER_CREDENTIAL_LIST" ]; then
  VPN_IPSEC_PSK="$(< /dev/urandom tr -dc 'A-HJ-NPR-Za-km-z2-9' | head -c 16)"
  VPN_PASSWORD="$(< /dev/urandom tr -dc 'A-HJ-NPR-Za-km-z2-9' | head -c 16)"
  VPN_USER_CREDENTIAL_LIST="[{\"login\":\"vpnuser\",\"password\":\"$VPN_PASSWORD\"}]"
fi

if [ -z "$VPN_IPSEC_PSK" ] || [ -z "$VPN_USER_CREDENTIAL_LIST" ]; then
  echo "VPN credentials must be specified. Edit your 'env' file and re-enter them."
  exit 1
fi

echo
echo 'Trying to auto discover IPs of this server...'
echo

# In case auto IP discovery fails, you may manually enter the public IP
# of this server in your 'env' file, using variable 'VPN_PUBLIC_IP'.
PUBLIC_IP=${VPN_PUBLIC_IP:-''}

# Try to auto discover server IPs
[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
PRIVATE_IP=$(ip -4 route get 1 | awk '{print $NF;exit}')
[ -z "$PRIVATE_IP" ] && PRIVATE_IP=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')

# Check IPs for correct format
IP_REGEX="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
if ! printf %s "$PUBLIC_IP" | grep -Eq "$IP_REGEX"; then
  echo "Cannot find valid public IP. Please manually enter the public IP"
  echo "of this server in your 'env' file, using variable 'VPN_PUBLIC_IP'."
  exit 1
fi
if ! printf %s "$PRIVATE_IP" | grep -Eq "$IP_REGEX"; then
  echo "Cannot find valid private IP. Aborting."
  exit 1
fi

# Create IPsec (Libreswan) config
cat > /etc/ipsec.conf <<EOF
version 2.0

config setup

  nat_traversal=yes
  virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!192.168.42.0/23
  protostack=netkey
  nhelpers=0
  interfaces=%defaultroute
  uniqueids=no

conn shared
  left=$PRIVATE_IP
  leftid=$PUBLIC_IP
  right=%any
  forceencaps=yes
  authby=secret
  pfs=no
  rekey=no
  keyingtries=3
  dpddelay=15
  dpdtimeout=30
  dpdaction=clear
  ike=3des-sha1,aes-sha1
  phase2alg=3des-sha1,aes-sha1

conn l2tp-psk
  auto=add
  leftsubnet=$PRIVATE_IP/32
  leftnexthop=%defaultroute
  leftprotoport=17/1701
  rightprotoport=17/%any
  type=transport
  auth=esp
  also=shared

conn xauth-psk
  auto=add
  leftsubnet=0.0.0.0/0
  rightaddresspool=192.168.43.10-192.168.43.250
  modecfgdns1=8.8.8.8
  modecfgdns2=8.8.4.4
  leftxauthserver=yes
  rightxauthclient=yes
  leftmodecfgserver=yes
  rightmodecfgclient=yes
  modecfgpull=yes
  xauthby=file
  ike-frag=yes
  ikev2=never
  cisco-unity=yes
  also=shared
EOF

# Specify IPsec PSK
cat > /etc/ipsec.secrets <<EOF
$PUBLIC_IP  %any  : PSK "$VPN_IPSEC_PSK"
EOF

# Create xl2tpd config
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701

[lns default]
ip range = 192.168.42.10-192.168.42.50
local ip = 192.168.42.1
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

# Set xl2tpd options
cat > /etc/ppp/options.xl2tpd <<EOF
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
lock
lcp-echo-failure 4
lcp-echo-interval 30
EOF

# Create VPN credentials
echo "$VPN_USER_CREDENTIAL_LIST" | jq -r '.[] | .login + " l2tpd " + .password + " *"' > /etc/ppp/chap-secrets

CREDENTIALS_NUMBER=`echo "$VPN_USER_CREDENTIAL_LIST" | jq 'length'`
for (( i=0; i<=$CREDENTIALS_NUMBER - 1; i++ ))
do
	VPN_USER_LOGIN=`echo "$VPN_USER_CREDENTIAL_LIST" | jq ".["$i"] | .login"`
	VPN_USER_PASSWORD=`echo "$VPN_USER_CREDENTIAL_LIST" | jq ".["$i"] | .password"`
	VPN_PASSWORD_ENC=$(openssl passwd -1 "$VPN_USER_PASSWORD")
	echo "${VPN_USER_LOGIN}:${VPN_PASSWORD_ENC}:xauth-psk" >> /etc/ipsec.d/passwd
done

# Update sysctl settings
if ! grep -qs "Added by run.sh script" /etc/sysctl.conf; then
cat >> /etc/sysctl.conf <<EOF

# Added by run.sh script
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296

net.ipv4.ip_forward = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.lo.send_redirects = 0
net.ipv4.conf.eth0.send_redirects = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.lo.rp_filter = 0
net.ipv4.conf.eth0.rp_filter = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

net.core.wmem_max = 12582912
net.core.rmem_max = 12582912
net.ipv4.tcp_rmem = 10240 87380 12582912
net.ipv4.tcp_wmem = 10240 87380 12582912
EOF
fi

# Create IPTables rules
iptables -I INPUT 1 -p udp -m multiport --dports 500,4500 -j ACCEPT
iptables -I INPUT 2 -p udp --dport 1701 -m policy --dir in --pol ipsec -j ACCEPT
iptables -I INPUT 3 -p udp --dport 1701 -j DROP
iptables -I FORWARD 1 -m conntrack --ctstate INVALID -j DROP
iptables -I FORWARD 2 -i eth+ -o ppp+ -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 3 -i ppp+ -o eth+ -j ACCEPT
iptables -I FORWARD 4 -i eth+ -d 192.168.43.0/24 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 5 -s 192.168.43.0/24 -o eth+ -j ACCEPT
iptables -t nat -I POSTROUTING -s 192.168.43.0/24 -o eth+ -m policy --dir out --pol none -j SNAT --to-source "$PRIVATE_IP"
iptables -t nat -I POSTROUTING -s 192.168.42.0/24 -o eth+ -j SNAT --to-source "$PRIVATE_IP"

# Reload sysctl.conf
sysctl -q -p 2>/dev/null

# Update file attributes
chmod 600 /etc/ipsec.secrets /etc/ppp/chap-secrets /etc/ipsec.d/passwd

cat <<EOF

================================================

IPsec VPN server is now ready for use!

Connect to your new VPN with these details:

Server IP: $PUBLIC_IP
IPsec PSK: $VPN_IPSEC_PSK
Users credentials :
EOF

for (( i=0; i<=$CREDENTIALS_NUMBER - 1; i++ ))
do
	VPN_USER_LOGIN=`echo "$VPN_USER_CREDENTIAL_LIST" | jq -r ".["$i"] | .login"`
	VPN_USER_PASSWORD=`echo "$VPN_USER_CREDENTIAL_LIST" | jq -r ".["$i"] | .password"`
	echo "Login : ${VPN_USER_LOGIN} Password : ${VPN_USER_PASSWORD}"
done

cat <<EOF

Write these down. You'll need them to connect!

Setup VPN Clients: https://git.io/vpnclients

================================================

EOF

# Load IPsec NETKEY kernel module
modprobe af_key

# Start services
mkdir -p /var/run/pluto /var/run/xl2tpd
rm -f /var/run/pluto/pluto.pid /var/run/xl2tpd.pid

/usr/local/sbin/ipsec start --config /etc/ipsec.conf
exec /usr/sbin/xl2tpd -D -c /etc/xl2tpd/xl2tpd.conf
