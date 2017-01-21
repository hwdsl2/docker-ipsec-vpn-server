# Docker 上的 IPsec VPN 服务器

[![Build Status](https://travis-ci.org/hwdsl2/docker-ipsec-vpn-server.svg?branch=master)](https://travis-ci.org/hwdsl2/docker-ipsec-vpn-server) [![GitHub Stars](https://img.shields.io/github/stars/hwdsl2/docker-ipsec-vpn-server.svg?maxAge=86400)](https://github.com/hwdsl2/docker-ipsec-vpn-server/stargazers) [![Docker Stars](https://img.shields.io/docker/stars/hwdsl2/ipsec-vpn-server.svg?maxAge=86400)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server) [![Docker Pulls](https://img.shields.io/docker/pulls/hwdsl2/ipsec-vpn-server.svg?maxAge=86400)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server)

使用这个 Docker 镜像快速搭建 IPsec VPN 服务器。支持 `IPsec/L2TP` 和 `IPsec/XAuth ("Cisco IPsec")` 协议。

本镜像以 Debian Jessie 为基础，并使用 [Libreswan](https://libreswan.org) (IPsec VPN 软件) 和 [xl2tpd](https://github.com/xelerance/xl2tpd) (L2TP 服务进程)。

[**&raquo; 另见： IPsec VPN Server on Ubuntu, Debian and CentOS**](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh.md)

*其他语言版本: [English](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md), [简体中文](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md).*

## 安装 Docker

参照 [这些步骤](https://docs.docker.com/engine/installation/linux/) 在你的 Linux 服务器上安装并运行 Docker。

## 下载

预构建的可信任镜像可在 [Docker Hub registry](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server) 下载：

```
docker pull hwdsl2/ipsec-vpn-server
```

或者，你也可以自己从 GitHub [编译源代码](#从源代码构建)。

## 如何使用本镜像

### 环境变量

这个 Docker 镜像使用以下三个环境变量，可以在一个 `env` 文件中定义：

```
VPN_IPSEC_PSK=<IPsec pre-shared key>
VPN_USER=<VPN Username>
VPN_PASSWORD=<VPN Password>
```

这将创建一个用于 VPN 登录的用户账户。 IPsec PSK (预共享密钥) 由 `VPN_IPSEC_PSK` 环境变量指定。 VPN 用户名和密码分别在 `VPN_USER` 和 `VPN_PASSWORD` 中定义。

**注：** 在你的 `env` 文件中，**不要**为变量值添加单引号/双引号，或在 `=` 两边添加空格。**不要**在值中使用这些字符： `\ " '`。

所有这些环境变量对于本镜像都是可选的，也就是说无需定义它们就可以搭建 IPsec VPN 服务器。详情请参见以下部分。

### 运行 IPsec VPN 服务器

**重要：** 首先在 Docker 主机上加载 IPsec `NETKEY` 内核模块：

```
sudo modprobe af_key
```

使用本镜像创建一个新的 Docker 容器 （将 `./vpn.env` 替换为你自己的 `env` 文件）：

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

### 获取 VPN 登录信息

如果你在上述 `docker run` 命令中没有指定 `env` 文件，`VPN_USER` 会默认为 `vpnuser`，并且 `VPN_IPSEC_PSK` 和 `VPN_PASSWORD` 会被自动随机生成。要获取这些登录信息，可以查看容器的日志：

```
docker logs ipsec-vpn-server
```

在命令输出中查找这些行：

```
Connect to your new VPN with these details:

Server IP: <VPN Server IP>
IPsec PSK: <IPsec pre-shared key>
Username: <VPN Username>
Password: <VPN Password>
```

（可选步骤） 备份自动生成的 VPN 登录信息（如果有）到当前目录：

```
docker cp ipsec-vpn-server:/opt/src/vpn-gen.env ./
```

### 查看服务器状态

如需查看你的 IPsec VPN 服务器状态，可以在容器中运行 `ipsec status` 命令：

```
docker exec -it ipsec-vpn-server ipsec status
```

## 下一步

配置你的计算机或其它设备使用 VPN 。请参见：

[配置 IPsec/L2TP VPN 客户端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md)   
[配置 IPsec/XAuth ("Cisco IPsec") VPN 客户端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth-zh.md)

如果在连接过程中遇到错误，请参见 [故障排除](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#故障排除)。

开始使用自己的专属 VPN !

## 重要提示

*其他语言版本: [English](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md#important-notes), [简体中文](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md#重要提示).*

**Windows 用户** 在首次连接之前需要[修改一次注册表](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#windows-错误-809)，以解决 VPN 服务器 和/或 客户端与 NAT （比如家用路由器）的兼容问题。

同一个 VPN 账户可以在你的多个设备上使用。但是由于 IPsec/L2TP 的局限性，如果你需要同时连接在同一个 NAT 后面（比如家用路由器）的多个设备到 VPN 服务器，你必须仅使用 [IPsec/XAuth 模式](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth-zh.md)。

对于有外部防火墙的服务器（比如 [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html)/[GCE](https://cloud.google.com/compute/docs/networking#firewalls)），请为 VPN 打开 UDP 端口 500 和 4500。

在编辑任何 VPN 配置文件之前，你必须首先在正在运行的 Docker 容器中 [开始一个 Bash 会话](#在容器中运行-bash-shell)。

如果需要添加，修改或者删除 VPN 用户账户，请参见 [管理 VPN 用户](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/manage-users-zh.md)。完成后重启你的 Docker 容器。

在 VPN 已连接时，客户端配置为使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。如果偏好其它的域名解析服务，请编辑 `/etc/ppp/options.xl2tpd` 和 `/etc/ipsec.conf` 并替换 `8.8.8.8` 和 `8.8.4.4`。然后重启你的 Docker 容器。

在使用 `IPsec/L2TP` 连接时，VPN 服务器在虚拟网络 `192.168.42.0/24` 内具有 IP `192.168.42.1`。

## 高级用法

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

完成后退出并重启 Docker 容器 （如果需要）：

```
exit
docker restart ipsec-vpn-server
```

## 技术细节

需要运行以下两个服务： `Libreswan (pluto)` 提供 IPsec VPN， `xl2tpd` 提供 L2TP 支持。

默认的 IPsec 配置支持以下协议：

* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IPsec/L2TP with PSK

为使 VPN 服务器正常工作，将会打开以下端口：

* 4500/udp and 500/udp for IPsec

## 另见

* [IPsec VPN Server on Ubuntu, Debian and CentOS](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh.md)
* [IKEv2 VPN Server on Docker](https://github.com/gaomd/docker-ikev2-vpn-server)

## 授权协议

版权所有 (C) 2016-2017 [Lin Song](https://www.linkedin.com/in/linsongui) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
基于 [Thomas Sarlandie 的工作](https://github.com/sarfata/voodooprivacy) (Copyright 2012) (版权所有 2012)

这个项目是以 [知识共享署名-相同方式共享3.0](http://creativecommons.org/licenses/by-sa/3.0/) 许可协议授权。   
必须署名： 请包括我的名字在任何衍生产品，并且让我知道你是如何改善它的！
