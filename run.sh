#!/bin/bash
#
# Docker script to configure and start an IPsec VPN server
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS ONLY MEANT TO BE RUN
# IN A CONTAINER!
#
# This file is part of IPsec VPN Docker image, available at:
# https://github.com/hwdsl2/docker-ipsec-vpn-server
#
# Copyright (C) 2016-2024 Lin Song <linsongui@gmail.com>
# Based on the work of Thomas Sarlandie (Copyright 2012)
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

exiterr()  { echo "Error: $1" >&2; exit 1; }
nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
onespace() { printf '%s' "$1" | tr -s ' '; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }
noquotes2() { printf '%s' "$1" | sed -e 's/" "/ /g' -e "s/' '/ /g"; }

check_ip() {
  IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}

check_dns_name() {
  FQDN_REGEX='^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$FQDN_REGEX"
}

check_client_name() {
  ! { [ "${#1}" -gt "64" ] || printf '%s' "$1" | LC_ALL=C grep -q '[^A-Za-z0-9_-]\+' \
    || case $1 in -*) true ;; *) false ;; esac; }
}

if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] \
  && [ -z "$KUBERNETES_SERVICE_HOST" ] \
  && ! head -n 1 /proc/1/sched 2>/dev/null | grep -q '^run\.sh '; then
  exiterr "This script ONLY runs in a container (e.g. Docker, Podman)."
fi

if ip link add dummy0 type dummy 2>&1 | grep -q "not permitted"; then
cat 1>&2 <<'EOF'
Error: This Docker image should be run in privileged mode.
       See: https://github.com/hwdsl2/docker-ipsec-vpn-server

EOF
  exit 1
fi
ip link delete dummy0 >/dev/null 2>&1

os_type=debian
os_arch=$(uname -m | tr -dc 'A-Za-z0-9_-')
[ -f /etc/os-release ] && os_type=$(. /etc/os-release && printf '%s' "$ID")

if [ ! -e /dev/ppp ]; then
cat <<'EOF'

Warning: /dev/ppp is missing, and IPsec/L2TP mode may not work.
         Please use IKEv2 or IPsec/XAuth mode to connect.
         Debian 11/10 users, see https://vpnsetup.net/debian10
EOF
fi

NET_IFACE=$(route 2>/dev/null | grep -m 1 '^default' | grep -o '[^ ]*$')
[ -z "$NET_IFACE" ] && NET_IFACE=$(ip -4 route list 0/0 2>/dev/null | grep -m 1 -Po '(?<=dev )(\S+)')
[ -z "$NET_IFACE" ] && NET_IFACE=eth0

mkdir -p /opt/src
vpn_env="/opt/src/vpn.env"
vpn_env_dir="/opt/src/env/vpn.env"
if [ -f "$vpn_env_dir" ]; then
  vpn_env="$vpn_env_dir"
fi
vpn_gen_env="/etc/ipsec.d/vpn-gen.env"
if [ -z "$VPN_IPSEC_PSK" ] && [ -z "$VPN_USER" ] && [ -z "$VPN_PASSWORD" ]; then
  if [ -f "$vpn_env" ]; then
    echo
    echo 'Retrieving VPN credentials...'
    . "$vpn_env"
  elif [ -f "$vpn_gen_env" ]; then
    echo
    echo 'Retrieving previously generated VPN credentials...'
    . "$vpn_gen_env"
  else
    echo
    echo 'VPN credentials not set by user. Generating random PSK and password...'
    VPN_IPSEC_PSK=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' </dev/urandom 2>/dev/null | head -c 20)
    VPN_USER=vpnuser
    VPN_PASSWORD=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' </dev/urandom 2>/dev/null | head -c 16)
    printf '%s\n' "VPN_IPSEC_PSK='$VPN_IPSEC_PSK'" > "$vpn_gen_env"
    printf '%s\n' "VPN_USER='$VPN_USER'" >> "$vpn_gen_env"
    printf '%s\n' "VPN_PASSWORD='$VPN_PASSWORD'" >> "$vpn_gen_env"
    chmod 600 "$vpn_gen_env"
  fi
fi

