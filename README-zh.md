# Docker 上的 IPsec VPN 服务器

[![Build Status](https://img.shields.io/github/workflow/status/hwdsl2/docker-ipsec-vpn-server/buildx%20latest.svg?cacheSeconds=3600)](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions) [![GitHub Stars](https://img.shields.io/github/stars/hwdsl2/docker-ipsec-vpn-server.svg?cacheSeconds=86400)](https://github.com/hwdsl2/docker-ipsec-vpn-server/stargazers) [![Docker Stars](https://img.shields.io/docker/stars/hwdsl2/ipsec-vpn-server.svg?cacheSeconds=86400)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/) [![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/ipsec-vpn-server.svg?cacheSeconds=86400)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/)

使用这个 Docker 镜像快速搭建 IPsec VPN 服务器。支持 `IPsec/L2TP`，`Cisco IPsec` 和 `IKEv2` 协议。

本镜像以 Debian 10 (Buster) 为基础，并使用 [Libreswan](https://libreswan.org) (IPsec VPN 软件) 和 [xl2tpd](https://github.com/xelerance/xl2tpd) (L2TP 服务进程)。

[**&raquo; 另见： IPsec VPN 服务器一键安装脚本**](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh.md)

*其他语言版本: [English](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md), [简体中文](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md).*

#### 目录

- [快速开始](#快速开始)
- [安装 Docker](#安装-docker)
- [下载](#下载)
- [如何使用本镜像](#如何使用本镜像)
- [下一步](#下一步)
- [重要提示](#重要提示)
- [更新 Docker 镜像](#更新-docker-镜像)
- [高级用法](#高级用法)
- [技术细节](#技术细节)
- [另见](#另见)
- [授权协议](#授权协议)

## 快速开始

使用以下命令在 Docker 上快速搭建 IPsec VPN 服务器：

```
docker run \
    --name ipsec-vpn-server \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

你的 VPN 登录凭证将会被自动随机生成。请参见 [获取 VPN 登录信息](#获取-vpn-登录信息)。

如需了解更多有关如何使用本镜像的信息，请继续阅读以下部分。

## 安装 Docker

首先，在你的 Linux 服务器上 [安装并运行 Docker](https://docs.docker.com/engine/install/)。高级用户也可以使用 [Podman](https://podman.io) 来替代 Docker 运行本镜像，需要首先为 `docker` 命令 [创建一个别名](https://podman.io/whatis.html)。

**注：** 本镜像不支持 Docker for Mac 或者 Windows。

## 下载

预构建的可信任镜像可在 [Docker Hub registry](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/) 下载：

```
docker pull hwdsl2/ipsec-vpn-server
```

或者，你也可以从 [Quay.io](https://quay.io/repository/hwdsl2/ipsec-vpn-server) 下载这个镜像：

```
docker pull quay.io/hwdsl2/ipsec-vpn-server
docker image tag quay.io/hwdsl2/ipsec-vpn-server hwdsl2/ipsec-vpn-server
```

支持以下架构系统：`linux/amd64`, `linux/arm64` 和 `linux/arm/v7`。

高级用户可以自己从 GitHub [编译源代码](#从源代码构建)。

## 如何使用本镜像

### 环境变量

**注：** 所有这些环境变量对于本镜像都是可选的，也就是说无需定义它们就可以搭建 IPsec VPN 服务器。你可以运行 `touch vpn.env` 创建一个空的 `env` 文件，然后跳到下一节。

这个 Docker 镜像使用以下几个变量，可以在一个 `env` 文件中定义 （[示例](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/vpn.env.example)）：

```
VPN_IPSEC_PSK=your_ipsec_pre_shared_key
VPN_USER=your_vpn_username
VPN_PASSWORD=your_vpn_password
```

这将创建一个用于 VPN 登录的用户账户，它可以在你的多个设备上使用[*](#重要提示)。 IPsec PSK (预共享密钥) 由 `VPN_IPSEC_PSK` 环境变量指定。 VPN 用户名和密码分别在 `VPN_USER` 和 `VPN_PASSWORD` 中定义。

支持创建额外的 VPN 用户，如果需要，可以像下面这样在你的 `env` 文件中定义。用户名和密码必须分别使用空格进行分隔，并且用户名不能有重复。所有的 VPN 用户将共享同一个 IPsec PSK。

```
VPN_ADDL_USERS=additional_username_1 additional_username_2
VPN_ADDL_PASSWORDS=additional_password_1 additional_password_2
```

**注：** 在你的 `env` 文件中，**不要**为变量值添加 `""` 或者 `''`，或在 `=` 两边添加空格。**不要**在值中使用这些字符： `\ " '`。一个安全的 IPsec PSK 应该至少包含 20 个随机字符。

高级用户可以指定一个域名作为 VPN 服务器的地址。这是可选的。该域名必须是一个全称域名(FQDN)。示例如下：

```
VPN_DNS_NAME=vpn.example.com
```

### 运行 IPsec VPN 服务器

使用本镜像创建一个新的 Docker 容器 （将 `./vpn.env` 替换为你自己的 `env` 文件）：

```
docker run \
    --name ipsec-vpn-server \
    --env-file ./vpn.env \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

在该命令中，我们使用 `docker run` 的 `-v` 选项来创建一个名为 `ikev2-vpn-data` 的新 [Docker 卷](https://docs.docker.com/storage/volumes/)，并且将它挂载到容器内的 `/etc/ipsec.d` 目录下。IKEv2 的相关数据（比如证书和密钥）在该卷中保存，之后当你需要重新创建 Docker 容器的时候，只需指定同一个卷。

推荐在使用本镜像时启用 IKEv2。如果你不想启用 IKEv2 而仅使用 IPsec/L2TP 和 IPsec/XAuth ("Cisco IPsec") 模式连接到 VPN，可以去掉上面 `docker run` 命令中的 `-v` 选项。

**注：** 高级用户也可以 [不启用 privileged 模式运行](#不启用-privileged-模式运行)。

### 获取 VPN 登录信息

如果你在上述 `docker run` 命令中没有指定 `env` 文件，`VPN_USER` 会默认为 `vpnuser`，并且 `VPN_IPSEC_PSK` 和 `VPN_PASSWORD` 会被自动随机生成。要获取这些登录信息，可以查看容器的日志：

```
docker logs ipsec-vpn-server
```

在命令输出中查找这些行：

```
Connect to your new VPN with these details:

Server IP: 你的VPN服务器IP
IPsec PSK: 你的IPsec预共享密钥
Username: 你的VPN用户名
Password: 你的VPN密码
```

在命令输出中也会包含 IKEv2 配置信息（如果启用）。要开始使用 IKEv2，请参见 [配置并使用 IKEv2 VPN](#配置并使用-ikev2-vpn)。

（可选步骤）备份自动生成的 VPN 登录信息（如果有）到当前目录：

```
docker cp ipsec-vpn-server:/opt/src/vpn-gen.env ./
```

## 下一步

配置你的计算机或其它设备使用 VPN 。请参见：

**[配置 IPsec/L2TP VPN 客户端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md)**

**[配置 IPsec/XAuth ("Cisco IPsec") VPN 客户端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth-zh.md)**

**[高级用法：配置并使用 IKEv2 VPN](#配置并使用-ikev2-vpn)**

如果在连接过程中遇到错误，请参见 [故障排除](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#故障排除)。

开始使用自己的专属 VPN !

## 重要提示

*其他语言版本: [English](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md#important-notes), [简体中文](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md#重要提示).*

**Windows 用户** 在首次连接之前需要 [修改注册表](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#windows-错误-809)，以解决 VPN 服务器或客户端与 NAT（比如家用路由器）的兼容问题。

**Android 用户** 如果遇到连接问题，请尝试 [这些步骤](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#android-mtumss-问题)。

同一个 VPN 账户可以在你的多个设备上使用。但是由于 IPsec/L2TP 的局限性，如果需要同时连接在同一个 NAT（比如家用路由器）后面的多个设备到 VPN 服务器，你必须仅使用 [IPsec/XAuth 模式](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth-zh.md)，或者 [配置 IKEv2](#配置并使用-ikev2-vpn)。

如需添加，修改或者删除 VPN 用户账户，首先更新你的 `env` 文件，然后你必须按照 [下一节](#更新-docker-镜像) 的说明来删除并重新创建 Docker 容器。高级用户可以 [绑定挂载](#绑定挂载-env-文件) `env` 文件。

对于有外部防火墙的服务器（比如 [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)/[GCE](https://cloud.google.com/vpc/docs/firewalls)），请为 VPN 打开 UDP 端口 500 和 4500。阿里云用户请参见 [#433](https://github.com/hwdsl2/setup-ipsec-vpn/issues/433)。

在 VPN 已连接时，客户端配置为使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。如果偏好其它的域名解析服务，请看 [这里](#使用其他的-dns-服务器)。

## 更新 Docker 镜像

如需更新你的 Docker 镜像和容器，首先 [下载](#下载) 最新版本：

```
docker pull hwdsl2/ipsec-vpn-server
```

如果 Docker 镜像已经是最新的，你会看到提示：

```
Status: Image is up to date for hwdsl2/ipsec-vpn-server:latest
```

否则，将会下载最新版本。要更新你的 Docker 容器，首先在纸上记下你所有的 [VPN 登录信息](#获取-vpn-登录信息)。然后删除 Docker 容器： `docker rm -f ipsec-vpn-server`。最后按照 [如何使用本镜像](#如何使用本镜像) 的说明来重新创建它。

## 高级用法

*其他语言版本: [English](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md#advanced-usage), [简体中文](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md#高级用法).*

- [使用其他的 DNS 服务器](#使用其他的-dns-服务器)
- [不启用 privileged 模式运行](#不启用-privileged-模式运行)
- [关于 host network 模式](#关于-host-network-模式)
- [配置并使用 IKEv2 VPN](#配置并使用-ikev2-vpn)
- [启用 Libreswan 日志](#启用-libreswan-日志)
- [查看服务器状态](#查看服务器状态)
- [从源代码构建](#从源代码构建)
- [在容器中运行 Bash shell](#在容器中运行-bash-shell)
- [绑定挂载 env 文件](#绑定挂载-env-文件)

### 使用其他的 DNS 服务器

在 VPN 已连接时，客户端配置为使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。如果偏好其它的域名解析服务，你可以在 `env` 文件中定义 `VPN_DNS_SRV1` 和 `VPN_DNS_SRV2`（可选），然后按照上面的说明重新创建 Docker 容器。比如你想使用 [Cloudflare 的 DNS 服务](https://1.1.1.1)：

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

### 不启用 privileged 模式运行

高级用户可以在不启用 [privileged 模式](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) 的情况下使用本镜像创建一个 Docker 容器 （将 `./vpn.env` 替换为你自己的 `env` 文件）：

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

在不启用 privileged 模式运行时，容器不能更改 `sysctl` 设置。这可能会影响本镜像的某些功能。一个已知问题是 [Android MTU/MSS fix](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#android-mtumss-问题) 需要另外在 `docker run` 命令添加 `--sysctl net.ipv4.ip_no_pmtu_disc=1` 才有效。如果你遇到任何问题，可以尝试换用 [privileged 模式](#运行-ipsec-vpn-服务器) 重新创建容器。

在创建 Docker 容器之后，请转到 [获取 VPN 登录信息](#获取-vpn-登录信息)。

类似地，如果你使用 [Docker compose](https://docs.docker.com/compose/)，可以将 [docker-compose.yml](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docker-compose.yml) 中的 `privileged: true` 替换为：

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

更多信息请参见 [compose file reference](https://docs.docker.com/compose/compose-file/)。

### 关于 host network 模式

高级用户可以使用 [host network 模式](https://docs.docker.com/network/host/) 运行本镜像，通过为 `docker run` 命令添加 `--network=host` 参数来实现。另外，如果 [不启用 privileged 模式运行](#不启用-privileged-模式运行)，你可能还需要将 `eth0` 替换为你的 Docker 主机的网络接口名称。

在非必要的情况下，**不推荐**使用 host network 模式运行本镜像。在该模式下，容器的网络栈未与 Docker 主机隔离，从而在使用 IPsec/L2TP 模式连接之后，VPN 客户端可以使用 Docker 主机的 VPN 内网 IP `192.168.42.1` 访问主机上的端口或服务。请注意，当你不再使用本镜像时，你需要手动清理 [run.sh](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/run.sh) 所更改的 IPTables 规则和 sysctl 设置，或者重启服务器。

某些 Docker 主机操作系统，比如 Debian 10，不能使用 host network 模式运行本镜像，因为它们使用 nftables。

### 配置并使用 IKEv2 VPN

*其他语言版本: [English](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md#configure-and-use-ikev2-vpn), [简体中文](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md#配置并使用-ikev2-vpn).*

使用这个 Docker 镜像，高级用户可以配置并使用 IKEv2。它是比 IPsec/L2TP 和 IPsec/XAuth ("Cisco IPsec") 更佳的连接模式，该模式无需 IPsec PSK, 用户名或密码。更多信息请看[这里](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md)。

首先，查看容器的日志以获取 IKEv2 配置信息：

```bash
docker logs ipsec-vpn-server
```

**注：** 如果你无法找到 IKEv2 配置信息，IKEv2 可能没有在容器中启用。尝试按照 [更新 Docker 镜像](#更新-docker-镜像) 一节的说明更新 Docker 镜像和容器。

在 IKEv2 安装过程中会创建一个新的名称为 `vpnclient` 的 IKEv2 客户端，并且导出它的配置到 **容器内** 的 `/etc/ipsec.d` 目录下。如果要将客户端配置文件从容器复制到 Docker 主机当前目录：

```bash
# 查看容器内的 /etc/ipsec.d 目录的文件
docker exec -it ipsec-vpn-server ls -l /etc/ipsec.d
# 示例：将一个客户端配置文件从容器复制到 Docker 主机
docker cp ipsec-vpn-server:/etc/ipsec.d/vpnclient.p12 ./
```

然后你可以使用上面获取的 IKEv2 配置信息来 [配置 IKEv2 VPN 客户端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md#配置-ikev2-vpn-客户端)。

要管理 IKEv2 客户端，你可以使用 [辅助脚本](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md#使用辅助脚本)。示例如下。如果需要自定义客户端选项，可以在不添加参数的情况下运行脚本。

```bash
# 添加一个客户端（使用默认选项）
docker exec -it ipsec-vpn-server bash /opt/src/ikev2.sh --addclient [client name]
# 导出一个已有的客户端的配置
docker exec -it ipsec-vpn-server bash /opt/src/ikev2.sh --exportclient [client name]
# 列出已有的客户端的名称
docker exec -it ipsec-vpn-server bash /opt/src/ikev2.sh --listclients
```

### 启用 Libreswan 日志

为了保持较小的 Docker 镜像，Libreswan (IPsec) 日志默认未开启。如果你需要启用它以进行故障排除，首先在正在运行的 Docker 容器中开始一个 Bash 会话：

```
docker exec -it ipsec-vpn-server env TERM=xterm bash -l
```

然后运行以下命令：

```
apt-get update && apt-get -y install rsyslog
service rsyslog restart
service ipsec restart
sed -i '/pluto\.pid/a service rsyslog restart' /opt/src/run.sh
exit
```

完成后你可以这样查看 Libreswan 日志：

```
docker exec -it ipsec-vpn-server grep pluto /var/log/auth.log
```

如需查看 xl2tpd 日志，请运行 `docker logs ipsec-vpn-server`。

### 查看服务器状态

如需查看你的 IPsec VPN 服务器状态，可以在容器中运行 `ipsec status` 命令：

```
docker exec -it ipsec-vpn-server ipsec status
```

或者查看当前已建立的 VPN 连接：

```
docker exec -it ipsec-vpn-server ipsec whack --trafficstatus
```

### 从源代码构建

高级用户可以从 GitHub 下载并自行编译源代码：

```
git clone https://github.com/hwdsl2/docker-ipsec-vpn-server.git
cd docker-ipsec-vpn-server
docker build -t hwdsl2/ipsec-vpn-server .
```

若不需要改动源码，也可以这样：

```
docker build -t hwdsl2/ipsec-vpn-server github.com/hwdsl2/docker-ipsec-vpn-server.git
```

### 在容器中运行 Bash shell

在正在运行的 Docker 容器中开始一个 Bash 会话：

```
docker exec -it ipsec-vpn-server env TERM=xterm bash -l
```

（可选步骤） 安装 `nano` 编辑器：

```
apt-get update && apt-get -y install nano
```

然后在容器中运行你的命令。完成后退出并重启 Docker 容器 （如果需要）：

```
exit
docker restart ipsec-vpn-server
```

### 绑定挂载 env 文件

作为 `--env-file` 选项的替代方案，高级用户可以绑定挂载 `env` 文件。该方法的好处是你在更新 `env` 文件之后可以重启 Docker 容器以生效，而不需要重新创建它。要使用这个方法，你必须首先编辑你的 `env` 文件并将所有的变量值用单引号 `''` 括起来。然后（重新）创建 Docker 容器（将第一个 `vpn.env` 替换为你自己的 `env` 文件）：

```
docker run \
    --name ipsec-vpn-server \
    --restart=always \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -v "$(pwd)/vpn.env:/opt/src/vpn.env:ro" \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

## 技术细节

需要运行以下两个服务：`Libreswan (pluto)` 提供 IPsec VPN，`xl2tpd` 提供 L2TP 支持。

默认的 IPsec 配置支持以下协议：

* IPsec/L2TP with PSK
* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IKEv2

为使 VPN 服务器正常工作，将会打开以下端口：

* 4500/udp and 500/udp for IPsec

## 另见

* [IPsec VPN Server on Ubuntu, Debian and CentOS](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh.md)

## 授权协议

版权所有 (C) 2016-2021 [Lin Song](https://www.linkedin.com/in/linsongui) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
基于 [Thomas Sarlandie 的工作](https://github.com/sarfata/voodooprivacy) (版权所有 2012)

<a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/3.0/88x31.png" /></a>   
这个项目是以 [知识共享署名-相同方式共享3.0](http://creativecommons.org/licenses/by-sa/3.0/) 许可协议授权。   
必须署名： 请包括我的名字在任何衍生产品，并且让我知道你是如何改善它的！
