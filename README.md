# IPsec VPN Server on Docker

[![Build Status](https://img.shields.io/travis/hwdsl2/docker-ipsec-vpn-server.svg)](https://travis-ci.org/hwdsl2/docker-ipsec-vpn-server) 
[![Docker Stars](https://img.shields.io/docker/stars/hwdsl2/ipsec-vpn-server.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server) 
[![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/ipsec-vpn-server.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server)

Docker image to run an IPsec VPN server, with support for both `IPsec/L2TP` and `IPsec/XAuth ("Cisco IPsec")`.

Based on Debian Jessie with [Libreswan](https://libreswan.org) (IPsec VPN software) and [xl2tpd](https://github.com/xelerance/xl2tpd) (L2TP daemon).

## Install Docker

Follow [these instructions](https://docs.docker.com/engine/installation/) to get Docker running on your server.

## Download

Get the trusted build from the [Docker Hub registry](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server):

```
docker pull hwdsl2/ipsec-vpn-server
```

or download and compile the source yourself from GitHub:

```
git clone https://github.com/fcojean/docker-ipsec-vpn-server.git
cd docker-ipsec-vpn-server
docker build -t fcojean/l2tp-ipsec-vpn-server .
```

## How to use this image

### Environment variables

This Docker image uses the following three environment variables, that can be declared in an `env` file:

```
VPN_IPSEC_PSK=<IPsec pre-shared key>
VPN_USER_CREDENTIAL_LIST=[{"login":"userTest1","password":"test1"},{"login":"userTest2","password":"test2"}]
```

The IPsec PSK (pre-shared key) is specified by the `VPN_IPSEC_PSK` environment variable.
Multiple user is supported. VPN user credentials is defined in `VPN_USER_CREDENTIAL_LIST` environnement variable.
Users login and password must be defined in a json format array. Each user should be define with a "login" and a "password" attribute. 

**Note:** In your `env` file, DO NOT put single or double quotes around values, or add space around `=`. Also, DO NOT use these characters within values: `\ " '`

All the variables to this image are optional, which means you don't have to type in any environment variable, and you can have an IPsec VPN server out of the box! Read the sections below for details.

### Start the IPsec VPN server

First, run this command on the Docker host to load the IPsec `NETKEY` kernel module:

```
sudo modprobe af_key
```

Start a new Docker container with the following command (replace `./vpn.env` with your own `env` file) :

```
docker run \
    --name l2tp-ipsec-vpn-server \
    --env-file ./vpn.env \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -v /lib/modules:/lib/modules:ro \
    -d --privileged \
    fcojean/l2tp-ipsec-vpn-server
```

### Retrieve VPN login details

If you did not set environment variables via an `env` file, a vpn user login will default to `vpnuser` and both `VPN_IPSEC_PSK` and vpn user password will be randomly generated. To retrieve them, show the logs of the running container:

```
docker logs l2tp-ipsec-vpn-server
```

Search for these lines in the output:

```console
Connect to your new VPN with these details:

Server IP: <VPN Server IP>
IPsec PSK: <IPsec pre-shared key>
Users credentials :
Login : <vpn user_login> Password : <vpn user_password>
```

### Check server status

To check the status of your IPsec VPN server, you can pass `ipsec status` to your container like this:

```
docker exec -it l2tp-ipsec-vpn-server ipsec status
```

## Next Steps

Get your computer or device to use the VPN. Please refer to:

[Configure IPsec/L2TP VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md)   
[Configure IPsec/XAuth VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md)

Enjoy your very own VPN! :sparkles::tada::rocket::sparkles:

## Technical Details

There are two services running: `Libreswan (pluto)` for the IPsec VPN, and `xl2tpd` for L2TP support.

Clients are configured to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN connection is active.

The default IPsec configuration supports:

* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IPsec/L2TP with PSK

The ports that are exposed for this container to work are:

* 4500/udp and 500/udp for IPsec

## See Also

* [IPsec VPN Server on Ubuntu, Debian and CentOS](https://github.com/hwdsl2/setup-ipsec-vpn)
* [IKEv2 VPN Server on Docker](https://github.com/gaomd/docker-ikev2-vpn-server)

## Author

##### Lin Song   
- Final year U.S. PhD candidate, majoring in Electrical and Computer Engineering (ECE)
- Actively seeking opportunities in areas such as Software or Systems Engineering
- Contact me on LinkedIn: <a href="https://www.linkedin.com/in/linsongui" target="_blank">https://www.linkedin.com/in/linsongui</a>

## License

Copyright (C) 2016&nbsp;Lin Song&nbsp;&nbsp;&nbsp;<a href="https://www.linkedin.com/in/linsongui" target="_blank"><img src="https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png" width="160" height="25" border="0" alt="View my profile on LinkedIn"></a>    
Based on [the work of Thomas Sarlandie](https://github.com/sarfata/voodooprivacy) (Copyright 2012)

This work is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/)   
Attribution required: please include my name in any derivative and let me know how you have improved it!