# Remove whitespace and quotes around VPN variables, if any
VPN_IPSEC_PSK=$(nospaces "$VPN_IPSEC_PSK")
VPN_IPSEC_PSK=$(noquotes "$VPN_IPSEC_PSK")
VPN_USER=$(nospaces "$VPN_USER")
VPN_USER=$(noquotes "$VPN_USER")
VPN_PASSWORD=$(nospaces "$VPN_PASSWORD")
VPN_PASSWORD=$(noquotes "$VPN_PASSWORD")
if [ -n "$VPN_ADDL_USERS" ] && [ -n "$VPN_ADDL_PASSWORDS" ]; then
  VPN_ADDL_USERS=$(nospaces "$VPN_ADDL_USERS")
  VPN_ADDL_USERS=$(noquotes "$VPN_ADDL_USERS")
  VPN_ADDL_USERS=$(onespace "$VPN_ADDL_USERS")
  VPN_ADDL_USERS=$(noquotes2 "$VPN_ADDL_USERS")
  VPN_ADDL_PASSWORDS=$(nospaces "$VPN_ADDL_PASSWORDS")
  VPN_ADDL_PASSWORDS=$(noquotes "$VPN_ADDL_PASSWORDS")
  VPN_ADDL_PASSWORDS=$(onespace "$VPN_ADDL_PASSWORDS")
  VPN_ADDL_PASSWORDS=$(noquotes2 "$VPN_ADDL_PASSWORDS")
  if [ -n "$VPN_ADDL_IP_ADDRS" ]; then
    VPN_ADDL_IP_ADDRS=$(nospaces "$VPN_ADDL_IP_ADDRS")
    VPN_ADDL_IP_ADDRS=$(noquotes "$VPN_ADDL_IP_ADDRS")
    VPN_ADDL_IP_ADDRS=$(onespace "$VPN_ADDL_IP_ADDRS")
    VPN_ADDL_IP_ADDRS=$(noquotes2 "$VPN_ADDL_IP_ADDRS")
  fi
else
  VPN_ADDL_USERS=""
  VPN_ADDL_PASSWORDS=""
  VPN_ADDL_IP_ADDRS=""
fi
if [ -n "$VPN_DNS_SRV1" ]; then
  VPN_DNS_SRV1=$(nospaces "$VPN_DNS_SRV1")
  VPN_DNS_SRV1=$(noquotes "$VPN_DNS_SRV1")
fi
if [ -n "$SPLIT_VPN_IKEV2" ]; then
  SPLIT_VPN_IKEV2=$(nospaces "$SPLIT_VPN_IKEV2")
  SPLIT_VPN_IKEV2=$(noquotes "$SPLIT_VPN_IKEV2")
fi
if [ -n "$VPN_DNS_SRV2" ]; then
  VPN_DNS_SRV2=$(nospaces "$VPN_DNS_SRV2")
  VPN_DNS_SRV2=$(noquotes "$VPN_DNS_SRV2")
fi
if [ -n "$VPN_CLIENT_NAME" ]; then
  VPN_CLIENT_NAME=$(nospaces "$VPN_CLIENT_NAME")
  VPN_CLIENT_NAME=$(noquotes "$VPN_CLIENT_NAME")
fi
if [ -n "$VPN_DNS_NAME" ]; then
  VPN_DNS_NAME=$(nospaces "$VPN_DNS_NAME")
  VPN_DNS_NAME=$(noquotes "$VPN_DNS_NAME")
fi
if [ -n "$VPN_PUBLIC_IP" ]; then
  VPN_PUBLIC_IP=$(nospaces "$VPN_PUBLIC_IP")
  VPN_PUBLIC_IP=$(noquotes "$VPN_PUBLIC_IP")
fi
if [ -n "$VPN_ANDROID_MTU_FIX" ]; then
  VPN_ANDROID_MTU_FIX=$(nospaces "$VPN_ANDROID_MTU_FIX")
  VPN_ANDROID_MTU_FIX=$(noquotes "$VPN_ANDROID_MTU_FIX")
fi
if [ -n "$VPN_SHA2_TRUNCBUG" ]; then
  VPN_SHA2_TRUNCBUG=$(nospaces "$VPN_SHA2_TRUNCBUG")
  VPN_SHA2_TRUNCBUG=$(noquotes "$VPN_SHA2_TRUNCBUG")
fi
if [ -n "$VPN_PROTECT_CONFIG" ]; then
  VPN_PROTECT_CONFIG=$(nospaces "$VPN_PROTECT_CONFIG")
  VPN_PROTECT_CONFIG=$(noquotes "$VPN_PROTECT_CONFIG")
fi
if [ -n "$VPN_DISABLE_IPSEC_L2TP" ]; then
  VPN_DISABLE_IPSEC_L2TP=$(nospaces "$VPN_DISABLE_IPSEC_L2TP")
  VPN_DISABLE_IPSEC_L2TP=$(noquotes "$VPN_DISABLE_IPSEC_L2TP")
