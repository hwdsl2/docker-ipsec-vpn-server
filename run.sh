#!/bin/sh
#
# Docker script to configure and start an IPsec VPN server
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS ONLY MEANT TO BE RUN
# IN A CONTAINER!
#
# This file is part of IPsec VPN Docker image, available at:
# https://github.com/hwdsl2/docker-ipsec-vpn-server
#
# Copyright (C) 2016-2021 Lin Song <linsongui@gmail.com>
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
    || case $1 in -*) true;; *) false;; esac; }
}

if [ ! -f "/.dockerenv" ] && [ ! -f "/run/.containerenv" ] && ! head -n 1 /proc/1/sched | grep -q '^run\.sh '; then
  exiterr "This script ONLY runs in a container (e.g. Docker, Podman)."
fi

if ip link add dummy0 type dummy 2>&1 | grep -q "not permitted"; then
cat 1>&2 <<'EOF'
Error: This Docker image should be run in privileged mode.
       For detailed instructions, please visit:
       https://github.com/hwdsl2/docker-ipsec-vpn-server

EOF
  exit 1
fi
ip link delete dummy0 >/dev/null 2>&1

os_type=debian
os_arch=$(uname -m | tr -dc 'A-Za-z0-9_-')
[ -f /etc/os-release ] && os_type=$(. /etc/os-release && printf '%s' "$ID")

if uname -r | grep -q cloud && [ ! -e /dev/ppp ]; then
  echo >&2
  echo "Error: /dev/ppp is missing. Debian 10 users, see: https://git.io/vpndebian10" >&2
fi

NET_IFACE=$(route 2>/dev/null | grep -m 1 '^default' | grep -o '[^ ]*$')
[ -z "$NET_IFACE" ] && NET_IFACE=$(ip -4 route list 0/0 2>/dev/null | grep -m 1 -Po '(?<=dev )(\S+)')
[ -z "$NET_IFACE" ] && NET_IFACE=eth0

mkdir -p /opt/src
vpn_env="/opt/src/vpn.env"
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
    VPN_IPSEC_PSK=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 20)
    VPN_USER=vpnuser
    VPN_PASSWORD=$(LC_CTYPE=C tr -dc 'A-HJ-NPR-Za-km-z2-9' < /dev/urandom | head -c 16)

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
else
  VPN_ADDL_USERS=""
  VPN_ADDL_PASSWORDS=""
fi

if [ -n "$VPN_DNS_SRV1" ]; then
  VPN_DNS_SRV1=$(nospaces "$VPN_DNS_SRV1")
  VPN_DNS_SRV1=$(noquotes "$VPN_DNS_SRV1")
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
    echo >&2
    echo "Error: Invalid DNS server. Check VPN_DNS_SRV1 in your 'env' file." >&2
    VPN_DNS_SRV1=""
  fi
fi

if [ -n "$VPN_DNS_SRV2" ]; then
  check_ip "$VPN_DNS_SRV2" || VPN_DNS_SRV2=$(dig -t A -4 +short "$VPN_DNS_SRV2")
  if ! check_ip "$VPN_DNS_SRV2"; then
    echo >&2
    echo "Error: Invalid DNS server. Check VPN_DNS_SRV2 in your 'env' file." >&2
    VPN_DNS_SRV2=""
  fi
fi

if [ -n "$VPN_CLIENT_NAME" ]; then
  if ! check_client_name "$VPN_CLIENT_NAME"; then
    echo >&2
    echo "Error: Invalid client name. Use one word only, no special characters except '-' and '_'." >&2
    echo "       Falling back to default client name 'vpnclient'." >&2
    VPN_CLIENT_NAME=""
  fi
fi

if [ -n "$VPN_DNS_NAME" ]; then
  if ! check_dns_name "$VPN_DNS_NAME"; then
    echo >&2
    echo "Error: Invalid DNS name. 'VPN_DNS_NAME' must be a fully qualified domain name (FQDN)." >&2
    echo "       Falling back to using this server's IP address." >&2
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
  check_ip "$public_ip" || public_ip=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
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

case $VPN_SHA2_TRUNCBUG in
  [yY][eE][sS])
    echo
    echo "Setting sha2-truncbug to yes in ipsec.conf..."
    SHA2_TRUNCBUG=yes
    ;;
  *)
    SHA2_TRUNCBUG=no
    ;;
esac

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
  dpdtimeout=120
  dpdaction=clear
  ikev2=never
  ike=aes256-sha2,aes128-sha2,aes256-sha1,aes128-sha1,aes256-sha2;modp1024,aes128-sha1;modp1024
  phase2alg=aes_gcm-null,aes128-sha1,aes256-sha1,aes256-sha2_512,aes128-sha2,aes256-sha2
  ikelifetime=24h
  salifetime=24h
  sha2-truncbug=$SHA2_TRUNCBUG

