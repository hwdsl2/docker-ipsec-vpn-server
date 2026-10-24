# Changelog

Notable changes to the Docker IPsec VPN server are documented here.

## 2026-08-27

### Fixed

- Fixed `VPN_SPLIT_IKEV2` so the requested split-tunnel subnet is applied when
  initializing IKEv2 configuration.

## 2026-08-22

### Compatibility

- Removed the legacy MODP1024 option. `VPN_ENABLE_MODP1024=yes` is now ignored
  with a warning; use IKEv2 for affected Android clients.

## 2026-06-04

### Fixed

- Restored project-scoped naming for `ikev2-vpn-data` so existing Compose
  deployments reuse their original volume. Deployments using the temporary
  global name should retain that volume mapping when updating.

## 2026-03-23

### Added

- Added `VPN_CLIENT_VALIDITY` to configure client-certificate validity during
  automatic IKEv2 setup. Existing certificates are unchanged.

## 2026-03-18

### Added

- Added IPv6 support for IKEv2 clients. Requires a public IPv6 address on the
  host and IPv6-enabled container networking; see
  [IPv6 setup](docs/advanced-usage.md#ipv6-support)
  for client-specific requirements.

## 2024-02-24

### Added

- Added `VPN_SPLIT_IKEV2` to configure an IPv4 subnet for IKEv2 split tunneling
  during initial setup.

## 2023-04-24

### Fixed

- Added a fallback NAT rule for hosts where the iptables policy match is
  unavailable.

## 2022-09-30

### Compatibility

- Changed the default IPsec/L2TP and XAuth IKE proposals to MODP2048,
  excluding MODP1024 and MODP1536 by default. Affected Android clients should
  use IKEv2.

## 2022-03-28

### Fixed

- Added automatic recovery of a crashed IPsec service in Alpine images,
  avoiding the need to restart the container manually.

## 2022-03-03

### Added

- Added `VPN_ADDL_IP_ADDRS` to assign static VPN addresses to additional
  IPsec/L2TP and XAuth user accounts.

## 2022-02-15

### Added

- Added `VPN_PROTECT_CONFIG=yes` to enable password protection for IKEv2 client
  configuration files during automatic setup.

## 2022-01-03

### Fixed

- Fixed a potential security issue when handling multi-line responses from
  the Libreswan update check.

## 2021-07-19

### Added

- Added `VPN_IKEV2_ONLY=yes` and options to disable IPsec/L2TP or XAuth
  individually.

## 2021-07-14

### Changed

- Switched the default image to Alpine. The Debian image remains available
  as `hwdsl2/ipsec-vpn-server:debian`.

## 2021-06-01

### Added

- Added support for revoking IKEv2 client certificates through the bundled
  helper.

## 2021-03-03

### Changed

- Newly generated PSKs and login credentials now persist in `/etc/ipsec.d`
  across container recreation when the same data volume is reused.

## 2021-02-20

### Added

- Enabled automatic IKEv2 setup when a fresh data volume is mounted at
  `/etc/ipsec.d`.

## 2021-02-09

### Added

- Added `VPN_DNS_NAME` to use a DNS name as the VPN server address, including
  during IKEv2 setup.

## 2020-12-02

### Added

- Added support for [host network mode](docs/advanced-usage.md#about-host-network-mode).

## 2020-11-28

### Added

- Added support for [running without privileged mode](docs/advanced-usage.md#run-without-privileged-mode)
  using explicit capabilities and device access.

## 2020-06-21

### Added

- Added multi-architecture images, including ARM64 and ARMv7 support.

## 2020-05-31

### Added

- Added certificate-based IKEv2 setup alongside IPsec/L2TP and XAuth, with
  configuration and certificates persisted in a volume at `/etc/ipsec.d`.

## 2020-04-18

### Added

- Added Podman support.

## 2018-12-20

### Added

- Added bind-mounted environment files so IPsec/L2TP and XAuth settings can
  be refreshed on container restart.

## 2018-11-07

### Added

- Added multiple IPsec/L2TP and XAuth accounts using `VPN_ADDL_USERS` and
  `VPN_ADDL_PASSWORDS`.

## 2017-02-11

### Added

- Added environment variables for customizing VPN subnets, client address
  pools, and DNS servers.

## 2016-09-26

### Changed

- Automatically generated VPN credentials are now reused across container
  restarts.

## Earlier notable changes

- The initial Debian image provided IPsec/L2TP and Cisco IPsec (XAuth), with
  automatic PSK and password generation when credentials were not supplied.