fi
if [ -n "$VPN_DISABLE_IPSEC_XAUTH" ]; then
  VPN_DISABLE_IPSEC_XAUTH=$(nospaces "$VPN_DISABLE_IPSEC_XAUTH")
  VPN_DISABLE_IPSEC_XAUTH=$(noquotes "$VPN_DISABLE_IPSEC_XAUTH")
fi
if [ -n "$VPN_IKEV2_ONLY" ]; then
  VPN_IKEV2_ONLY=$(nospaces "$VPN_IKEV2_ONLY")
  VPN_IKEV2_ONLY=$(noquotes "$VPN_IKEV2_ONLY")
fi
if [ -n "$VPN_ENABLE_MODP1024" ]; then
  VPN_ENABLE_MODP1024=$(nospaces "$VPN_ENABLE_MODP1024")
  VPN_ENABLE_MODP1024=$(noquotes "$VPN_ENABLE_MODP1024")
fi
if [ -n "$VPN_ENABLE_MODP1536" ]; then
  VPN_ENABLE_MODP1536=$(nospaces "$VPN_ENABLE_MODP1536")
  VPN_ENABLE_MODP1536=$(noquotes "$VPN_ENABLE_MODP1536")
fi
if [ -n "$VPN_L2TP_NET" ]; then
  VPN_L2TP_NET=$(nospaces "$VPN_L2TP_NET")
  VPN_L2TP_NET=$(noquotes "$VPN_L2TP_NET")
fi
if [ -n "$VPN_L2TP_LOCAL" ]; then
  VPN_L2TP_LOCAL=$(nospaces "$VPN_L2TP_LOCAL")
  VPN_L2TP_LOCAL=$(noquotes "$VPN_L2TP_LOCAL")
fi
if [ -n "$VPN_L2TP_POOL" ]; then
  VPN_L2TP_POOL=$(nospaces "$VPN_L2TP_POOL")
  VPN_L2TP_POOL=$(noquotes "$VPN_L2TP_POOL")
fi
if [ -n "$VPN_XAUTH_NET" ]; then
  VPN_XAUTH_NET=$(nospaces "$VPN_XAUTH_NET")
  VPN_XAUTH_NET=$(noquotes "$VPN_XAUTH_NET")
fi
if [ -n "$VPN_XAUTH_POOL" ]; then
  VPN_XAUTH_POOL=$(nospaces "$VPN_XAUTH_POOL")
  VPN_XAUTH_POOL=$(noquotes "$VPN_XAUTH_POOL")
fi

if [ -z "$VPN_IPSEC_PSK" ] || [ -z "$VPN_USER" ] || [ -z "$VPN_PASSWORD" ]; then
  exiterr "All VPN credentials must be specified. Edit your 'env' file and re-enter them."
fi
if printf '%s' "$VPN_IPSEC_PSK $VPN_USER $VPN_PASSWORD $VPN_ADDL_USERS $VPN_ADDL_PASSWORDS" | LC_ALL=C grep -q '[^ -~]\+'; then
  exiterr "VPN credentials must not contain non-ASCII characters."
