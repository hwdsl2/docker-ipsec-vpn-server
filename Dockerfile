FROM debian:jessie
MAINTAINER Lin Song <linsongui@gmail.com>

ENV REFRESHED_AT 2016-10-01
ENV SWAN_VER 3.18

WORKDIR /opt/src

RUN sed -i "s/httpredir\.debian\.org/ftp.us.debian.org/g" /etc/apt/sources.list \
    && apt-get -yqq update \
    && DEBIAN_FRONTEND=noninteractive apt-get -yqq --no-install-recommends install \
         wget dnsutils openssl ca-certificates kmod \
         iproute gawk grep sed net-tools iptables \
         bsdmainutils libunbound2 libcurl3-nss \
         libnss3-tools libevent-dev libcap-ng0 xl2tpd \
         libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
         libcap-ng-dev libcap-ng-utils libselinux1-dev \
         libcurl4-nss-dev libsystemd-dev flex bison gcc make \
         libunbound-dev xmlto \
    && wget -t 3 -T 30 -nv -O "libreswan.tar.gz" "https://download.libreswan.org/libreswan-${SWAN_VER}.tar.gz" \
    || wget -t 3 -T 30 -nv -O "libreswan.tar.gz" "https://github.com/libreswan/libreswan/archive/v${SWAN_VER}.tar.gz" \
    && tar xzf "libreswan.tar.gz" \
    && rm -f "libreswan.tar.gz" \
    && cd "libreswan-${SWAN_VER}" \
    && echo "WERROR_CFLAGS =" > Makefile.inc.local \
    && make -s programs \
    && make -s install \
    && cd /opt/src \
    && rm -rf "/opt/src/libreswan-${SWAN_VER}" \
    && apt-get -yqq remove \
         libnss3-dev libnspr4-dev pkg-config libpam0g-dev \
         libcap-ng-dev libcap-ng-utils libselinux1-dev \
         libcurl4-nss-dev libsystemd-dev flex bison gcc make \
         libunbound-dev xmlto perl-modules perl \
    && apt-get -yqq autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./run.sh /run.sh
RUN chmod 755 /run.sh

EXPOSE 500/udp 4500/udp

VOLUME ["/lib/modules"]

CMD ["/run.sh"]
