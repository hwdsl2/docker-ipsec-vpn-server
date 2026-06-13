---
name: 错误报告
about: 请使用这个模板来提交 bug
title: ''
labels: ''
assignees: ''

---

**任务列表**

- [ ] 我已阅读[自述文件](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md)
- [ ] 我已阅读[重要提示](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md#重要提示)
- [ ] 我已按照说明[配置 VPN 客户端](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README-zh.md#下一步)
- [ ] 我检查了 [IKEv1 故障排除](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#ikev1-故障排除)，[IKEv2 故障排除](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md#ikev2-故障排除)，[启用日志](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage-zh.md#启用-libreswan-日志)并查看了[服务器状态](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage-zh.md#查看服务器状态)
- [ ] 我搜索了已有的 [Issues](https://github.com/hwdsl2/docker-ipsec-vpn-server/issues?q=is%3Aissue)
- [ ] 这个 bug 是关于 IPsec VPN 服务器 Docker 镜像，而不是 IPsec VPN 本身

<!---
如果你发现的是 IPsec VPN 本身的可重复 bug，请在 https://github.com/libreswan/libreswan 提交错误报告。VPN 的相关问题可在 [Libreswan](https://lists.libreswan.org) 或 [strongSwan](https://lists.strongswan.org) 用户邮件列表提问，或者搜索比如 [Stack Overflow](https://stackoverflow.com/questions/tagged/vpn) 等网站。

发布日志、env 文件、Docker Compose 文件或配置前，请删除 VPN 凭据、私钥、IPsec PSK、密码和其它敏感信息。
--->

**问题描述**
使用清楚简明的语言描述这个 bug。

**重现步骤**
重现该 bug 的步骤：

1. ...
2. ...

**期待的正确结果**
简要地描述你期望的正确结果。

**日志**
[启用日志](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage-zh.md#启用-libreswan-日志)，检查[服务器状态](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage-zh.md#查看服务器状态)，并添加相关错误日志以帮助解释该问题（如果适用）。

常用命令包括：

```bash
docker logs ipsec-vpn-server
docker exec -it ipsec-vpn-server grep pluto /var/log/auth.log
docker exec -it ipsec-vpn-server ipsec status
docker exec -it ipsec-vpn-server ipsec trafficstatus
```

**Docker/服务器信息（请填写以下信息）**
- 镜像和标签: [比如 `hwdsl2/ipsec-vpn-server`, `hwdsl2/ipsec-vpn-server:debian`]
- 容器名称: [比如 `ipsec-vpn-server`]
- 启动方式: [比如 `docker run`, Docker Compose, Podman, Synology, Unraid]
- Docker 主机操作系统和版本: [比如 Ubuntu 24.04]
- Docker 主机架构: [比如 x86_64, arm64]
- Docker/Podman 版本: [比如 Docker 28.x]
- privileged 模式: [是/否]
- 服务提供商（如果适用）: [比如 GCP, AWS]
- 外部防火墙/NAT: [比如 UDP 500/4500 已开放，位于 NAT 后，不适用]

**配置**
- VPN 模式: [IPsec/L2TP, IPsec/XAuth ("Cisco IPsec") 或 IKEv2]
- Docker 命令或 Compose 文件: [粘贴相关部分，并删除敏感信息]
- 修改过的 env 文件或变量: [粘贴相关部分，并删除敏感信息]
- 持久化卷或绑定挂载: [比如 `ikev2-vpn-data:/etc/ipsec.d`]

**客户端信息（请填写以下信息）**
- 设备: [比如 iPhone 15]
- 操作系统和版本: [比如 iOS 18]
- VPN 客户端应用及版本（如果适用）: [比如 strongSwan VPN Client 2.x]

**其它信息**
添加关于该 bug 的其它信息。
