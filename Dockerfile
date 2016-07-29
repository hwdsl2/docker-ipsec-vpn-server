FROM debian:jessie
MAINTAINER Lin Song <linsongui@gmail.com>

ENV REFRESHED_AT 2016-07-29
ENV SWAN_VER 3.18

RUN apt-get -yqq update \
    && DEBIAN_FRONTEND=noninteractive apt-get -yqq --no-install-recommends install \
         wget dnsutils openssl ca-certificates kmod \
         iproute gawk grep sed net-tools iptables \
         libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
         libcap-ng-dev libcap-ng-utils libselinux1-dev \
         libcurl4-nss-dev libsystemd-dev flex bison gcc make \
         libunbound-dev libnss3-tools libevent-dev xl2tpd xmlto \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/src
RUN wget -t 3 -T 30 -nv -O "libreswan-${SWAN_VER}.tar.gz" "https://download.libreswan.org/libreswan-${SWAN_VER}.tar.gz" \
    || wget -t 3 -T 30 -nv -O "libreswan-${SWAN_VER}.tar.gz" "https://github.com/libreswan/libreswan/archive/v${SWAN_VER}.tar.gz" \
    && tar xzf "libreswan-${SWAN_VER}.tar.gz" \
    && rm -f "libreswan-${SWAN_VER}.tar.gz" \
    && cd "libreswan-${SWAN_VER}" \
    && echo "WERROR_CFLAGS =" > Makefile.inc.local \
    && make -s programs \
    && make -s install \
    && rm -rf "/opt/src/libreswan-${SWAN_VER}"

COPY ./run.sh /run.sh
RUN chmod 755 /run.sh

EXPOSE 500/udp 4500/udp

VOLUME ["/lib/modules"]

CMD ["/run.sh"]
