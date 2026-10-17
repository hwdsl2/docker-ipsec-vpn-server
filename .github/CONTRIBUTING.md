# Contributing

Thanks for helping improve this project. This repository maintains the Docker image for IPsec VPN; bare-metal install script changes belong in [setup-ipsec-vpn](https://github.com/hwdsl2/setup-ipsec-vpn).

## Before You Start

- Search existing issues and pull requests.
- Keep changes focused and easy to review.
- For upstream Libreswan or xl2tpd behavior, check the upstream project first.
- Do not include IPsec PSKs, passwords, private keys, client configs, env secrets, or logs with secrets.

## Pull Requests

- Update `README.md`, env examples, compose examples, or docs when behavior changes.
- Include the Docker host OS, architecture, image tag, and start method tested.
- Note privileged/non-privileged mode and VPN mode tested when relevant.

## Testing

Test the smallest relevant path before opening a PR, for example:

- Build or run the affected Alpine/Debian image when Dockerfile/runtime behavior changes.
- Exercise IPsec/L2TP, IPsec/XAuth, or IKEv2 paths touched by the change.
- Check `docker logs`, `ipsec status`, and `ipsec trafficstatus` for runtime changes.
- Run ShellCheck when editing shell scripts.