fi
case "$VPN_IPSEC_PSK $VPN_USER $VPN_PASSWORD $VPN_ADDL_USERS $VPN_ADDL_PASSWORDS" in
  *[\\\"\']*)
    exiterr "VPN credentials must not contain these special characters: \\ \" '"
    ;;
esac
if printf '%s' "$VPN_USER $VPN_ADDL_USERS" | tr ' ' '\n' | sort | uniq -c | grep -qv '^ *1 '; then
  exiterr "VPN usernames must not contain duplicates."
fi

# Check DNS servers and try to resolve hostnames to IPs
if [ -n "$VPN_DNS_SRV1" ]; then
  check_ip "$VPN_DNS_SRV1" || VPN_DNS_SRV1=$(dig -t A -4 +short "$VPN_DNS_SRV1")
  if ! check_ip "$VPN_DNS_SRV1"; then
cat <<'EOF'

Warning: Invalid DNS server. Check VPN_DNS_SRV1 in your 'env' file.
EOF
    VPN_DNS_SRV1=""
  fi
fi
if [ -n "$VPN_DNS_SRV2" ]; then
  check_ip "$VPN_DNS_SRV2" || VPN_DNS_SRV2=$(dig -t A -4 +short "$VPN_DNS_SRV2")
  if ! check_ip "$VPN_DNS_SRV2"; then
cat <<'EOF'

Warning: Invalid DNS server. Check VPN_DNS_SRV2 in your 'env' file.
EOF
    VPN_DNS_SRV2=""
  fi
fi
if [ -n "$VPN_CLIENT_NAME" ]; then
  if ! check_client_name "$VPN_CLIENT_NAME"; then
cat <<'EOF'

Warning: Invalid client name. Use one word only, no special characters except '-' and '_'.
         Falling back to default client name 'vpnclient'.
EOF
    VPN_CLIENT_NAME=""
  fi
fi
if [ -n "$VPN_DNS_NAME" ]; then
  if ! check_dns_name "$VPN_DNS_NAME"; then
cat <<'EOF'

Warning: Invalid DNS name. 'VPN_DNS_NAME' must be a fully qualified domain name (FQDN).
         Falling back to using this server's IP address.
EOF
    VPN_DNS_NAME=""
  fi
fi

if [ -n "$VPN_DNS_NAME" ]; then
  server_addr="$VPN_DNS_NAME"
else
  echo
  echo 'Trying to auto discover IP of this server...'
  # In case auto IP discovery fails, manually define the public IP
  # of this server in your 'env' file, as variable 'VPN_PUBLIC_IP'.
  public_ip=${VPN_PUBLIC_IP:-''}
  check_ip "$public_ip" || public_ip=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)
  check_ip "$public_ip" || public_ip=$(wget -t 2 -T 10 -qO- http://ipv4.icanhazip.com)
  check_ip "$public_ip" || public_ip=$(wget -t 2 -T 10 -qO- http://ip1.dynupdate.no-ip.com)
  check_ip "$public_ip" || exiterr "Cannot detect this server's public IP. Define it in your 'env' file as 'VPN_PUBLIC_IP'."
  server_addr="$public_ip"
fi

L2TP_NET=${VPN_L2TP_NET:-'192.168.42.0/24'}
L2TP_LOCAL=${VPN_L2TP_LOCAL:-'192.168.42.1'}
L2TP_POOL=${VPN_L2TP_POOL:-'192.168.42.10-192.168.42.250'}
XAUTH_NET=${VPN_XAUTH_NET:-'192.168.43.0/24'}
XAUTH_POOL=${VPN_XAUTH_POOL:-'192.168.43.10-192.168.43.250'}
DNS_SRV1=${VPN_DNS_SRV1:-'8.8.8.8'}
DNS_SRV2=${VPN_DNS_SRV2:-'8.8.4.4'}
DNS_SRVS="\"$DNS_SRV1 $DNS_SRV2\""
[ -n "$VPN_DNS_SRV1" ] && [ -z "$VPN_DNS_SRV2" ] && DNS_SRVS="$DNS_SRV1"

if [ -n "$VPN_DNS_SRV1" ] && [ -n "$VPN_DNS_SRV2" ]; then
  echo
  echo "Setting DNS servers to $VPN_DNS_SRV1 and $VPN_DNS_SRV2..."
elif [ -n "$VPN_DNS_SRV1" ]; then
  echo
  echo "Setting DNS server to $VPN_DNS_SRV1..."
fi

sha2_truncbug=no
case $VPN_SHA2_TRUNCBUG in
  [yY][eE][sS])
    echo
    echo "Setting sha2-truncbug to yes in ipsec.conf..."
    sha2_truncbug=yes
    ;;
esac
disable_ipsec_l2tp=no
case $VPN_DISABLE_IPSEC_L2TP in
  [yY][eE][sS])
    disable_ipsec_l2tp=yes
    ;;
esac
disable_ipsec_xauth=no
case $VPN_DISABLE_IPSEC_XAUTH in
  [yY][eE][sS])
    disable_ipsec_xauth=yes
    ;;
esac
case $VPN_IKEV2_ONLY in
  [yY][eE][sS])
    disable_ipsec_l2tp=yes
    disable_ipsec_xauth=yes
    ;;
esac
ike_algs="aes256-sha2;modp2048,aes128-sha2;modp2048,aes256-sha1;modp2048,aes128-sha1;modp2048"
ike_algs_addl_1=",aes256-sha2;modp1024,aes128-sha1;modp1024"
ike_algs_addl_2=",aes256-sha2;modp1536,aes128-sha1;modp1536"
case $VPN_ENABLE_MODP1024 in
  [yY][eE][sS])
    echo
    echo "Enabling modp1024 in ipsec.conf..."
    ike_algs="$ike_algs$ike_algs_addl_1"
    ;;
