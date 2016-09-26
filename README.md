# IPsec VPN Server on Docker

[![Build Status](https://static.ls20.com/travis-ci/docker-ipsec-vpn-server.svg)](https://travis-ci.org/hwdsl2/docker-ipsec-vpn-server) 
[![Author](https://static.ls20.com/travis-ci/author.svg)](#author) 
[![Docker Stars](https://img.shields.io/docker/stars/hwdsl2/ipsec-vpn-server.svg?maxAge=3600)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server) 
[![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/ipsec-vpn-server.svg?maxAge=3600)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server)

Docker image to run an IPsec VPN server, with support for both `IPsec/L2TP` and `IPsec/XAuth ("Cisco IPsec")`.

Based on Debian Jessie with [Libreswan](https://libreswan.org) (IPsec VPN software) and [xl2tpd](https://github.com/xelerance/xl2tpd) (L2TP daemon).

*Read this in other languages: [English](README.md), [简体中文](README-zh.md).*

## Install Docker

Follow [these instructions](https://docs.docker.com/engine/installation/) to get Docker running on your server.

## Download

Get the trusted build from the [Docker Hub registry](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server):

```
docker pull hwdsl2/ipsec-vpn-server
```

Alternatively, you may [build from source code](#build-from-source-code) on GitHub.

## How to use this image

### Environment variables

This Docker image uses the following three environment variables, that can be declared in an `env` file:

```
VPN_IPSEC_PSK=<IPsec pre-shared key>
VPN_USER=<VPN Username>
VPN_PASSWORD=<VPN Password>
```

This will create a single user account for VPN login. The IPsec PSK (pre-shared key) is specified by the `VPN_IPSEC_PSK` environment variable. The VPN username is defined in `VPN_USER`, and VPN password is specified by `VPN_PASSWORD`.

**Note 1:** In your `env` file, DO NOT put single or double quotes around values, or add space around `=`. Also, DO NOT use these characters within values: `\ " '`

**Note 2:** The same VPN account can be used by your multiple devices. However, due to a limitation of the IPsec protocol, if these devices are behind the same NAT (e.g. home router), they cannot simultaneously connect to the VPN server.

All the variables to this image are optional, which means you don't have to type in any environment variable, and you can have an IPsec VPN server out of the box! Read the sections below for details.

### Start the IPsec VPN server

(IMPORTANT) First, run this command on the Docker host to load the IPsec `NETKEY` kernel module:

```
sudo modprobe af_key
```

Start a new Docker container with the following command (replace `./vpn.env` with your own `env` file) :

```
docker run \
    --name ipsec-vpn-server \
    --env-file ./vpn.env \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -v /lib/modules:/lib/modules:ro \
    -d --privileged \
    --restart=always \
    hwdsl2/ipsec-vpn-server
```

### Retrieve VPN login details

If you did not set environment variables via an `env` file, `VPN_USER` will default to `vpnuser` and both `VPN_IPSEC_PSK` and `VPN_PASSWORD` will be randomly generated. To retrieve them, show the logs of the running container:

```
docker logs ipsec-vpn-server
```

Search for these lines in the output:

```
Connect to your new VPN with these details:

Server IP: <VPN Server IP>
IPsec PSK: <IPsec pre-shared key>
Username: <VPN Username>
Password: <VPN Password>
```

### Check server status

To check the status of your IPsec VPN server, you can pass `ipsec status` to your container like this:

```
docker exec -it ipsec-vpn-server ipsec status
```

## Next steps

Get your computer or device to use the VPN. Please refer to:

[Configure IPsec/L2TP VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md)   
[Configure IPsec/XAuth ("Cisco IPsec") VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md)

If you get an error when trying to connect, see [Troubleshooting](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#troubleshooting).

Enjoy your very own VPN! :sparkles::tada::rocket::sparkles:

## Technical details

There are two services running: `Libreswan (pluto)` for the IPsec VPN, and `xl2tpd` for L2TP support.

Clients are configured to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN connection is active.

The default IPsec configuration supports:

* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IPsec/L2TP with PSK

The ports that are exposed for this container to work are:

* 4500/udp and 500/udp for IPsec

## Build from source code

Advanced users can download and compile the source yourself from GitHub:

```
git clone https://github.com/hwdsl2/docker-ipsec-vpn-server.git
cd docker-ipsec-vpn-server
docker build -t hwdsl2/ipsec-vpn-server .
```

or use this if not modifying the source code:

```
docker build -t hwdsl2/ipsec-vpn-server github.com/hwdsl2/docker-ipsec-vpn-server.git
```

## See also

* [IPsec VPN Server on Ubuntu, Debian and CentOS](https://github.com/hwdsl2/setup-ipsec-vpn)
* [IKEv2 VPN Server on Docker](https://github.com/gaomd/docker-ikev2-vpn-server)

## Author

**Lin Song** (linsongui@gmail.com)   
- Final year U.S. PhD candidate, majoring in Electrical and Computer Engineering (ECE)
- Actively seeking opportunities in areas such as Software or Systems Engineering
- Contact me on LinkedIn: [https://www.linkedin.com/in/linsongui](https://www.linkedin.com/in/linsongui)

Thanks to <a href="https://github.com/hwdsl2/docker-ipsec-vpn-server/graphs/contributors" target="_blank">all contributors</a> to this project!

## License

Copyright (C) 2016&nbsp;Lin Song&nbsp;&nbsp;&nbsp;<a href="https://www.linkedin.com/in/linsongui" target="_blank"><img src="https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png" width="160" height="25" border="0" alt="View my profile on LinkedIn"></a>    
Based on [the work of Thomas Sarlandie](https://github.com/sarfata/voodooprivacy) (Copyright 2012)

This work is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/)   
Attribution required: please include my name in any derivative and let me know how you have improved it!
