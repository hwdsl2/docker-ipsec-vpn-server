# IPsec VPN Server on Docker

[![Build Status](https://travis-ci.org/hwdsl2/docker-ipsec-vpn-server.svg?branch=master)](https://travis-ci.org/hwdsl2/docker-ipsec-vpn-server) [![GitHub Stars](https://img.shields.io/github/stars/hwdsl2/docker-ipsec-vpn-server.svg?maxAge=86400)](https://github.com/hwdsl2/docker-ipsec-vpn-server/stargazers) [![Docker Stars](https://img.shields.io/docker/stars/hwdsl2/ipsec-vpn-server.svg?maxAge=86400)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server) [![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/ipsec-vpn-server.svg?maxAge=86400)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server)

Docker image to run an IPsec VPN server, with both `IPsec/L2TP` and `Cisco IPsec`.

Based on Debian 9 (Stretch) with [Libreswan](https://libreswan.org) (IPsec VPN software) and [xl2tpd](https://github.com/xelerance/xl2tpd) (L2TP daemon).

[**&raquo; See also: IPsec VPN Server on Ubuntu, Debian and CentOS**](https://github.com/hwdsl2/setup-ipsec-vpn)

*Read this in other languages: [English](https://github.com/hwdsl2/docker-ipsec-vpn-server), [简体中文](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md).*

#### Table of Contents

- [Install Docker](https://github.com/hwdsl2/docker-ipsec-vpn-server#install-docker)
- [Download](https://github.com/hwdsl2/docker-ipsec-vpn-server#download)
- [How to use this image](https://github.com/hwdsl2/docker-ipsec-vpn-server#how-to-use-this-image)
- [Next steps](https://github.com/hwdsl2/docker-ipsec-vpn-server#next-steps)
- [Important notes](https://github.com/hwdsl2/docker-ipsec-vpn-server#important-notes)
- [Update Docker image](https://github.com/hwdsl2/docker-ipsec-vpn-server#update-docker-image)
- [Advanced usage](https://github.com/hwdsl2/docker-ipsec-vpn-server#advanced-usage)
- [Technical details](https://github.com/hwdsl2/docker-ipsec-vpn-server#technical-details)
- [See also](https://github.com/hwdsl2/docker-ipsec-vpn-server#see-also)
- [License](https://github.com/hwdsl2/docker-ipsec-vpn-server#license)

## Install Docker

First, [install and run Docker](https://docs.docker.com/engine/installation/) on your Linux server.

## Download

Get the trusted build from the [Docker Hub registry](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/):

```
docker pull hwdsl2/ipsec-vpn-server
```

Alternatively, you may [build from source code](https://github.com/hwdsl2/docker-ipsec-vpn-server#build-from-source-code) on GitHub.

## How to use this image

### Environment variables

This Docker image uses the following three variables, that can be declared in an `env` file ([example](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/vpn.env.example)):

```
VPN_IPSEC_PSK=your_ipsec_pre_shared_key
VPN_USER=your_vpn_username
VPN_PASSWORD=your_vpn_password
```

This will create a user account for VPN login, which can be used by your multiple devices[*](https://github.com/hwdsl2/docker-ipsec-vpn-server#multi-device-note) . The IPsec PSK (pre-shared key) is specified by the `VPN_IPSEC_PSK` environment variable. The VPN username is defined in `VPN_USER`, and VPN password is specified by `VPN_PASSWORD`.

**Note:** In your `env` file, DO NOT put `""` or `''` around values, or add space around `=`. DO NOT use these special characters within values: `\ " '`.

All the variables to this image are optional, which means you don't have to type in any environment variable, and you can have an IPsec VPN server out of the box! Read the sections below for details.

### Start the IPsec VPN server

**Important:** First, load the IPsec `NETKEY` kernel module on the Docker host:

```
sudo modprobe af_key
```

Create a new Docker container from this image (replace `./vpn.env` with your own `env` file):

```
docker run \
    --name ipsec-vpn-server \
    --env-file ./vpn.env \
    --restart=always \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -v /lib/modules:/lib/modules:ro \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

### Retrieve VPN login details

If you did not specify an `env` file in the `docker run` command above, `VPN_USER` will default to `vpnuser` and both `VPN_IPSEC_PSK` and `VPN_PASSWORD` will be randomly generated. To retrieve them, view the container logs:

```
docker logs ipsec-vpn-server
```

Search for these lines in the output:

```
Connect to your new VPN with these details:

Server IP: your_vpn_server_ip
IPsec PSK: your_ipsec_pre_shared_key
Username: your_vpn_username
Password: your_vpn_password
```

(Optional) Backup the generated VPN login details (if any) to the current directory:

```
docker cp ipsec-vpn-server:/opt/src/vpn-gen.env ./
```

### Check server status

To check the status of your IPsec VPN server, you can pass `ipsec status` to your container like this:

```
docker exec -it ipsec-vpn-server ipsec status
```

Or display current established VPN connections:

```
docker exec -it ipsec-vpn-server ipsec whack --trafficstatus
```

## Next steps

Get your computer or device to use the VPN. Please refer to:

**[Configure IPsec/L2TP VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md)**

**[Configure IPsec/XAuth ("Cisco IPsec") VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md)**

If you get an error when trying to connect, see [Troubleshooting](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#troubleshooting).

Enjoy your very own VPN!

## Important notes

*Read this in other languages: [English](https://github.com/hwdsl2/docker-ipsec-vpn-server#important-notes), [简体中文](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md#重要提示).*

For **Windows users**, this [one-time registry change](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#windows-error-809) is required if the VPN server and/or client is behind NAT (e.g. home router).

<a name="multi-device-note"></a>
The same VPN account can be used by your multiple devices. However, due to an IPsec/L2TP limitation, if you wish to connect multiple devices simultaneously from behind the same NAT (e.g. home router), you must use only [IPsec/XAuth mode](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md).

For servers with an external firewall (e.g. [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html)/[GCE](https://cloud.google.com/compute/docs/vpc/firewalls)), open UDP ports 500 and 4500 for the VPN.

Before editing any VPN config files, you must first [start a Bash session](https://github.com/hwdsl2/docker-ipsec-vpn-server#bash-shell-inside-container) in the running container.

If you wish to add, edit or remove VPN user accounts, see [Manage VPN Users](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/manage-users.md). **Important:** After editing the VPN config files, you must also comment out the relevant sections in `/opt/src/run.sh`, to avoid losing your changes on container restart.

Clients are set to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN connection is active. If another DNS provider is preferred, replace `8.8.8.8` and `8.8.4.4` in `/opt/src/run.sh` with the new servers. Then restart the Docker container.

## Update Docker image

To update your Docker image and container, follow these steps:

```
docker pull hwdsl2/ipsec-vpn-server
```

If the Docker image is already up to date, you should see:

```
Status: Image is up to date for hwdsl2/ipsec-vpn-server:latest
```

Otherwise, it will download the latest version. To update your Docker container, first write down all your VPN login details (refer to "Retrieve VPN login details" above). Then remove the Docker container with `docker rm -f ipsec-vpn-server`. Finally, re-create it using instructions from the "How to use this image" section.

## Advanced usage

### Build from source code

Advanced users can download and compile the source code from GitHub:

```
git clone https://github.com/hwdsl2/docker-ipsec-vpn-server.git
cd docker-ipsec-vpn-server
docker build -t hwdsl2/ipsec-vpn-server .
```

Or use this if not modifying the source code:

```
docker build -t hwdsl2/ipsec-vpn-server github.com/hwdsl2/docker-ipsec-vpn-server.git
```

### Bash shell inside container

To start a Bash session in the running container:

```
docker exec -it ipsec-vpn-server env TERM=xterm bash -l
```

(Optional) Install the `nano` editor:

```
apt-get update && apt-get -y install nano
```

Then run your commands inside the container. When finished, exit the container and restart if needed:

```
exit
docker restart ipsec-vpn-server
```

### Enable Libreswan logs

To keep the Docker image small, Libreswan (IPsec) logs are not enabled by default. If you are an advanced user and wish to enable it for troubleshooting purposes, first start a Bash session in the running container:

```
docker exec -it ipsec-vpn-server env TERM=xterm bash -l
```

Then run the following commands:

```
apt-get update && apt-get -y install rsyslog
service rsyslog restart
service ipsec restart
sed -i '/modprobe/a service rsyslog restart' /opt/src/run.sh
exit
```

When finished, you may check Libreswan logs with:

```
docker exec -it ipsec-vpn-server grep pluto /var/log/auth.log
```

## Technical details

There are two services running: `Libreswan (pluto)` for the IPsec VPN, and `xl2tpd` for L2TP support.

The default IPsec configuration supports:

* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IPsec/L2TP with PSK

The ports that are exposed for this container to work are:

* 4500/udp and 500/udp for IPsec

## See also

* [IPsec VPN Server on Ubuntu, Debian and CentOS](https://github.com/hwdsl2/setup-ipsec-vpn)
* [IKEv2 VPN Server on Docker](https://github.com/gaomd/docker-ikev2-vpn-server)

## License

Copyright (C) 2016-2017 [Lin Song](https://www.linkedin.com/in/linsongui) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
Based on [the work of Thomas Sarlandie](https://github.com/sarfata/voodooprivacy) (Copyright 2012)

This work is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/)   
Attribution required: please include my name in any derivative and let me know how you have improved it!
