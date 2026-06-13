---
name: Bug report
about: Tell us about a problem you are experiencing
title: ''
labels: ''
assignees: ''

---

**Checklist**

- [ ] I read the [README](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md)
- [ ] I read the [Important notes](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md#important-notes)
- [ ] I followed instructions to [configure VPN clients](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md#next-steps)
- [ ] I checked [IKEv1 troubleshooting](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#ikev1-troubleshooting), [IKEv2 troubleshooting](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md#ikev2-troubleshooting), [enabled logs](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage.md#enable-libreswan-logs) and checked [server status](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage.md#check-server-status)
- [ ] I searched existing [Issues](https://github.com/hwdsl2/docker-ipsec-vpn-server/issues?q=is%3Aissue)
- [ ] This bug is about the IPsec VPN server Docker image, and not IPsec VPN itself

<!---
If you found a reproducible bug in IPsec VPN itself, open a bug report at https://github.com/libreswan/libreswan. Ask VPN-related questions on the [Libreswan](https://lists.libreswan.org) or [strongSwan](https://lists.strongswan.org) users mailing list, or search e.g. [Stack Overflow](https://stackoverflow.com/questions/tagged/vpn).

Before posting logs, env files, Docker Compose files or configuration, remove VPN credentials, private keys, IPsec PSKs, passwords and other secrets.
--->

**Describe the issue**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:

1. ...
2. ...

**Expected behavior**
A clear and concise description of what you expected to happen.

**Logs**
[Enable logs](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage.md#enable-libreswan-logs), check [server status](https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage.md#check-server-status), and add relevant error logs to help explain the problem, if applicable.

Useful commands include:

```bash
docker logs ipsec-vpn-server
docker exec -it ipsec-vpn-server grep pluto /var/log/auth.log
docker exec -it ipsec-vpn-server ipsec status
docker exec -it ipsec-vpn-server ipsec trafficstatus
```

**Docker/server information (please complete the following information)**
- Image and tag: [e.g. `hwdsl2/ipsec-vpn-server`, `hwdsl2/ipsec-vpn-server:debian`]
- Container name: [e.g. `ipsec-vpn-server`]
- Start method: [e.g. `docker run`, Docker Compose, Podman, Synology, Unraid]
- Docker host OS and version: [e.g. Ubuntu 24.04]
- Docker host architecture: [e.g. x86_64, arm64]
- Docker/Podman version: [e.g. Docker 28.x]
- Privileged mode: [yes/no]
- Hosting provider (if applicable): [e.g. GCP, AWS]
- External firewall/NAT: [e.g. UDP 500/4500 open, behind NAT, not applicable]

**Configuration**
- VPN mode: [IPsec/L2TP, IPsec/XAuth ("Cisco IPsec") or IKEv2]
- Docker command or Compose file: [paste relevant parts with secrets removed]
- Env file or variables changed: [paste relevant parts with secrets removed]
- Persistent volume or bind mount: [e.g. `ikev2-vpn-data:/etc/ipsec.d`]

**Client (please complete the following information)**
- Device: [e.g. iPhone 15]
- OS and version: [e.g. iOS 18]
- VPN client app and version (if applicable): [e.g. strongSwan VPN Client 2.x]

**Additional context**
Add any other context about the problem here.