esac
case $VPN_ENABLE_MODP1536 in
  [yY][eE][sS])
    echo
    echo "Enabling modp1536 in ipsec.conf..."
    ike_algs="$ike_algs$ike_algs_addl_2"
    ;;
esac

if [ "$disable_ipsec_l2tp" = yes ] && [ "$disable_ipsec_xauth" = yes ]; then
cat <<'EOF'

Note: Running in IKEv2-only mode via env file option.
      IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes are disabled.
EOF
  if ! grep -q " /etc/ipsec.d " /proc/mounts; then
cat <<'EOF'

Warning: /etc/ipsec.d not mounted. IKEv2 setup requires a Docker volume
         mounted at /etc/ipsec.d.
EOF
  fi
elif [ "$disable_ipsec_l2tp" = yes ]; then
cat <<'EOF'

Note: IPsec/L2TP mode is disabled via env file option.
EOF
elif [ "$disable_ipsec_xauth" = yes ]; then
cat <<'EOF'

Note: IPsec/XAuth ("Cisco IPsec") mode is disabled via env file option.
EOF
fi

# Create IPsec config
cat > /etc/ipsec.conf <<EOF
version 2.0

config setup
  virtual-private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!$L2TP_NET,%v4:!$XAUTH_NET
  uniqueids=no

conn shared
  left=%defaultroute
  leftid=$server_addr
  right=%any
  encapsulation=yes
  authby=secret
  pfs=no
  rekey=no
  keyingtries=5
  dpddelay=30
  dpdtimeout=300
  dpdaction=clear
  ikev2=never
  ike=$ike_algs
  phase2alg=aes_gcm-null,aes128-sha1,aes256-sha1,aes256-sha2_512,aes128-sha2,aes256-sha2
  ikelifetime=24h
  salifetime=24h
  sha2-truncbug=$sha2_truncbug

EOF

if [ "$disable_ipsec_l2tp" != yes ]; then
cat >> /etc/ipsec.conf <<'EOF'
conn l2tp-psk
  auto=add
  leftprotoport=17/1701
  rightprotoport=17/%any
  type=transport
  also=shared

EOF
fi
if [ "$disable_ipsec_xauth" != yes ]; then
cat >> /etc/ipsec.conf <<EOF
conn xauth-psk
  auto=add
  leftsubnet=0.0.0.0/0
  rightaddresspool=$XAUTH_POOL
  modecfgdns=$DNS_SRVS
  leftxauthserver=yes
  rightxauthclient=yes
  leftmodecfgserver=yes
  rightmodecfgclient=yes
  modecfgpull=yes
  cisco-unity=yes
  also=shared

EOF
fi

