#!/bin/bash

VPN_USER=$1
VPN_PASSWORD=$2
MOUNT_CHECK=$3

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# process STDIN; expecting one or more lines of "username cleartxt", "username\tcleartxt", or "username,cleartxt"
if [[ ! -t 0 && -z "$MOUNT_CHECK" ]]; then
  while IFS=$' \t,' read -a INP; do
    ./useradd.sh ${INP[0]} ${INP[1]} bypass
    echo "Added ${INP[0]}"
  done 
  exit 0
fi

exiterr()  { echo "Error: $1" >&2; exit 1; }
nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
onespace() { printf '%s' "$1" | tr -s ' '; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }
noquotes2() { printf '%s' "$1" | sed -e 's/" "/ /g' -e "s/' '/ /g"; }

if [ ! -f "/.dockerenv" ]; then
  exiterr "This script ONLY runs in a Docker container."
fi

if [ "$MOUNT_CHECK" != "bypass" -a "$(mount | egrep '(/etc/ppp/chap-secrets|/etc/ipsec.d/passwd)' | wc -l)" -ne 2 ]; then
  exiterr "/etc/ppp/chap-secrets and /etc/ipsec.d/passwd must be bind mounted."
fi

if [ ! -w /etc/ppp/chap-secrets ]; then
  exiterr "/etc/ppp/chap-secrets must be writable."
fi

if [ ! -w /etc/ipsec.d/passwd ]; then
  exiterr "/etc/ipsec.d/passwd must be writable."
fi

# Remove whitespace and quotes around VPN variables, if any
VPN_USER="$(nospaces "$VPN_USER")"
VPN_USER="$(noquotes "$VPN_USER")"
VPN_PASSWORD="$(nospaces "$VPN_PASSWORD")"
VPN_PASSWORD="$(noquotes "$VPN_PASSWORD")"

if [ -z "$VPN_USER" ] || [ -z "$VPN_PASSWORD" ]; then
  exiterr "All VPN credentials must be specified."
fi

if printf '%s' "$VPN_USER $VPN_PASSWORD" | LC_ALL=C grep -q '[^ -~]\+'; then
  exiterr "VPN credentials must not contain non-ASCII characters."
fi

case "$VPN_USER $VPN_PASSWORD" in
  *[\\\"\']*)
    exiterr "VPN credentials must not contain these special characters: \\ \" '"
    ;;
esac

# Create VPN credentials
cat >> /etc/ppp/chap-secrets <<EOF
"$VPN_USER" l2tpd "$VPN_PASSWORD" *
EOF

VPN_PASSWORD_ENC=$(openssl passwd -1 "$VPN_PASSWORD")
cat >> /etc/ipsec.d/passwd <<EOF
$VPN_USER:$VPN_PASSWORD_ENC:xauth-psk
EOF
