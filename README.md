[English](README.md) | [中文](README-zh.md)

# IPsec VPN Server on Docker

[![Build Status](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml/badge.svg)](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml) [![GitHub Stars](docs/images/badges/github-stars.svg)](https://github.com/hwdsl2/docker-ipsec-vpn-server/stargazers) [![Docker Stars](docs/images/badges/docker-stars.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/) [![Docker Pulls](docs/images/badges/docker-pulls.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/)

Docker image to run an IPsec VPN server, with IPsec/L2TP, Cisco IPsec and IKEv2.

Based on Alpine 3.16 or Debian 11 with [Libreswan](https://libreswan.org) (IPsec VPN software) and [xl2tpd](https://github.com/xelerance/xl2tpd) (L2TP daemon).

An IPsec VPN encrypts your network traffic, so that nobody between you and the VPN server can eavesdrop on your data as it travels via the Internet. This is especially useful when using unsecured networks, e.g. at coffee shops, airports or hotel rooms.

[**&raquo; See also: IPsec VPN Server Auto Setup Scripts**](https://github.com/hwdsl2/setup-ipsec-vpn)

## Quick start

Use this command to set up an IPsec VPN server on Docker:

```
docker run \
    --name ipsec-vpn-server \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v /lib/modules:/lib/modules:ro \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

Your VPN login details will be randomly generated. See [Retrieve VPN login details](#retrieve-vpn-login-details).

To learn more about how to use this image, read the sections below.

## Features

- Supports IKEv2 with strong and fast ciphers (e.g. AES-GCM)
- Generates VPN profiles to auto-configure iOS, macOS and Android devices
- Supports Windows, macOS, iOS, Android and Linux as VPN clients
- Includes a helper script to manage IKEv2 users and certificates

## Install Docker

First, [install Docker](https://docs.docker.com/engine/install/) on your Linux server. You may also use [Podman](https://podman.io) to run this image, after [creating an alias](https://podman.io/whatis.html) for `docker`.

Advanced users can use this image on macOS with [Docker for Mac](https://docs.docker.com/docker-for-mac/). Before using IPsec/L2TP mode, you may need to restart the Docker container once with `docker restart ipsec-vpn-server`. This image does not support Docker for Windows.

## Download

Get the trusted build from the [Docker Hub registry](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/):

```
docker pull hwdsl2/ipsec-vpn-server
```

Alternatively, you may download from [Quay.io](https://quay.io/repository/hwdsl2/ipsec-vpn-server):

```
docker pull quay.io/hwdsl2/ipsec-vpn-server
docker image tag quay.io/hwdsl2/ipsec-vpn-server hwdsl2/ipsec-vpn-server
```

Supported platforms: `linux/amd64`, `linux/arm64` and `linux/arm/v7`.

Advanced users can [build from source code](docs/advanced-usage.md#build-from-source-code) on GitHub.

### Image comparison

Two pre-built images are available. The default Alpine-based image is only ~17MB.

|                   | Alpine-based             | Debian-based                   |
| ----------------- | ------------------------ | ------------------------------ |
| Image name        | hwdsl2/ipsec-vpn-server  | hwdsl2/ipsec-vpn-server:debian |
| Compressed size   | ~ 17 MB                  | ~ 62 MB                        |
| Base image        | Alpine Linux 3.16        | Debian Linux 11                |
| Platforms         | amd64, arm64, arm/v7     | amd64, arm64, arm/v7           |
| Libreswan version | 4.7                      | 4.7                            |
| IPsec/L2TP        | ✅                       | ✅                              |
| Cisco IPsec       | ✅                       | ✅                              |
| IKEv2             | ✅                       | ✅                              |

**Note:** To use the Debian-based image, replace every `hwdsl2/ipsec-vpn-server` with `hwdsl2/ipsec-vpn-server:debian` in this README.

## How to use this image

### Environment variables

**Note:** All the variables to this image are optional, which means you don't have to type in any variable, and you can have an IPsec VPN server out of the box! To do that, create an empty `env` file using `touch vpn.env`, and skip to the next section.

This Docker image uses the following variables, that can be declared in an `env` file (see [example](vpn.env.example)):

```
VPN_IPSEC_PSK=your_ipsec_pre_shared_key
VPN_USER=your_vpn_username
VPN_PASSWORD=your_vpn_password
```

This will create a user account for VPN login, which can be used by your multiple devices[*](#important-notes). The IPsec PSK (pre-shared key) is specified by the `VPN_IPSEC_PSK` environment variable. The VPN username is defined in `VPN_USER`, and VPN password is specified by `VPN_PASSWORD`.

Additional VPN users are supported, and can be optionally declared in your `env` file like this. Usernames and passwords must be separated by spaces, and usernames cannot contain duplicates. All VPN users will share the same IPsec PSK.

```
VPN_ADDL_USERS=additional_username_1 additional_username_2
VPN_ADDL_PASSWORDS=additional_password_1 additional_password_2
```

**Note:** In your `env` file, DO NOT put `""` or `''` around values, or add space around `=`. DO NOT use these special characters within values: `\ " '`. A secure IPsec PSK should consist of at least 20 random characters.

<details>
<summary>
:information_source: You may optionally specify a DNS name, client name and/or custom DNS servers. :information_source:
</summary>

Advanced users can optionally specify a DNS name for the IKEv2 server address. The DNS name must be a fully qualified domain name (FQDN). Example:

```
VPN_DNS_NAME=vpn.example.com
```

You may specify a name for the first IKEv2 client. Use one word only, no special characters except `-` and `_`. The default is `vpnclient` if not specified.

```
VPN_CLIENT_NAME=your_client_name
```

By default, clients are set to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN is active. You may specify custom DNS server(s) for all VPN modes. Example:

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

By default, no password is required when importing IKEv2 client configuration. You can choose to protect client config files using a random password.

```
VPN_PROTECT_CONFIG=yes
```

**Note:** The variables above have no effect for IKEv2 mode, if IKEv2 is already set up in the Docker container. In this case, you may remove IKEv2 and set it up again using custom options. Refer to [Configure and use IKEv2 VPN](#configure-and-use-ikev2-vpn).
</details>

### Start the IPsec VPN server

Create a new Docker container from this image (replace `./vpn.env` with your own `env` file):

```
docker run \
    --name ipsec-vpn-server \
    --env-file ./vpn.env \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v /lib/modules:/lib/modules:ro \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

In this command, we use the `-v` option of `docker run` to create a new [Docker volume](https://docs.docker.com/storage/volumes/) named `ikev2-vpn-data`, and mount it into `/etc/ipsec.d` in the container. IKEv2 related data such as certificates and keys will persist in the volume, and later when you need to re-create the Docker container, just specify the same volume again.

It is recommended to enable IKEv2 when using this image. However, if you prefer not to enable IKEv2 and use only the IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes to connect to the VPN, remove the first `-v` option from the `docker run` command above.

**Note:** Advanced users can also [run without privileged mode](docs/advanced-usage.md#run-without-privileged-mode).

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

The output will also include details for IKEv2 mode, if enabled.

(Optional) Backup the generated VPN login details (if any) to the current directory:

```
docker cp ipsec-vpn-server:/etc/ipsec.d/vpn-gen.env ./
```

## Next steps

*Read this in other languages: [English](README.md#next-steps), [中文](README-zh.md#下一步).*

Get your computer or device to use the VPN. Please refer to:

**[Configure and use IKEv2 VPN (recommended)](#configure-and-use-ikev2-vpn)**

**[Configure IPsec/L2TP VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md)**

**[Configure IPsec/XAuth ("Cisco IPsec") VPN Clients](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md)**

**[Download PDF versions of VPN docs (supporters)](https://ko-fi.com/post/PDF-versions-of-Setup-IPsec-VPN-docs-for-easy-shar-E1E4DO69I)**

Enjoy your very own VPN! :sparkles::tada::rocket::sparkles:

> Like this project? You can show your support or appreciation.
>
> <a href="https://ko-fi.com/hwdsl2" target="_blank"><img height="36" width="187" src="docs/images/kofi2.png" border="0" alt="Buy Me a Coffee at ko-fi.com" /></a> &nbsp;<a href="https://coindrop.to/hwdsl2" target="_blank"><img src="docs/images/embed-button.png" height="36" width="145" border="0" alt="Coindrop.to me" /></a>

## Important notes

**Windows users**: For IPsec/L2TP mode, a [one-time registry change](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#windows-error-809) is required if the VPN server or client is behind NAT (e.g. home router).

The same VPN account can be used by your multiple devices. However, due to an IPsec/L2TP limitation, if you wish to connect multiple devices from behind the same NAT (e.g. home router), you must use [IKEv2](#configure-and-use-ikev2-vpn) or [IPsec/XAuth](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md) mode.

If you wish to add, edit or remove VPN user accounts, first update your `env` file, then you must remove and re-create the Docker container using instructions from the [next section](#update-docker-image). Advanced users can [bind mount](docs/advanced-usage.md#bind-mount-the-env-file) the `env` file.

For servers with an external firewall (e.g. [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)/[GCE](https://cloud.google.com/vpc/docs/firewalls)), open UDP ports 500 and 4500 for the VPN. Aliyun users, see [#433](https://github.com/hwdsl2/setup-ipsec-vpn/issues/433).

Clients are set to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN is active. If another DNS provider is preferred, read [this section](docs/advanced-usage.md#use-alternative-dns-servers).

## Update Docker image

To update the Docker image and container, first [download](#download) the latest version:

```
docker pull hwdsl2/ipsec-vpn-server
```

If the Docker image is already up to date, you should see:

```
Status: Image is up to date for hwdsl2/ipsec-vpn-server:latest
```

Otherwise, it will download the latest version. To update your Docker container, first write down all your [VPN login details](#retrieve-vpn-login-details). Then remove the Docker container with `docker rm -f ipsec-vpn-server`. Finally, re-create it using instructions from [How to use this image](#how-to-use-this-image).

## Configure and use IKEv2 VPN

IKEv2 mode has improvements over IPsec/L2TP and IPsec/XAuth ("Cisco IPsec"), and does not require an IPsec PSK, username or password. Read more [here](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md).

First, check container logs to view details for IKEv2:

```bash
docker logs ipsec-vpn-server
```

**Note:** If you cannot find IKEv2 details, IKEv2 may not be enabled in the container. Try updating the Docker image and container using instructions from the [Update Docker image](#update-docker-image) section.

During IKEv2 setup, an IKEv2 client (with default name `vpnclient`) is created, with its configuration exported to `/etc/ipsec.d` **inside the container**. To copy config file(s) to the Docker host:

```bash
# Check contents of /etc/ipsec.d in the container
docker exec -it ipsec-vpn-server ls -l /etc/ipsec.d
# Example: Copy a client config file from the container
# to the current directory on the Docker host
docker cp ipsec-vpn-server:/etc/ipsec.d/vpnclient.p12 ./
```

**Next steps:** [Configure your devices](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md) to use the IKEv2 VPN.

<details>
<summary>
Learn how to manage IKEv2 clients.
</summary>

You can manage IKEv2 clients using the helper script. See examples below. To customize client options, run the script without arguments.

```bash
# Add a new client (using default options)
docker exec -it ipsec-vpn-server ikev2.sh --addclient [client name]
# Export configuration for an existing client
docker exec -it ipsec-vpn-server ikev2.sh --exportclient [client name]
# List existing clients
docker exec -it ipsec-vpn-server ikev2.sh --listclients
# Show usage
docker exec -it ipsec-vpn-server ikev2.sh -h
```

**Note:** If you encounter error "executable file not found", replace `ikev2.sh` above with `/opt/src/ikev2.sh`.
</details>
<details>
<summary>
Learn how to change the IKEv2 server address.
</summary>

In certain circumstances, you may need to change the IKEv2 server address. For example, to switch to use a DNS name, or after server IP changes. To change the IKEv2 server address, first [open a bash shell inside the container](docs/advanced-usage.md#bash-shell-inside-container), then [follow these instructions](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md#change-ikev2-server-address). Note that this will override the `VPN_DNS_NAME` variable you specified in the `env` file, and the container logs will no longer show up-to-date information for IKEv2.
</details>
<details>
<summary>
Remove IKEv2 and set it up again using custom options.
</summary>

In certain circumstances, you may need to remove IKEv2 and set it up again using custom options. This can be done using the helper script. Note that this will override variables you specified in the `env` file, such as `VPN_DNS_NAME` and `VPN_CLIENT_NAME`, and the container logs will no longer show up-to-date information for IKEv2.

**Warning:** All IKEv2 configuration including certificates and keys will be **permanently deleted**. This **cannot be undone**!

```bash
# Remove IKEv2 and delete all IKEv2 configuration
docker exec -it ipsec-vpn-server ikev2.sh --removeikev2
# Set up IKEv2 again using custom options
docker exec -it ipsec-vpn-server ikev2.sh
```
</details>

## Advanced usage

See [Advanced usage](docs/advanced-usage.md).

- [Use alternative DNS servers](docs/advanced-usage.md#use-alternative-dns-servers)
- [Run without privileged mode](docs/advanced-usage.md#run-without-privileged-mode)
- [Select VPN modes](docs/advanced-usage.md#select-vpn-modes)
- [Access other containers on the Docker host](docs/advanced-usage.md#access-other-containers-on-the-docker-host)
- [Specify VPN server's public IP](docs/advanced-usage.md#specify-vpn-servers-public-ip)
- [Assign static IPs to VPN clients](docs/advanced-usage.md#assign-static-ips-to-vpn-clients)
- [Customize VPN subnets](docs/advanced-usage.md#customize-vpn-subnets)
- [About host network mode](docs/advanced-usage.md#about-host-network-mode)
- [Enable Libreswan logs](docs/advanced-usage.md#enable-libreswan-logs)
- [Check server status](docs/advanced-usage.md#check-server-status)
- [Build from source code](docs/advanced-usage.md#build-from-source-code)
- [Bash shell inside container](docs/advanced-usage.md#bash-shell-inside-container)
- [Bind mount the env file](docs/advanced-usage.md#bind-mount-the-env-file)
- [Deploy Google BBR congestion control](docs/advanced-usage.md#deploy-google-bbr-congestion-control)

## Technical details

There are two services running: `Libreswan (pluto)` for the IPsec VPN, and `xl2tpd` for L2TP support.

The default IPsec configuration supports:

* IPsec/L2TP with PSK
* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IKEv2

The ports that are exposed for this container to work are:

* 4500/udp and 500/udp for IPsec

## License

**Note:** The software components inside the pre-built image (such as Libreswan and xl2tpd) are under the respective licenses chosen by their respective copyright holders. As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.

Copyright (C) 2016-2022 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
Based on [the work of Thomas Sarlandie](https://github.com/sarfata/voodooprivacy) (Copyright 2012)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
This work is licensed under the [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/)   
Attribution required: please include my name in any derivative and let me know how you have improved it!
