# Advanced Usage

*Read this in other languages: [English](advanced-usage.md), [简体中文](advanced-usage-zh.md).*

- [Use alternative DNS servers](#use-alternative-dns-servers)
- [Run without privileged mode](#run-without-privileged-mode)
- [Select VPN modes](#select-vpn-modes)
- [Access other containers on the Docker host](#access-other-containers-on-the-docker-host)
- [Specify VPN server's public IP](#specify-vpn-servers-public-ip)
- [About host network mode](#about-host-network-mode)
- [Enable Libreswan logs](#enable-libreswan-logs)
- [Check server status](#check-server-status)
- [Build from source code](#build-from-source-code)
- [Bash shell inside container](#bash-shell-inside-container)
- [Bind mount the env file](#bind-mount-the-env-file)

## Use alternative DNS servers

Clients are set to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN is active. If another DNS provider is preferred, define `VPN_DNS_SRV1` and optionally `VPN_DNS_SRV2` in your `env` file, then follow [instructions](../README.md#update-docker-image) to re-create the Docker container. For example, if you want to use [Cloudflare's DNS service](https://1.1.1.1/dns/):

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

## Run without privileged mode

Advanced users can create a Docker container from this image without using [privileged mode](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) (replace `./vpn.env` with your own `env` file):

```
docker run \
    --name ipsec-vpn-server \
    --env-file ./vpn.env \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --cap-add=NET_ADMIN \
    --device=/dev/ppp \
    --sysctl net.ipv4.ip_forward=1 \
    --sysctl net.ipv4.conf.all.accept_redirects=0 \
    --sysctl net.ipv4.conf.all.send_redirects=0 \
    --sysctl net.ipv4.conf.all.rp_filter=0 \
    --sysctl net.ipv4.conf.default.accept_redirects=0 \
    --sysctl net.ipv4.conf.default.send_redirects=0 \
    --sysctl net.ipv4.conf.default.rp_filter=0 \
    --sysctl net.ipv4.conf.eth0.send_redirects=0 \
    --sysctl net.ipv4.conf.eth0.rp_filter=0 \
    hwdsl2/ipsec-vpn-server
```

When running without privileged mode, the container is unable to change `sysctl` settings. This could affect certain features of this image. A known issue is that the [Android MTU/MSS fix](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#android-mtumss-issues) also requires adding `--sysctl net.ipv4.ip_no_pmtu_disc=1` to the `docker run` command. If you encounter any issues, try re-creating the container using [privileged mode](../README.md#start-the-ipsec-vpn-server).

After creating the Docker container, see [Retrieve VPN login details](../README.md#retrieve-vpn-login-details).

Similarly, if using [Docker compose](https://docs.docker.com/compose/), you may replace `privileged: true` in [docker-compose.yml](../docker-compose.yml) with:

```
  cap_add:
    - NET_ADMIN
  devices:
    - "/dev/ppp:/dev/ppp"
  sysctls:
    - net.ipv4.ip_forward=1
    - net.ipv4.conf.all.accept_redirects=0
    - net.ipv4.conf.all.send_redirects=0
    - net.ipv4.conf.all.rp_filter=0
    - net.ipv4.conf.default.accept_redirects=0
    - net.ipv4.conf.default.send_redirects=0
    - net.ipv4.conf.default.rp_filter=0
    - net.ipv4.conf.eth0.send_redirects=0
    - net.ipv4.conf.eth0.rp_filter=0
```

For more information, see [compose file reference](https://docs.docker.com/compose/compose-file/).

## Select VPN modes

Using this Docker image, the IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes are enabled by default. In addition, IKEv2 mode will be enabled if the `-v ikev2-vpn-data:/etc/ipsec.d` option [is specified](../README.md#start-the-ipsec-vpn-server) in the `docker run` command when creating the Docker container.

Advanced users can selectively disable VPN modes by setting the following variable(s) in the `env` file, then re-create the Docker container.

Disable IPsec/L2TP mode: `VPN_DISABLE_IPSEC_L2TP=yes`   
Disable IPsec/XAuth ("Cisco IPsec") mode: `VPN_DISABLE_IPSEC_XAUTH=yes`   
Disable both IPsec/L2TP and IPsec/XAuth modes: `VPN_IKEV2_ONLY=yes`

## Access other containers on the Docker host

After connecting to the VPN, VPN clients can generally access services running in other containers on the same Docker host, without additional configuration.

For example, if the IPsec VPN server container has IP `172.17.0.2`, and an Nginx container with IP `172.17.0.3` is running on the same Docker host, VPN clients can use IP `172.17.0.3` to access services on the Nginx container. To find out which IP is assigned to a container, run `docker inspect <container name>`.

## Specify VPN server's public IP

On Docker hosts with multiple public IP addresses, advanced users can specify a public IP for the VPN server using variable `VPN_PUBLIC_IP` in the `env` file, then re-create the Docker container. For example, if the Docker host has IPs `192.0.2.1` and `192.0.2.2`, and you want the VPN server to use `192.0.2.2`:

```
VPN_PUBLIC_IP=192.0.2.2
```

Note that this variable has no effect if IKEv2 is already set up in the Docker container. In this case, you may remove IKEv2 and set it up again using custom options. Refer to [Configure and use IKEv2 VPN](../README.md#configure-and-use-ikev2-vpn).

Additional configuration may be required if you want VPN clients to use the specified public IP as their "outgoing IP" when the VPN connection is active, and the specified IP is NOT the main IP (or default route) on the Docker host. In this case, you can try adding an IPTables `SNAT` rule on the Docker host. To persist after reboot, you may add the command to `/etc/rc.local`.

Continuing with the example above, if the Docker container has internal IP `172.17.0.2` (check using `docker inspect ipsec-vpn-server`), Docker's network interface name is `docker0` (check using `iptables -nvL -t nat`), and you want the "outgoing IP" to be `192.0.2.2`:

```
iptables -t nat -I POSTROUTING -s 172.17.0.2 ! -o docker0 -j SNAT --to 192.0.2.2
```

To check the "outgoing IP" for a connected VPN client, you may open a browser on the client and [look up the IP address on Google](https://www.google.com/search?q=my+ip).

## About host network mode

Advanced users can run this image in [host network mode](https://docs.docker.com/network/host/), by adding `--network=host` to the `docker run` command. In addition, if [running without privileged mode](#run-without-privileged-mode), you may also need to replace `eth0` with the network interface name of your Docker host.

Host network mode is NOT recommended for this image, unless your use case requires it. In this mode, the container's network stack is not isolated from the Docker host, and VPN clients may be able to access ports or services on the Docker host using its internal VPN IP `192.168.42.1` after connecting using IPsec/L2TP mode. Note that you will need to manually clean up the changes to IPTables rules and sysctl settings by [run.sh](../run.sh) or reboot the server when you no longer use this image.

Some Docker host OS, such as Debian 10, cannot run this image in host network mode due to the use of nftables.

## Enable Libreswan logs

To keep the Docker image small, Libreswan (IPsec) logs are not enabled by default. If you need to enable it for troubleshooting purposes, first start a Bash session in the running container:

```
docker exec -it ipsec-vpn-server env TERM=xterm bash -l
```

Then run the following commands:

```
# For Alpine-based image
apk add --no-cache rsyslog
rsyslogd
ipsec whack --shutdown
ipsec pluto --config /etc/ipsec.conf
sed -i '/pluto\.pid/a rsyslogd' /opt/src/run.sh
exit
# For Debian-based image
apt-get update && apt-get -y install rsyslog
service rsyslog restart
service ipsec restart
sed -i '/pluto\.pid/a service rsyslog restart' /opt/src/run.sh
exit
```

When finished, you may check Libreswan logs with:

```
docker exec -it ipsec-vpn-server grep pluto /var/log/auth.log
```

To check xl2tpd logs, run `docker logs ipsec-vpn-server`.

## Check server status

Check the status of the IPsec VPN server:

```
docker exec -it ipsec-vpn-server ipsec status
```

Show currently established VPN connections:

```
docker exec -it ipsec-vpn-server ipsec trafficstatus
```

## Build from source code

Advanced users can download and compile the source code from GitHub:

```
git clone https://github.com/hwdsl2/docker-ipsec-vpn-server
cd docker-ipsec-vpn-server
# To build Alpine-based image
docker build -t hwdsl2/ipsec-vpn-server .
# To build Debian-based image
docker build -f Dockerfile.debian -t hwdsl2/ipsec-vpn-server:debian .
```

Or use this if not modifying the source code:

```
# To build Alpine-based image
docker build -t hwdsl2/ipsec-vpn-server github.com/hwdsl2/docker-ipsec-vpn-server
# To build Debian-based image
docker build -f Dockerfile.debian -t hwdsl2/ipsec-vpn-server:debian \
  github.com/hwdsl2/docker-ipsec-vpn-server
```

## Bash shell inside container

To start a Bash session in the running container:

```
docker exec -it ipsec-vpn-server env TERM=xterm bash -l
```

(Optional) Install the `nano` editor:

```
# For Alpine-based image
apk add --no-cache nano
# For Debian-based image
apt-get update && apt-get -y install nano
```

Then run your commands inside the container. When finished, exit the container and restart if needed:

```
exit
docker restart ipsec-vpn-server
```

## Bind mount the env file

As an alternative to the `--env-file` option, advanced users can bind mount the `env` file. The advantage of this method is that after updating the `env` file, you can restart the Docker container to take effect instead of re-creating it. To use this method, you must first edit your `env` file and use single quotes `''` to enclose the values of all variables. Then (re-)create the Docker container (replace the first `vpn.env` with your own `env` file):

```
docker run \
    --name ipsec-vpn-server \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v "$(pwd)/vpn.env:/opt/src/vpn.env:ro" \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

## License

**Note:** The software components inside the pre-built image (such as Libreswan and xl2tpd) are under the respective licenses chosen by their respective copyright holders. As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

Copyright (C) 2016-2021 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
This work is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/)   
Attribution required: please include my name in any derivative and let me know how you have improved it!
