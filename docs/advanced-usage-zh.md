# 高级用法

*其他语言版本: [English](advanced-usage.md), [简体中文](advanced-usage-zh.md).*

- [使用其他的 DNS 服务器](#使用其他的-dns-服务器)
- [不启用 privileged 模式运行](#不启用-privileged-模式运行)
- [选择 VPN 模式](#选择-vpn-模式)
- [访问 Docker 主机上的其它容器](#访问-docker-主机上的其它容器)
- [关于 host network 模式](#关于-host-network-模式)
- [启用 Libreswan 日志](#启用-libreswan-日志)
- [查看服务器状态](#查看服务器状态)
- [从源代码构建](#从源代码构建)
- [在容器中运行 Bash shell](#在容器中运行-bash-shell)
- [绑定挂载 env 文件](#绑定挂载-env-文件)

## 使用其他的 DNS 服务器

在 VPN 已连接时，客户端配置为使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。如果偏好其它的域名解析服务，你可以在 `env` 文件中定义 `VPN_DNS_SRV1` 和 `VPN_DNS_SRV2`（可选），然后按照[说明](../README-zh.md#更新-docker-镜像)重新创建 Docker 容器。比如你想使用 [Cloudflare 的 DNS 服务](https://1.1.1.1)：

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

## 不启用 privileged 模式运行

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

在不启用 privileged 模式运行时，容器不能更改 `sysctl` 设置。这可能会影响本镜像的某些功能。一个已知问题是 [Android MTU/MSS fix](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#android-mtumss-问题) 需要另外在 `docker run` 命令添加 `--sysctl net.ipv4.ip_no_pmtu_disc=1` 才有效。如果你遇到任何问题，可以尝试换用 [privileged 模式](../README-zh.md#运行-ipsec-vpn-服务器) 重新创建容器。

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
    - net.ipv4.conf.eth0.send_redirects=0
    - net.ipv4.conf.eth0.rp_filter=0
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

## 关于 host network 模式

高级用户可以使用 [host network 模式](https://docs.docker.com/network/host/) 运行本镜像，通过为 `docker run` 命令添加 `--network=host` 参数来实现。另外，如果 [不启用 privileged 模式运行](#不启用-privileged-模式运行)，你可能还需要将 `eth0` 替换为你的 Docker 主机的网络接口名称。

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
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v "$(pwd)/vpn.env:/opt/src/vpn.env:ro" \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
```

## 授权协议

**注：** 预构建镜像中的软件组件（例如 Libreswan 和 xl2tpd）在其各自版权所有者选择的相应许可下。对于任何预构建的镜像的使用，用户有责任确保对该镜像的任何使用符合其中包含的所有软件的任何相关许可。

版权所有 (C) 2016-2021 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
这个项目是以 [知识共享署名-相同方式共享3.0](http://creativecommons.org/licenses/by-sa/3.0/) 许可协议授权。   
必须署名： 请包括我的名字在任何衍生产品，并且让我知道你是如何改善它的！