conn l2tp-psk
  auto=add
  leftprotoport=17/1701
  rightprotoport=17/%any
  type=transport
  also=shared

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
  while [ -n "$addl_user" ] && [ -n "$addl_password" ]; do
    addl_password_enc=$(openssl passwd -1 "$addl_password")
cat >> /etc/ppp/chap-secrets <<EOF
"$addl_user" l2tpd "$addl_password" *
EOF
cat >> /etc/ipsec.d/passwd <<EOF
$addl_user:$addl_password_enc:xauth-psk
EOF
    count=$((count+1))
    addl_user=$(printf '%s' "$VPN_ADDL_USERS" | cut -s -d ' ' -f "$count")
    addl_password=$(printf '%s' "$VPN_ADDL_PASSWORDS" | cut -s -d ' ' -f "$count")
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

# Create IPTables rules
ipi='iptables -I INPUT'
ipf='iptables -I FORWARD'
ipp='iptables -t nat -I POSTROUTING'
res='RELATED,ESTABLISHED'
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
  $ipp -s "$XAUTH_NET" -o "$NET_IFACE" -m policy --dir out --pol none -j MASQUERADE
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
  ipsec initnss >/dev/null
  ipsec pluto --config /etc/ipsec.conf
else
  service ipsec start >/dev/null 2>&1
fi

if [ -n "$VPN_DNS_NAME" ]; then
  server_text="Server"
else
  server_text="Server IP"
fi

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

Important notes:   https://git.io/vpnnotes2
Setup VPN clients: https://git.io/vpnclients
EOF

if ! mount | grep -q " /etc/ipsec.d "; then
  echo "IKEv2 guide:       https://git.io/ikev2docker"
fi

cat <<'EOF'

================================================
EOF

# Set up IKEv2
status=0
ikev2_sh="/opt/src/ikev2.sh"
ikev2_conf="/etc/ipsec.d/ikev2.conf"
ikev2_log="/etc/ipsec.d/ikev2setup.log"
if mount | grep -q " /etc/ipsec.d " && [ -s "$ikev2_sh" ] && [ ! -f "$ikev2_conf" ]; then
  echo
  echo "Setting up IKEv2. This may take a few moments..."
  if VPN_DNS_NAME="$VPN_DNS_NAME" VPN_PUBLIC_IP="$public_ip" VPN_CLIENT_NAME="$VPN_CLIENT_NAME" \
    VPN_DNS_SRV1="$VPN_DNS_SRV1" VPN_DNS_SRV2="$VPN_DNS_SRV2" \
    bash "$ikev2_sh" --auto >"$ikev2_log" 2>&1; then
    status=1
    status_text="IKEv2 setup successful."
  else
    status=4
    rm -f "$ikev2_conf"
    echo "IKEv2 setup failed."
  fi
  chmod 600 "$ikev2_log"
fi
if [ "$status" = "0" ] && [ -f "$ikev2_conf" ] && [ -s "$ikev2_log" ]; then
  status=2
  status_text="IKEv2 is already set up."
fi
if [ "$status" = "1" ] || [ "$status" = "2" ]; then
cat <<EOF

================================================

$status_text Details for IKEv2 mode:

EOF
  sed -n '/VPN server address:/,/Write this down/p' "$ikev2_log"
cat <<'EOF'

To start using IKEv2, see: https://git.io/ikev2docker

================================================

EOF
else
  echo
fi

# Check for new Libreswan version
swan_ver_file="/opt/src/swanver"
if [ ! -f "$swan_ver_file" ]; then
  touch "$swan_ver_file"
  ipsec_ver=$(ipsec --version 2>/dev/null)
  swan_ver=$(printf '%s' "$ipsec_ver" | sed -e 's/.*Libreswan U\?//' -e 's/\( (\|\/K\).*//')
  swan_ver_url="https://dl.ls20.com/v1/docker/$os_type/$os_arch/swanver?ver=$swan_ver&ver2=$IMAGE_VER&i=$status"
  swan_ver_latest=$(wget -t 3 -T 15 -qO- "$swan_ver_url")
  if printf '%s' "$swan_ver_latest" | grep -Eq '^([3-9]|[1-9][0-9]{1,2})(\.([0-9]|[1-9][0-9]{1,2})){1,2}$' \
    && [ -n "$swan_ver" ] && [ "$swan_ver" != "$swan_ver_latest" ] \
    && printf '%s\n%s' "$swan_ver" "$swan_ver_latest" | sort -C -V; then
    printf '%s\n' "swan_ver_latest='$swan_ver_latest'" > "$swan_ver_file"
  fi
fi
if [ -s "$swan_ver_file" ]; then
  . "$swan_ver_file"
cat <<EOF
Note: A newer version of Libreswan ($swan_ver_latest) is available.
To update this Docker image, see: https://git.io/updatedockervpn

EOF
fi

# Start xl2tpd
mkdir -p /var/run/xl2tpd
rm -f /var/run/xl2tpd.pid
exec /usr/sbin/xl2tpd -D -c /etc/xl2tpd/xl2tpd.conf