cat >> /etc/ipsec.conf <<'EOF'
include /etc/ipsec.d/*.conf
EOF

if uname -r | grep -qi 'coreos'; then
  sed -i '/phase2alg/s/,aes256-sha2_512//' /etc/ipsec.conf
fi
if grep -qs ike-frag /etc/ipsec.d/ikev2.conf; then
  sed -i 's/^[[:space:]]\+ike-frag=/  fragmentation=/' /etc/ipsec.d/ikev2.conf
fi

# Specify IPsec PSK
cat > /etc/ipsec.secrets <<EOF
%any  %any  : PSK "$VPN_IPSEC_PSK"
EOF

# Create xl2tpd config
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701

[lns default]
ip range = $L2TP_POOL
local ip = $L2TP_LOCAL
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tpd
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

# Set xl2tpd options
cat > /etc/ppp/options.xl2tpd <<EOF
+mschap-v2
ipcp-accept-local
ipcp-accept-remote
noccp
auth
mtu 1280
mru 1280
proxyarp
lcp-echo-failure 4
lcp-echo-interval 30
connect-delay 5000
ms-dns $DNS_SRV1
EOF

if [ -z "$VPN_DNS_SRV1" ] || [ -n "$VPN_DNS_SRV2" ]; then
cat >> /etc/ppp/options.xl2tpd <<EOF
ms-dns $DNS_SRV2
EOF
fi

# Create VPN credentials
cat > /etc/ppp/chap-secrets <<EOF
"$VPN_USER" l2tpd "$VPN_PASSWORD" *
EOF

VPN_PASSWORD_ENC=$(openssl passwd -1 "$VPN_PASSWORD")
cat > /etc/ipsec.d/passwd <<EOF
$VPN_USER:$VPN_PASSWORD_ENC:xauth-psk
EOF

if [ -n "$VPN_ADDL_USERS" ] && [ -n "$VPN_ADDL_PASSWORDS" ]; then
  count=1
  addl_user=$(printf '%s' "$VPN_ADDL_USERS" | cut -d ' ' -f 1)
  addl_password=$(printf '%s' "$VPN_ADDL_PASSWORDS" | cut -d ' ' -f 1)
  addl_ip=$(printf '%s' "$VPN_ADDL_IP_ADDRS" | cut -d ' ' -f 1)
  while [ -n "$addl_user" ] && [ -n "$addl_password" ]; do
    addl_ip_l2tp="$addl_ip"
    addl_ip_xauth="$addl_ip"
    if [ "$addl_ip" = "*" ] || ! check_ip "$addl_ip"; then
      addl_ip_l2tp=""
      addl_ip_xauth=""
    elif [ "$L2TP_NET" = "192.168.42.0/24" ] && [ "$XAUTH_NET" = "192.168.43.0/24" ]; then
      addl_ip_part=$(printf '%s' "$addl_ip" | cut -f 1-3 -d '.')
      if [ "$addl_ip_part" = "192.168.42" ]; then
        addl_ip_xauth=""
      elif [ "$addl_ip_part" = "192.168.43" ]; then
        addl_ip_l2tp=""
      else
        addl_ip_l2tp=""
        addl_ip_xauth=""
      fi
    fi
cat >> /etc/ppp/chap-secrets <<EOF
"$addl_user" l2tpd "$addl_password" ${addl_ip_l2tp:-*}
EOF
    [ -n "$addl_ip_xauth" ] && addl_ip_xauth=$(printf '%s' ":$addl_ip_xauth")
    addl_password_enc=$(openssl passwd -1 "$addl_password")
cat >> /etc/ipsec.d/passwd <<EOF
$addl_user:$addl_password_enc:xauth-psk${addl_ip_xauth}
EOF
    count=$((count+1))
    addl_user=$(printf '%s' "$VPN_ADDL_USERS" | cut -s -d ' ' -f "$count")
    addl_password=$(printf '%s' "$VPN_ADDL_PASSWORDS" | cut -s -d ' ' -f "$count")
    addl_ip=$(printf '%s' "$VPN_ADDL_IP_ADDRS" | cut -s -d ' ' -f "$count")
  done
fi

# Update sysctl settings
syt='/sbin/sysctl -e -q -w'
$syt kernel.msgmnb=65536 2>/dev/null
$syt kernel.msgmax=65536 2>/dev/null
$syt net.ipv4.ip_forward=1 2>/dev/null
$syt net.ipv4.conf.all.accept_redirects=0 2>/dev/null
$syt net.ipv4.conf.all.send_redirects=0 2>/dev/null
$syt net.ipv4.conf.all.rp_filter=0 2>/dev/null
$syt net.ipv4.conf.default.accept_redirects=0 2>/dev/null
$syt net.ipv4.conf.default.send_redirects=0 2>/dev/null
$syt net.ipv4.conf.default.rp_filter=0 2>/dev/null
$syt "net.ipv4.conf.$NET_IFACE.send_redirects=0" 2>/dev/null
$syt "net.ipv4.conf.$NET_IFACE.rp_filter=0" 2>/dev/null
$syt net.ipv4.tcp_rmem="4096 87380 16777216" 2>/dev/null
$syt net.ipv4.tcp_wmem="4096 87380 16777216" 2>/dev/null
if modprobe -q tcp_bbr 2>/dev/null \
  && printf '%s\n%s' "4.20" "$(uname -r)" | sort -C -V; then
  $syt net.ipv4.tcp_congestion_control=bbr 2>/dev/null
fi

# Create IPTables rules
ipi='iptables -I INPUT'
ipf='iptables -I FORWARD'
ipp='iptables -t nat -I POSTROUTING'
res='RELATED,ESTABLISHED'
modprobe -q ip_tables 2>/dev/null
if ! iptables -t nat -C POSTROUTING -s "$L2TP_NET" -o "$NET_IFACE" -j MASQUERADE 2>/dev/null; then
  $ipi 1 -p udp --dport 1701 -m policy --dir in --pol none -j DROP
  $ipi 2 -m conntrack --ctstate INVALID -j DROP
  $ipi 3 -m conntrack --ctstate "$res" -j ACCEPT
  $ipi 4 -p udp -m multiport --dports 500,4500 -j ACCEPT
  $ipi 5 -p udp --dport 1701 -m policy --dir in --pol ipsec -j ACCEPT
  $ipi 6 -p udp --dport 1701 -j DROP
  $ipf 1 -m conntrack --ctstate INVALID -j DROP
  $ipf 2 -i "$NET_IFACE" -o ppp+ -m conntrack --ctstate "$res" -j ACCEPT
  $ipf 3 -i ppp+ -o "$NET_IFACE" -j ACCEPT
  $ipf 4 -i ppp+ -o ppp+ -j ACCEPT
  $ipf 5 -i "$NET_IFACE" -d "$XAUTH_NET" -m conntrack --ctstate "$res" -j ACCEPT
  $ipf 6 -s "$XAUTH_NET" -o "$NET_IFACE" -j ACCEPT
  $ipf 7 -s "$XAUTH_NET" -o ppp+ -j ACCEPT
  # Client-to-client traffic is allowed by default. To *disallow* such traffic,
  # uncomment below and restart the Docker container.
  # $ipf 2 -i ppp+ -o ppp+ -s "$L2TP_NET" -d "$L2TP_NET" -j DROP
  # $ipf 3 -s "$XAUTH_NET" -d "$XAUTH_NET" -j DROP
  # $ipf 4 -i ppp+ -d "$XAUTH_NET" -j DROP
  # $ipf 5 -s "$XAUTH_NET" -o ppp+ -j DROP
  iptables -A FORWARD -j DROP
  if ! $ipp -s "$XAUTH_NET" -o "$NET_IFACE" -m policy --dir out --pol none -j MASQUERADE; then
    $ipp -s "$XAUTH_NET" -o "$NET_IFACE" ! -d "$XAUTH_NET" -j MASQUERADE
  fi
  $ipp -s "$L2TP_NET" -o "$NET_IFACE" -j MASQUERADE
fi

case $VPN_ANDROID_MTU_FIX in
  [yY][eE][sS])
    echo
    echo "Applying fix for Android MTU/MSS issues..."
    iptables -t mangle -A FORWARD -m policy --pol ipsec --dir in \
      -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 \
      -j TCPMSS --set-mss 1360
    iptables -t mangle -A FORWARD -m policy --pol ipsec --dir out \
      -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 \
      -j TCPMSS --set-mss 1360
    echo 1 > /proc/sys/net/ipv4/ip_no_pmtu_disc
    ;;
esac

# Update file attributes
chmod 600 /etc/ipsec.secrets /etc/ppp/chap-secrets /etc/ipsec.d/passwd

echo
echo "Starting IPsec service..."
mkdir -p /run/pluto /var/run/pluto
rm -f /run/pluto/pluto.pid /var/run/pluto/pluto.pid
if [ "$os_type" = "alpine" ]; then
  sed -i '1c\#!/sbin/openrc-run' /etc/init.d/ipsec
  rc-status >/dev/null 2>&1
  rc-service ipsec zap >/dev/null
  rc-service -D ipsec start >/dev/null 2>&1
  mkdir -p /etc/crontabs
  cron_cmd="rc-service -c -D ipsec zap start"
if ! grep -qs "$cron_cmd" /etc/crontabs/root; then
cat >> /etc/crontabs/root <<EOF
* * * * * $cron_cmd
* * * * * sleep 15; $cron_cmd
* * * * * sleep 30; $cron_cmd
* * * * * sleep 45; $cron_cmd
EOF
fi
  /usr/sbin/crond -L /dev/null
else
  service ipsec start >/dev/null 2>&1
fi

if [ -n "$VPN_DNS_NAME" ]; then
  server_text="Server"
else
  server_text="Server IP"
fi

if [ "$disable_ipsec_l2tp" != yes ] || [ "$disable_ipsec_xauth" != yes ]; then
cat <<EOF

================================================

IPsec VPN server is now ready for use!

Connect to your new VPN with these details:

$server_text: $server_addr
IPsec PSK: $VPN_IPSEC_PSK
Username: $VPN_USER
Password: $VPN_PASSWORD
EOF
  if [ -n "$VPN_ADDL_USERS" ] && [ -n "$VPN_ADDL_PASSWORDS" ]; then
    count=1
    addl_user=$(printf '%s' "$VPN_ADDL_USERS" | cut -d ' ' -f 1)
    addl_password=$(printf '%s' "$VPN_ADDL_PASSWORDS" | cut -d ' ' -f 1)
cat <<'EOF'

Additional VPN users (username | password):
EOF
    while [ -n "$addl_user" ] && [ -n "$addl_password" ]; do
cat <<EOF
$addl_user | $addl_password
EOF
      count=$((count+1))
      addl_user=$(printf '%s' "$VPN_ADDL_USERS" | cut -s -d ' ' -f "$count")
      addl_password=$(printf '%s' "$VPN_ADDL_PASSWORDS" | cut -s -d ' ' -f "$count")
    done
  fi
cat <<'EOF'

Write these down. You'll need them to connect!

VPN client setup: https://vpnsetup.net/clients2

================================================
EOF
fi

# Set up IKEv2
status=0
ikev2_sh="/opt/src/ikev2.sh"
ikev2_conf="/etc/ipsec.d/ikev2.conf"
ikev2_log="/etc/ipsec.d/ikev2setup.log"
if grep -q " /etc/ipsec.d " /proc/mounts && [ -s "$ikev2_sh" ] && [ ! -f "$ikev2_conf" ]; then
if [ -n "$SPLIT_VPN_IKEV2" ]; then
	sed -i "s|^  leftsubnet=.*|  leftsubnet=$SPLIT_VPN_IKEV2 |g" /opt/src/ikev2.sh
fi

  echo
  echo "Setting up IKEv2. This may take a few moments..."
  if VPN_DNS_NAME="$VPN_DNS_NAME" VPN_PUBLIC_IP="$public_ip" \
    VPN_CLIENT_NAME="$VPN_CLIENT_NAME" VPN_XAUTH_POOL="$VPN_XAUTH_POOL" \
    VPN_DNS_SRV1="$VPN_DNS_SRV1" VPN_DNS_SRV2="$VPN_DNS_SRV2" \
    VPN_PROTECT_CONFIG="$VPN_PROTECT_CONFIG" \
    /bin/bash "$ikev2_sh" --auto >"$ikev2_log" 2>&1; then
    status=1
    status_text="IKEv2 setup successful."
  else
    status=4
    rm -f "$ikev2_conf"
    echo "IKEv2 setup failed."
  fi
  chmod 600 "$ikev2_log"
fi
if [ "$status" = 0 ] && [ -f "$ikev2_conf" ] && [ -s "$ikev2_log" ]; then
  status=2
  status_text="IKEv2 is already set up."
fi
if [ "$status" = 1 ] || [ "$status" = 2 ]; then
cat <<EOF

================================================

$status_text Details for IKEv2 mode:

EOF
  sed -n '/VPN server address:/,/Next steps:/p' "$ikev2_log"
cat <<'EOF'
https://vpnsetup.net/clients2

================================================

EOF
else
  echo
fi

if [ "$status" = 2 ] && [ -n "$VPN_DNS_NAME" ]; then
  server_addr_cur=$(grep -s "leftcert=" /etc/ipsec.d/ikev2.conf | cut -f2 -d=)
  if [ "$VPN_DNS_NAME" != "$server_addr_cur" ]; then
cat <<'EOF'
Warning: The VPN_DNS_NAME variable you specified has no effect
         for IKEv2 mode, because IKEv2 is already set up in this
         container. To change the IKEv2 server address, see:
         https://vpnsetup.net/ikev2docker

EOF
  fi
fi

# Check for new Libreswan version
ts_file="/opt/src/swanver"
if [ ! -f "$ts_file" ] || [ "$(find "$ts_file" -mmin +10080)" ]; then
  touch "$ts_file"
  ipsec_ver=$(ipsec --version 2>/dev/null)
  swan_ver=$(printf '%s' "$ipsec_ver" | sed -e 's/.*Libreswan U\?//' -e 's/\( (\|\/K\).*//')
  base_url="https://github.com/hwdsl2/vpn-extras/releases/download/v1.0.0"
  swan_ver_url="$base_url/upg-docker-$os_type-$os_arch-swanver"
  swan_ver_latest=$(wget -t 2 -T 10 -qO- "$swan_ver_url" | head -n 1)
  if printf '%s' "$swan_ver_latest" | grep -Eq '^([3-9]|[1-9][0-9]{1,2})(\.([0-9]|[1-9][0-9]{1,2})){1,2}$' \
    && [ -n "$swan_ver" ] && [ "$swan_ver" != "$swan_ver_latest" ] \
    && printf '%s\n%s' "$swan_ver" "$swan_ver_latest" | sort -C -V; then
cat <<EOF
Note: A newer version of Libreswan ($swan_ver_latest) is available.
To update this Docker image, see: https://vpnsetup.net/dockerupdate

EOF
  fi
fi

# Start xl2tpd
mkdir -p /var/run/xl2tpd
rm -f /var/run/xl2tpd.pid
exec /usr/sbin/xl2tpd -D -c /etc/xl2tpd/xl2tpd.conf
