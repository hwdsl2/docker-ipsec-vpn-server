#
# Copyright (C) 2021-2023 Lin Song <linsongui@gmail.com>
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

FROM alpine:3.18

ENV SWAN_VER 4.12
WORKDIR /opt/src

RUN set -x \
    && apk add --no-cache \
         bash bind-tools coreutils openssl uuidgen wget xl2tpd iproute2 \
         libcap-ng libcurl libevent linux-pam musl nspr nss nss-tools openrc \
         bison flex gcc make libc-dev bsd-compat-headers linux-pam-dev \
         nss-dev libcap-ng-dev libevent-dev curl-dev nspr-dev \
    && wget -t 3 -T 30 -nv -O libreswan.tar.gz "https://github.com/libreswan/libreswan/archive/v${SWAN_VER}.tar.gz" \
    || wget -t 3 -T 30 -nv -O libreswan.tar.gz "https://download.libreswan.org/libreswan-${SWAN_VER}.tar.gz" \
    && tar xzf libreswan.tar.gz \
    && rm -f libreswan.tar.gz \
    && cd "libreswan-${SWAN_VER}" \
    && printf 'WERROR_CFLAGS=-w -s\nUSE_DNSSEC=false\nUSE_DH2=true\nFINALNSSDIR=/etc/ipsec.d\n' > Makefile.inc.local \
    && make -s base \
    && make -s install-base \
    && cd /opt/src \
    && mkdir -p /run/openrc \
    && touch /run/openrc/softlevel \
    && rm -rf "/opt/src/libreswan-${SWAN_VER}" \
    && apk del --no-cache \
         bison flex gcc make libc-dev bsd-compat-headers linux-pam-dev \
         nss-dev libcap-ng-dev libevent-dev curl-dev nspr-dev

RUN wget -t 3 -T 30 -nv -O /opt/src/ikev2.sh https://github.com/hwdsl2/setup-ipsec-vpn/raw/16f5a1d81f9411846d434c0ac01de93a28d23e92/extras/ikev2setup.sh \
    && chmod +x /opt/src/ikev2.sh \
    && ln -s /opt/src/ikev2.sh /usr/bin

COPY ./run.sh /opt/src/run.sh
RUN chmod 755 /opt/src/run.sh
EXPOSE 500/udp 4500/udp
CMD ["/opt/src/run.sh"]

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF
ENV IMAGE_VER $BUILD_DATE

LABEL maintainer="Lin Song <linsongui@gmail.com>" \
    org.opencontainers.image.created="$BUILD_DATE" \
    org.opencontainers.image.version="$VERSION" \
    org.opencontainers.image.revision="$VCS_REF" \
    org.opencontainers.image.authors="Lin Song <linsongui@gmail.com>" \
    org.opencontainers.image.title="IPsec VPN Server on Docker" \
    org.opencontainers.image.description="Docker image to run an IPsec VPN server, with IPsec/L2TP, Cisco IPsec and IKEv2." \
    org.opencontainers.image.url="https://github.com/hwdsl2/docker-ipsec-vpn-server" \
    org.opencontainers.image.source="https://github.com/hwdsl2/docker-ipsec-vpn-server" \
    org.opencontainers.image.documentation="https://github.com/hwdsl2/docker-ipsec-vpn-server"
