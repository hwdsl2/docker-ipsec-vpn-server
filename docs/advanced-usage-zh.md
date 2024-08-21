[English](advanced-usage.md) | [中文](advanced-usage-zh.md)

# 高级用法

- [使用其他的 DNS 服务器](#使用其他的-dns-服务器)
- [不启用 privileged 模式运行](#不启用-privileged-模式运行)
- [选择 VPN 模式](#选择-vpn-模式)
- [访问 Docker 主机上的其它容器](#访问-docker-主机上的其它容器)
- [指定 VPN 服务器的公有 IP](#指定-vpn-服务器的公有-ip)
- [为 VPN 客户端指定静态 IP](#为-vpn-客户端指定静态-ip)
- [自定义 VPN 子网](#自定义-vpn-子网)
- [VPN 分流](#vpn-分流)
- [关于 host network 模式](#关于-host-network-模式)
- [启用 Libreswan 日志](#启用-libreswan-日志)
- [查看服务器状态](#查看服务器状态)
- [从源代码构建](#从源代码构建)
- [在容器中运行 Bash shell](#在容器中运行-bash-shell)
- [绑定挂载 env 文件](#绑定挂载-env-文件)
- [部署 Google BBR 拥塞控制](#部署-google-bbr-拥塞控制)

## 使用其他的 DNS 服务器

在 VPN 已连接时，客户端默认配置为使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。如果偏好其它的域名解析服务，你可以在 `env` 文件中定义 `VPN_DNS_SRV1` 和 `VPN_DNS_SRV2`（可选），然后按照[说明](../README-zh.md#更新-docker-镜像)重新创建 Docker 容器。示例如下：

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

使用 `VPN_DNS_SRV1` 指定主 DNS 服务器，使用 `VPN_DNS_SRV2` 指定辅助 DNS 服务器（可选）。

请注意，如果 Docker 容器中已经配置了 IKEv2，你还需要编辑 Docker 容器内的 `/etc/ipsec.d/ikev2.conf` 并将 `8.8.8.8` 和 `8.8.4.4` 替换为你的其他的 DNS 服务器，然后重新启动 Docker 容器。

以下是一些流行的公共 DNS 提供商的列表，供你参考。

| 提供商 | 主 DNS | 辅助 DNS | 注释 |
| ----- | ------ | ------- | ---- |
| [Google Public DNS](https://developers.google.com/speed/public-dns) | 8.8.8.8 | 8.8.4.4 | 本项目默认 |
| [Cloudflare](https://1.1.1.1/dns/) | 1.1.1.1 | 1.0.0.1 | 另见：[Cloudflare for families](https://1.1.1.1/family/) |
| [Quad9](https://www.quad9.net) | 9.9.9.9 | 149.112.112.112 | 阻止恶意域 |
| [OpenDNS](https://www.opendns.com/home-internet-security/) | 208.67.222.222 | 208.67.220.220 | 阻止网络钓鱼域，可配置。 |
| [CleanBrowsing](https://cleanbrowsing.org/filters/) | 185.228.168.9 | 185.228.169.9 | [域过滤器](https://cleanbrowsing.org/filters/)可用 |
| [NextDNS](https://nextdns.io/?from=bg25bwmp) | 按需选择 | 按需选择 | 广告拦截，免费套餐可用。[了解更多](https://nextdns.io/?from=bg25bwmp)。 |
| [Control D](https://controld.com/free-dns) | 按需选择 | 按需选择 | 广告拦截，可配置。[了解更多](https://controld.com/free-dns)。 |

## 不启用 privileged 模式运行

高级用户可以在不启用 [privileged 模式](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) 的情况下使用本镜像创建一个 Docker 容器（将以下命令中的 `./vpn.env` 替换为你自己的 `env` 文件）。

**注：** 如果你的 Docker 主机运行 CentOS Stream, Oracle Linux 8+, Rocky Linux 或者 AlmaLinux，推荐使用 [privileged 模式](../README-zh.md#运行-ipsec-vpn-服务器)。如果你想要不启用 privileged 模式运行，则 **必须** 在创建 Docker 容器之前以及系统启动时运行 `modprobe ip_tables`。

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
    hwdsl2/ipsec-vpn-server
```

在不启用 privileged 模式运行时，容器不能更改 `sysctl` 设置。这可能会影响本镜像的某些功能。一个已知问题是 [Android/Linux MTU/MSS fix](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#androidlinux-mtumss-问题) 需要另外在 `docker run` 命令添加 `--sysctl net.ipv4.ip_no_pmtu_disc=1` 才有效。如果你遇到任何问题，可以尝试换用 [privileged 模式](../README-zh.md#运行-ipsec-vpn-服务器) 重新创建容器。

在创建 Docker 容器之后，请转到 [获取 VPN 登录信息](../README-zh.md#获取-vpn-登录信息)。

类似地，如果你使用 [Docker compose](https://docs.docker.com/compose/)，可以将 [docker-compose.yml](../docker-compose.yml) 中的 `privileged: true` 替换为：

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
```

更多信息请参见 [compose file reference](https://docs.docker.com/compose/compose-file/)。

## 选择 VPN 模式

在使用此 Docker 镜像时，默认启用 IPsec/L2TP 和 IPsec/XAuth ("Cisco IPsec") 模式。此外，如果在创建 Docker 容器时在 `docker run` 命令中[指定](../README-zh.md#运行-ipsec-vpn-服务器)了 `-v ikev2-vpn-data:/etc/ipsec.d` 选项，则会启用 IKEv2 模式。

高级用户可以有选择性地禁用 VPN 模式，通过在 `env` 文件中设置以下变量并重新创建 Docker 容器来实现。

禁用 IPsec/L2TP 模式：`VPN_DISABLE_IPSEC_L2TP=yes`   
禁用 IPsec/XAuth ("Cisco IPsec") 模式：`VPN_DISABLE_IPSEC_XAUTH=yes`   
禁用 IPsec/L2TP 和 IPsec/XAuth 模式：`VPN_IKEV2_ONLY=yes`

## 访问 Docker 主机上的其它容器

连接到 VPN 后，VPN 客户端通常可以访问在同一 Docker 主机上其他容器中运行的服务，而无需进行其他配置。

例如，如果 IPsec VPN 服务器容器的 IP 为 `172.17.0.2`，并且一个 IP 为 `172.17.0.3` 的 Nginx 容器在同一 Docker 主机上运行，则 VPN 客户端可以使用 IP `172.17.0.3` 来访问 Nginx 容器上的服务。要找出分配给容器的 IP ，可以运行 `docker inspect <container name>`。

## 指定 VPN 服务器的公有 IP

在具有多个公有 IP 地址的 Docker 主机上，高级用户可以使用 `env` 文件中的变量 `VPN_PUBLIC_IP` 为 VPN 服务器指定一个公有 IP，然后重新创建 Docker 容器。例如，如果 Docker 主机的 IP 为 `192.0.2.1` 和 `192.0.2.2`，并且你想要 VPN 服务器使用 `192.0.2.2`：

```
VPN_PUBLIC_IP=192.0.2.2
```

请注意，如果在 Docker 容器中已经配置了 IKEv2，则此变量对 IKEv2 模式无效。在这种情况下，你可以移除 IKEv2 并使用自定义选项重新配置它。参见 [配置并使用 IKEv2 VPN](../README-zh.md#配置并使用-ikev2-vpn)。

如果你想要 VPN 客户端在 VPN 连接处于活动状态时使用指定的公有 IP 作为其 "出站 IP"，并且指定的 IP **不是** Docker 主机上的主 IP（或默认路由），则可能需要额外的配置。在这种情况下，你可以尝试在 Docker 主机上添加一个 IPTables `SNAT` 规则。如果要在重启后继续有效，你可以将命令添加到 `/etc/rc.local`。

继续上面的例子，如果 Docker 容器具有内部 IP `172.17.0.2`（使用 `docker inspect ipsec-vpn-server` 查看），Docker 的网络接口名称为 `docker0`（使用 `iptables -nvL -t nat` 查看)，并且你希望 "出站 IP" 为 `192.0.2.2`：

```
iptables -t nat -I POSTROUTING -s 172.17.0.2 ! -o docker0 -j SNAT --to 192.0.2.2
```

要检查一个已连接的 VPN 客户端的 "出站 IP"，你可以在该客户端上打开浏览器并到 [这里](https://www.ipchicken.com) 检测 IP 地址。

## 为 VPN 客户端指定静态 IP

在使用 IPsec/L2TP 模式连接时，VPN 服务器（Docker 容器）在虚拟网络 `192.168.42.0/24` 内具有内网 IP `192.168.42.1`。为客户端分配的内网 IP 在这个范围内：`192.168.42.10` 到 `192.168.42.250`。要找到为特定的客户端分配的 IP，可以查看该 VPN 客户端上的连接状态。

在使用 IPsec/XAuth ("Cisco IPsec") 或 IKEv2 模式连接时，VPN 服务器（Docker 容器）在虚拟网络 `192.168.43.0/24` 内 **没有** 内网 IP。为客户端分配的内网 IP 在这个范围内：`192.168.43.10` 到 `192.168.43.250`。

高级用户可以将静态 IP 分配给 VPN 客户端。这是可选的。IKEv2 模式 **不支持** 此功能。要分配静态 IP，在你的 `env` 文件中定义 `VPN_ADDL_IP_ADDRS` 变量，然后重新创建 Docker 容器。例如：

```
VPN_ADDL_USERS=user1 user2 user3 user4 user5
VPN_ADDL_PASSWORDS=pass1 pass2 pass3 pass4 pass5
VPN_ADDL_IP_ADDRS=* * 192.168.42.2 192.168.43.2
```

在此示例中，我们为 IPsec/L2TP 模式的 `user3` 分配静态 IP `192.168.42.2`，并为 IPsec/XAuth ("Cisco IPsec") 模式的 `user4` 分配静态 IP `192.168.43.2`。`user1`, `user2` 和 `user5` 的内网 IP 将被自动分配。`user3` 在 IPsec/XAuth 模式下的内网 IP 和 `user4` 在 IPsec/L2TP 模式下的内网 IP 也将被自动分配。你可以使用 `*` 来指定自动分配的 IP，或者将这些用户放在列表的末尾。

你为 IPsec/L2TP 模式指定的静态 IP 必须在 `192.168.42.2` 到 `192.168.42.9` 范围内。你为 IPsec/XAuth ("Cisco IPsec") 模式指定的静态 IP 必须在 `192.168.43.2` 到 `192.168.43.9` 范围内。

如果你需要分配更多静态 IP，则必须缩小自动分配的 IP 地址池。示例如下：

```
VPN_L2TP_POOL=192.168.42.100-192.168.42.250
VPN_XAUTH_POOL=192.168.43.100-192.168.43.250
```

这将允许你为 IPsec/L2TP 模式在 `192.168.42.2` 到 `192.168.42.99` 范围内分配静态 IP，并且为 IPsec/XAuth ("Cisco IPsec") 模式在 `192.168.43.2` 到 `192.168.43.99` 范围内分配静态 IP。

请注意，如果你在 `env` 文件中指定了 `VPN_XAUTH_POOL`，并且在 Docker 容器中已经配置了 IKEv2，你 **必须** 在重新创建 Docker 容器之前手动编辑容器内的 `/etc/ipsec.d/ikev2.conf` 并将 `rightaddresspool=192.168.43.10-192.168.43.250` 替换为与 `VPN_XAUTH_POOL` **相同的值**。否则 IKEv2 可能会停止工作。

**注：** 在你的 `env` 文件中，**不要**为变量值添加 `""` 或者 `''`，或在 `=` 两边添加空格。**不要**在值中使用这些字符： `\ " '`。

## 自定义 VPN 子网

默认情况下，IPsec/L2TP VPN 客户端将使用内部 VPN 子网 `192.168.42.0/24`，而 IPsec/XAuth ("Cisco IPsec") 和 IKEv2 VPN 客户端将使用内部 VPN 子网 `192.168.43.0/24`。有关更多详细信息，请阅读上一节。

对于大多数用例，没有必要也 **不建议** 自定义这些子网。但是，如果你的用例需要它，你可以在 `env` 文件中指定自定义子网，然后你必须重新创建 Docker 容器。

```
# 示例：为 IPsec/L2TP 模式指定自定义 VPN 子网
# 注：必须指定所有三个变量。
VPN_L2TP_NET=10.1.0.0/16
VPN_L2TP_LOCAL=10.1.0.1
VPN_L2TP_POOL=10.1.0.10-10.1.254.254
```

```
# 示例：为 IPsec/XAuth 和 IKEv2 模式指定自定义 VPN 子网
# 注：必须指定以下两个变量。
VPN_XAUTH_NET=10.2.0.0/16
VPN_XAUTH_POOL=10.2.0.10-10.2.254.254
```

**注：** 在你的 `env` 文件中，**不要**为变量值添加 `""` 或者 `''`，或在 `=` 两边添加空格。

在上面的例子中，`VPN_L2TP_LOCAL` 是在 IPsec/L2TP 模式下的 VPN 服务器的内网 IP。`VPN_L2TP_POOL` 和 `VPN_XAUTH_POOL` 是为 VPN 客户端自动分配的 IP 地址池。

请注意，如果你在 `env` 文件中指定了 `VPN_XAUTH_POOL`，并且在 Docker 容器中已经配置了 IKEv2，你 **必须** 在重新创建 Docker 容器之前手动编辑容器内的 `/etc/ipsec.d/ikev2.conf` 并将 `rightaddresspool=192.168.43.10-192.168.43.250` 替换为与 `VPN_XAUTH_POOL` **相同的值**。否则 IKEv2 可能会停止工作。

## VPN 分流

在启用 VPN 分流 (split tunneling) 时，VPN 客户端将仅通过 VPN 隧道发送特定目标子网的流量。其他流量 **不会** 通过 VPN 隧道。这允许你通过 VPN 安全访问指定的网络，而无需通过 VPN 发送所有客户端的流量。VPN 分流有一些局限性，而且并非所有的 VPN 客户端都支持。

高级用户可以为 IKEv2 模式启用 VPN 分流。这是可选的。将变量 `VPN_SPLIT_IKEV2` 添加到你的 `env` 文件，然后重新创建 Docker 容器。例如，如果目标子网是 `10.123.123.0/24`：

```
VPN_SPLIT_IKEV2=10.123.123.0/24
```

请注意，如果在 Docker 容器中已经配置了 IKEv2，则此变量无效。在这种情况下，有两个选项：

**选项 1：** 首先[在容器中运行 Bash shell](#在容器中运行-bash-shell)，然后编辑 `/etc/ipsec.d/ikev2.conf` 并将 `leftsubnet=0.0.0.0/0` 替换为你想要的子网。在完成后，退出容器并运行 `docker restart ipsec-vpn-server`。

**选项 2：** 删除 Docker 容器以及 `ikev2-vpn-data` 卷，然后重新创建容器。这将**永久删除**所有的 VPN 配置。参见[配置并使用 IKEv2 VPN](../README-zh.md#配置并使用-ikev2-vpn) 中的"移除 IKEv2"部分。

另外，Windows 用户也可以通过手动添加路由的方式启用 VPN 分流。有关详细信息，请参阅 [VPN 分流](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/advanced-usage-zh.md#vpn-分流)。

## 关于 host network 模式

高级用户可以使用 [host network 模式](https://docs.docker.com/network/host/) 运行本镜像，通过为 `docker run` 命令添加 `--network=host` 参数来实现。

在非必要的情况下，**不推荐**使用 host network 模式运行本镜像。在该模式下，容器的网络栈未与 Docker 主机隔离，从而在使用 IPsec/L2TP 模式连接之后，VPN 客户端可以使用 Docker 主机的 VPN 内网 IP `192.168.42.1` 访问主机上的端口或服务。请注意，当你不再使用本镜像时，你需要手动清理 [run.sh](../run.sh) 所更改的 IPTables 规则和 sysctl 设置，或者重启服务器。

某些 Docker 主机操作系统，比如 Debian 10，不能使用 host network 模式运行本镜像，因为它们使用 nftables。

## 启用 Libreswan 日志

为了保持较小的 Docker 镜像，Libreswan (IPsec) 日志默认未开启。如果你需要启用它以进行故障排除，首先在正在运行的 Docker 容器中开始一个 Bash 会话：

```
docker exec -it ipsec-vpn-server env TERM=xterm bash -l
```

然后运行以下命令：

```
# For Alpine-based image
apk add --no-cache rsyslog
rsyslogd
rc-service ipsec stop; rc-service -D ipsec start >/dev/null 2>&1
sed -i '\|pluto\.pid|a rm -f /var/run/rsyslogd.pid; rsyslogd' /opt/src/run.sh
exit
# For Debian-based image
apt-get update && apt-get -y install rsyslog
rsyslogd
service ipsec restart
sed -i '\|pluto\.pid|a rm -f /var/run/rsyslogd.pid; rsyslogd' /opt/src/run.sh
exit
```

**注：** 如果你在不启用 privileged 模式的情况下使用本镜像，则错误 `rsyslogd: imklog: cannot open kernel log` 是正常的。

完成后你可以这样查看 Libreswan 日志：

```
docker exec -it ipsec-vpn-server grep pluto /var/log/auth.log
```

如需查看 xl2tpd 日志，请运行 `docker logs ipsec-vpn-server`。

## 查看服务器状态

检查 IPsec VPN 服务器状态：

```
docker exec -it ipsec-vpn-server ipsec status
```

查看当前已建立的 VPN 连接：

```
docker exec -it ipsec-vpn-server ipsec trafficstatus
```

## 从源代码构建

高级用户可以从 GitHub 下载并自行编译源代码：

```
git clone https://github.com/hwdsl2/docker-ipsec-vpn-server
cd docker-ipsec-vpn-server
# To build Alpine-based image
docker build -t hwdsl2/ipsec-vpn-server .
# To build Debian-based image
docker build -f Dockerfile.debian -t hwdsl2/ipsec-vpn-server:debian .
```

若不需要改动源码，也可以这样：

```
# To build Alpine-based image
docker build -t hwdsl2/ipsec-vpn-server github.com/hwdsl2/docker-ipsec-vpn-server
# To build Debian-based image
docker build -f Dockerfile.debian -t hwdsl2/ipsec-vpn-server:debian \
  github.com/hwdsl2/docker-ipsec-vpn-server
```

## 在容器中运行 Bash shell

在正在运行的 Docker 容器中开始一个 Bash 会话：

```
docker exec -it ipsec-vpn-server env TERM=xterm bash -l
```

（可选步骤）安装 `nano` 编辑器：

```
# For Alpine-based image
apk add --no-cache nano
# For Debian-based image
apt-get update && apt-get -y install nano
```

然后在容器中运行你的命令。完成后退出并重启 Docker 容器（如果需要）：

```
exit
docker restart ipsec-vpn-server
```

## 绑定挂载 env 文件

作为 `--env-file` 选项的替代方案，高级用户可以绑定挂载 `env` 文件。该方法的好处是你在更新 `env` 文件之后可以重启 Docker 容器以生效，而不需要重新创建它。要使用这个方法，你必须首先编辑你的 `env` 文件并将所有的变量值用单引号 `''` 括起来。然后（重新）创建 Docker 容器（将第一个 `vpn.env` 替换为你自己的 `env` 文件）：

```
docker run \
    --name ipsec-vpn-server \
    --restart=always \
    -v "$(pwd)/vpn.env:/opt/src/env/vpn.env:ro" \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v /lib/modules:/lib/modules:ro \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

## 部署 Google BBR 拥塞控制

VPN 服务器搭建完成后，可以通过在 Docker 主机上部署 Google BBR 拥塞控制算法提升性能。

这通常只需要在配置文件 `/etc/sysctl.conf` 中插入设定即可完成。但是部分 Linux 发行版可能需要额外更新 Linux 内核。

详细的部署方法，可以参考[这篇文档](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/bbr-zh.md)。在完成后重启 Docker 容器：

```
docker restart ipsec-vpn-server
```

## 授权协议

**注：** 预构建镜像中的软件组件（例如 Libreswan 和 xl2tpd）在其各自版权所有者选择的相应许可下。对于任何预构建的镜像的使用，用户有责任确保对该镜像的任何使用符合其中包含的所有软件的任何相关许可。

版权所有 (C) 2016-2024 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
这个项目是以 [知识共享署名-相同方式共享3.0](http://creativecommons.org/licenses/by-sa/3.0/) 许可协议授权。   
必须署名： 请包括我的名字在任何衍生产品，并且让我知道你是如何改善它的！
