[English](README.md) | [中文](README-zh.md)

# Docker 上的 IPsec VPN 服务器

[![Build Status](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml/badge.svg)](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml) [![GitHub Stars](docs/images/badges/github-stars.svg)](https://github.com/hwdsl2/docker-ipsec-vpn-server/stargazers) [![Docker Stars](docs/images/badges/docker-stars.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/) [![Docker Pulls](docs/images/badges/docker-pulls.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/)

使用这个 Docker 镜像快速搭建 IPsec VPN 服务器。支持 IPsec/L2TP，Cisco IPsec 和 IKEv2 协议。

本镜像以 Alpine 3.15 或 Debian 11 为基础，并使用 [Libreswan](https://libreswan.org) (IPsec VPN 软件) 和 [xl2tpd](https://github.com/xelerance/xl2tpd) (L2TP 服务进程)。

IPsec VPN 可以加密你的网络流量，以防止在通过因特网传送时，你和 VPN 服务器之间的任何人对你的数据的未经授权的访问。在使用不安全的网络时，这是特别有用的，例如在咖啡厅，机场或旅馆房间。

[**&raquo; 另见：IPsec VPN 服务器一键安装脚本**](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh.md)

## 快速开始

使用以下命令在 Docker 上快速搭建 IPsec VPN 服务器：

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

你的 VPN 登录凭证将会被自动随机生成。请参见 [获取 VPN 登录信息](#获取-vpn-登录信息)。

要了解更多有关如何使用本镜像的信息，请继续阅读以下部分。

## 功能特性

- 支持具有强大和快速加密算法（例如 AES-GCM）的 IKEv2 模式
- 生成 VPN 配置文件以自动配置 iOS, macOS 和 Android 设备
- 支持 Windows, macOS, iOS, Android 和 Linux 作为 VPN 客户端
- 包括辅助脚本以管理 IKEv2 用户和证书

## 安装 Docker

首先在你的 Linux 服务器上 [安装 Docker](https://docs.docker.com/engine/install/)。另外你也可以使用 [Podman](https://podman.io) 运行本镜像，需要首先为 `docker` 命令 [创建一个别名](https://podman.io/whatis.html)。

高级用户可以在 macOS 上通过安装 [Docker for Mac](https://docs.docker.com/docker-for-mac/) 使用本镜像。在使用 IPsec/L2TP 模式之前，你可能需要运行 `docker restart ipsec-vpn-server` 重启一次 Docker 容器。本镜像不支持 Docker for Windows。

## 下载

预构建的可信任镜像可在 [Docker Hub registry](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/) 下载：

```
docker pull hwdsl2/ipsec-vpn-server
```

或者，你也可以从 [Quay.io](https://quay.io/repository/hwdsl2/ipsec-vpn-server) 下载：

```
docker pull quay.io/hwdsl2/ipsec-vpn-server
docker image tag quay.io/hwdsl2/ipsec-vpn-server hwdsl2/ipsec-vpn-server
```

支持以下架构系统：`linux/amd64`, `linux/arm64` 和 `linux/arm/v7`。

高级用户可以自己从 GitHub [编译源代码](docs/advanced-usage-zh.md#从源代码构建)。

### 镜像对照表

有两个预构建的镜像可用。默认的基于 Alpine 的镜像大小仅 ~18MB。

|                 | 基于 Alpine               | 基于 Debian                     |
| --------------- | ------------------------ | ------------------------------ |
| 镜像名称          | hwdsl2/ipsec-vpn-server  | hwdsl2/ipsec-vpn-server:debian |
| 压缩后大小        | ~ 18 MB                  | ~ 62 MB                        |
| 基础镜像          | Alpine Linux 3.15        | Debian Linux 11                |
| 系统架构          | amd64, arm64, arm/v7     | amd64, arm64, arm/v7           |
| Libreswan 版本   | 4.7                      | 4.7                            |
| IPsec/L2TP      | ✅                       | ✅                              |
| Cisco IPsec     | ✅                       | ✅                              |
| IKEv2           | ✅                       | ✅                              |

**注：** 要使用基于 Debian 的镜像，请将本自述文件中所有的 `hwdsl2/ipsec-vpn-server` 替换为 `hwdsl2/ipsec-vpn-server:debian`。

## 如何使用本镜像

### 环境变量

**注：** 所有这些变量对于本镜像都是可选的，也就是说无需定义它们就可以搭建 IPsec VPN 服务器。你可以运行 `touch vpn.env` 创建一个空的 `env` 文件，然后跳到下一节。

这个 Docker 镜像使用以下几个变量，可以在一个 `env` 文件中定义（参见[示例](vpn.env.example)）：

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

<details>
<summary>
:information_source: 你可以指定一个域名，客户端名称和/或另外的 DNS 服务器。这是可选的。:information_source:
</summary>

高级用户可以指定一个域名作为 IKEv2 服务器地址。这是可选的。该域名必须是一个全称域名 (FQDN)。示例如下：

```
VPN_DNS_NAME=vpn.example.com
```

你可以指定第一个 IKEv2 客户端的名称。该名称不能包含空格或者除 `-` `_` 之外的任何特殊字符。如果未指定，则使用默认值 `vpnclient`。

```
VPN_CLIENT_NAME=your_client_name
```

在 VPN 已连接时，客户端默认配置为使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。你可以为所有的 VPN 模式指定另外的 DNS 服务器。示例如下：

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

默认情况下，导入 IKEv2 客户端配置时不需要密码。你可以选择使用随机密码保护客户端配置文件。

```
VPN_PROTECT_CONFIG=yes
```

**注：** 如果在 Docker 容器中已经配置了 IKEv2，则以上变量对 IKEv2 模式无效。在这种情况下，你可以移除 IKEv2 并使用自定义选项重新配置它。参见 [配置并使用 IKEv2 VPN](#配置并使用-ikev2-vpn)。
</details>

### 运行 IPsec VPN 服务器

使用本镜像创建一个新的 Docker 容器 （将 `./vpn.env` 替换为你自己的 `env` 文件）：

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

在该命令中，我们使用 `docker run` 的 `-v` 选项来创建一个名为 `ikev2-vpn-data` 的新 [Docker 卷](https://docs.docker.com/storage/volumes/)，并且将它挂载到容器内的 `/etc/ipsec.d` 目录下。IKEv2 的相关数据（比如证书和密钥）在该卷中保存，之后当你需要重新创建 Docker 容器的时候，只需指定同一个卷。

推荐在使用本镜像时启用 IKEv2。如果你不想启用 IKEv2 而仅使用 IPsec/L2TP 和 IPsec/XAuth ("Cisco IPsec") 模式连接到 VPN，可以去掉上面 `docker run` 命令中的第一个 `-v` 选项。

**注：** 高级用户也可以 [不启用 privileged 模式运行](docs/advanced-usage-zh.md#不启用-privileged-模式运行)。

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
docker cp ipsec-vpn-server:/etc/ipsec.d/vpn-gen.env ./
```

## 下一步

*其他语言版本: [English](README.md#next-steps), [中文](README-zh.md#下一步)。*

配置你的计算机或其它设备使用 VPN。请参见：

**[配置并使用 IKEv2 VPN（推荐）](#配置并使用-ikev2-vpn)**

**[配置 IPsec/L2TP VPN 客户端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md)**

**[配置 IPsec/XAuth ("Cisco IPsec") VPN 客户端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth-zh.md)**

如果在连接过程中遇到错误，请参见 [故障排除](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#故障排除)。

开始使用自己的专属 VPN! :sparkles::tada::rocket::sparkles:

如果你喜欢这个项目，可以 [表达你的支持或感谢](https://coindrop.to/hwdsl2)。

## 重要提示

*其他语言版本: [English](README.md#important-notes), [中文](README-zh.md#重要提示)。*

**Windows 用户** 对于 IPsec/L2TP 模式，在首次连接之前需要 [修改注册表](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#windows-错误-809)，以解决 VPN 服务器或客户端与 NAT（比如家用路由器）的兼容问题。

同一个 VPN 账户可以在你的多个设备上使用。但是由于 IPsec/L2TP 的局限性，如果需要连接在同一个 NAT（比如家用路由器）后面的多个设备，你必须使用 [IKEv2](#配置并使用-ikev2-vpn) 或者 [IPsec/XAuth](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth-zh.md) 模式。

如需添加，修改或者删除 VPN 用户账户，首先更新你的 `env` 文件，然后你必须按照 [下一节](#更新-docker-镜像) 的说明来删除并重新创建 Docker 容器。高级用户可以 [绑定挂载](docs/advanced-usage-zh.md#绑定挂载-env-文件) `env` 文件。

对于有外部防火墙的服务器（比如 [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)/[GCE](https://cloud.google.com/vpc/docs/firewalls)），请为 VPN 打开 UDP 端口 500 和 4500。阿里云用户请参见 [#433](https://github.com/hwdsl2/setup-ipsec-vpn/issues/433)。

在 VPN 已连接时，客户端配置为使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。如果偏好其它的域名解析服务，请看 [这里](docs/advanced-usage-zh.md#使用其他的-dns-服务器)。

## 更新 Docker 镜像

要更新 Docker 镜像和容器，首先 [下载](#下载) 最新版本：

```
docker pull hwdsl2/ipsec-vpn-server
```

如果 Docker 镜像已经是最新的，你会看到提示：

```
Status: Image is up to date for hwdsl2/ipsec-vpn-server:latest
```

否则将会下载最新版本。要更新你的 Docker 容器，首先在纸上记下你所有的 [VPN 登录信息](#获取-vpn-登录信息)。然后删除 Docker 容器： `docker rm -f ipsec-vpn-server`。最后按照 [如何使用本镜像](#如何使用本镜像) 的说明来重新创建它。

## 配置并使用 IKEv2 VPN

*其他语言版本: [English](README.md#configure-and-use-ikev2-vpn), [中文](README-zh.md#配置并使用-ikev2-vpn)。*

IKEv2 模式是比 IPsec/L2TP 和 IPsec/XAuth ("Cisco IPsec") 更佳的连接模式，该模式无需 IPsec PSK, 用户名或密码。更多信息请看[这里](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md)。

首先，查看容器的日志以获取 IKEv2 配置信息：

```bash
docker logs ipsec-vpn-server
```

**注：** 如果你无法找到 IKEv2 配置信息，IKEv2 可能没有在容器中启用。尝试按照 [更新 Docker 镜像](#更新-docker-镜像) 一节的说明更新 Docker 镜像和容器。

在 IKEv2 安装过程中会创建一个 IKEv2 客户端（默认名称为 `vpnclient`），并且导出它的配置到 **容器内** 的 `/etc/ipsec.d` 目录下。你可以将配置文件复制到 Docker 主机：

```bash
# 查看容器内的 /etc/ipsec.d 目录的文件
docker exec -it ipsec-vpn-server ls -l /etc/ipsec.d
# 示例：将一个客户端配置文件从容器复制到 Docker 主机当前目录
docker cp ipsec-vpn-server:/etc/ipsec.d/vpnclient.p12 ./
```

**下一步：** [配置你的设备](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md) 以使用 IKEv2 VPN。

<details>
<summary>
了解如何管理 IKEv2 客户端。
</summary>

你可以使用辅助脚本管理 IKEv2 客户端。示例如下。如需自定义客户端选项，可以在不添加参数的情况下运行脚本。

```bash
# 添加一个客户端（使用默认选项）
docker exec -it ipsec-vpn-server ikev2.sh --addclient [client name]
# 导出一个已有的客户端的配置
docker exec -it ipsec-vpn-server ikev2.sh --exportclient [client name]
# 列出已有的客户端
docker exec -it ipsec-vpn-server ikev2.sh --listclients
# 显示使用信息
docker exec -it ipsec-vpn-server ikev2.sh -h
```

**注：** 如果你遇到错误 "executable file not found"，将上面的 `ikev2.sh` 换成 `/opt/src/ikev2.sh`。
</details>
<details>
<summary>
了解如何更改 IKEv2 服务器地址。
</summary>

在某些情况下，你可能需要更改 IKEv2 服务器地址。例如切换为使用域名，或者在服务器的 IP 更改之后。要更改 IKEv2 服务器地址，首先[在容器中运行 Bash shell](docs/advanced-usage-zh.md#在容器中运行-bash-shell)，然后[按照这里的说明操作](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md#更改-ikev2-服务器地址)。请注意，这将覆盖你在 `env` 文件中指定的 `VPN_DNS_NAME` 变量，并且容器的日志将不再显示 IKEv2 的最新信息。
</details>
<details>
<summary>
移除 IKEv2 并使用自定义选项重新配置。
</summary>

在某些情况下，你可能需要移除 IKEv2 并使用自定义选项重新配置它。这可以使用辅助脚本来完成。请注意，这将覆盖你在 `env` 文件中指定的变量，例如 `VPN_DNS_NAME` 和 `VPN_CLIENT_NAME`，并且容器的日志将不再显示 IKEv2 的最新信息。

**警告：** 这将**永久删除**所有的 IKEv2 配置（包括证书和密钥），并且**不可撤销**！

```bash
# 移除 IKEv2 并删除所有的 IKEv2 配置
docker exec -it ipsec-vpn-server ikev2.sh --removeikev2
# 使用自定义选项重新配置 IKEv2
docker exec -it ipsec-vpn-server ikev2.sh
```
</details>

## 高级用法

请参见 [高级用法](docs/advanced-usage-zh.md)。

- [使用其他的 DNS 服务器](docs/advanced-usage-zh.md#使用其他的-dns-服务器)
- [不启用 privileged 模式运行](docs/advanced-usage-zh.md#不启用-privileged-模式运行)
- [选择 VPN 模式](docs/advanced-usage-zh.md#选择-vpn-模式)
- [访问 Docker 主机上的其它容器](docs/advanced-usage-zh.md#访问-docker-主机上的其它容器)
- [指定 VPN 服务器的公有 IP](docs/advanced-usage-zh.md#指定-vpn-服务器的公有-ip)
- [为 VPN 客户端指定静态 IP](docs/advanced-usage-zh.md#为-vpn-客户端指定静态-ip)
- [自定义 VPN 子网](docs/advanced-usage-zh.md#自定义-vpn-子网)
- [关于 host network 模式](docs/advanced-usage-zh.md#关于-host-network-模式)
- [启用 Libreswan 日志](docs/advanced-usage-zh.md#启用-libreswan-日志)
- [查看服务器状态](docs/advanced-usage-zh.md#查看服务器状态)
- [从源代码构建](docs/advanced-usage-zh.md#从源代码构建)
- [在容器中运行 Bash shell](docs/advanced-usage-zh.md#在容器中运行-bash-shell)
- [绑定挂载 env 文件](docs/advanced-usage-zh.md#绑定挂载-env-文件)

## 技术细节

需要运行以下两个服务：`Libreswan (pluto)` 提供 IPsec VPN，`xl2tpd` 提供 L2TP 支持。

默认的 IPsec 配置支持以下协议：

* IPsec/L2TP with PSK
* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IKEv2

为使 VPN 服务器正常工作，将会打开以下端口：

* 4500/udp and 500/udp for IPsec

## 授权协议

**注：** 预构建镜像中的软件组件（例如 Libreswan 和 xl2tpd）在其各自版权所有者选择的相应许可下。对于任何预构建的镜像的使用，用户有责任确保对该镜像的任何使用符合其中包含的所有软件的任何相关许可。

版权所有 (C) 2016-2022 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
基于 [Thomas Sarlandie 的工作](https://github.com/sarfata/voodooprivacy) (版权所有 2012)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
这个项目是以 [知识共享署名-相同方式共享3.0](http://creativecommons.org/licenses/by-sa/3.0/) 许可协议授权。   
必须署名： 请包括我的名字在任何衍生产品，并且让我知道你是如何改善它的！
