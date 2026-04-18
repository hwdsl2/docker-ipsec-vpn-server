[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# Docker 上的 IPsec VPN 伺服器

[![Build Status](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml/badge.svg)](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml) [![GitHub Stars](docs/images/badges/github-stars.svg)](https://github.com/hwdsl2/docker-ipsec-vpn-server/stargazers) [![Docker Stars](docs/images/badges/docker-stars.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/) [![Docker Pulls](docs/images/badges/docker-pulls.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/)

使用此 Docker 映像快速架設 IPsec VPN 伺服器。支援 IPsec/L2TP、Cisco IPsec 和 IKEv2 協議。

本映像以 Alpine 3.23 或 Debian 12 為基礎，並使用 [Libreswan](https://libreswan.org)（IPsec VPN 軟體）和 [xl2tpd](https://github.com/xelerance/xl2tpd)（L2TP 服務程序）。

IPsec VPN 可以加密你的網路流量，以防止在透過網際網路傳送時，你與 VPN 伺服器之間的任何人未經授權存取你的資料。在使用不安全的網路時，這一點特別有用，例如在咖啡廳、機場或旅館房間。

**功能特性：**

- 首次啟動時自動產生 VPN 憑證和 IKEv2 設定
- 支援具有強大且快速加密演算法（例如 AES-GCM）的 IKEv2 模式
- 生成 VPN 設定檔以自動設定 iOS、macOS 和 Android 裝置
- 支援 Windows、macOS、iOS、Android、Chrome OS 和 Linux 客戶端
- 包含輔助腳本以管理 IKEv2 使用者與憑證
- 透過 [GitHub Actions](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml) 自動建置和發布
- 使用 Docker 卷實現資料持久化
- 多架構支援：`linux/amd64`、`linux/arm64`、`linux/arm/v7`

**另提供：**

- VPN：[WireGuard](https://github.com/hwdsl2/docker-wireguard/blob/main/README-zh-Hant.md)、[OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-zh-Hant.md)、[Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-zh-Hant.md)
- AI/音訊：[Whisper (STT)](https://github.com/hwdsl2/docker-whisper/blob/main/README-zh-Hant.md)、[Kokoro (TTS)](https://github.com/hwdsl2/docker-kokoro/blob/main/README-zh-Hant.md)、[Embeddings](https://github.com/hwdsl2/docker-embeddings/blob/main/README-zh-Hant.md)、[LiteLLM](https://github.com/hwdsl2/docker-litellm/blob/main/README-zh-Hant.md)
- :book: Book：[Privacy Tools in the Age of AI](docs/vpn-book-zh-Hant.md)、[架設自己的 VPN 伺服器](docs/vpn-book-zh-Hant.md)

## 快速開始

使用以下命令在 Docker 上快速架設 IPsec VPN 伺服器：

```bash
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

你的 VPN 登入憑證將會自動隨機生成。請參見[取得 VPN 登入資訊](#取得-vpn-登入資訊)。

另外，你也可以在不使用 Docker 的情況下[安裝 IPsec VPN](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-zh-Hant.md)。若要了解更多關於如何使用本映像的資訊，請繼續閱讀以下部分。

## 系統需求

- 具有公用 IP 位址或 DNS 名稱的 Linux 伺服器
- 已安裝 Docker
- 在防火牆中開啟 VPN 連接埠（UDP 500 和 4500）
- 你也可以使用 [Podman](https://docs.podman.io) 執行本映像，需要先為 `docker` 命令建立一個別名

**注：** 進階使用者可以在 macOS 上透過安裝 [Docker for Mac](https://docs.docker.com/desktop/setup/install/mac-install/) 使用本映像。在使用 IPsec/L2TP 模式之前，你可能需要執行 `docker restart ipsec-vpn-server` 重新啟動一次容器。本映像不支援 Docker for Windows。

## 下載

預先建構的可信任映像可在 [Docker Hub registry](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/) 下載：

```bash
docker pull hwdsl2/ipsec-vpn-server
```

或者，你也可以從 [Quay.io](https://quay.io/repository/hwdsl2/ipsec-vpn-server) 下載：

```bash
docker pull quay.io/hwdsl2/ipsec-vpn-server
docker image tag quay.io/hwdsl2/ipsec-vpn-server hwdsl2/ipsec-vpn-server
```

支援的平台：`linux/amd64`、`linux/arm64` 和 `linux/arm/v7`。

進階使用者可以自行從 GitHub [編譯原始碼](docs/advanced-usage-zh.md#从源代码构建)。

### 映像對照表

有兩個預先建構的映像可用。預設的基於 Alpine 的映像大小僅約 ~19 MB。

|                 | 基於 Alpine               | 基於 Debian                     |
| --------------- | ------------------------ | ------------------------------ |
| 映像名稱          | hwdsl2/ipsec-vpn-server  | hwdsl2/ipsec-vpn-server:debian |
| 壓縮後大小        | ~ 19 MB                  | ~ 62 MB                        |
| 基礎映像          | Alpine Linux 3.23        | Debian Linux 12                |
| 系統架構          | amd64, arm64, arm/v7     | amd64, arm64, arm/v7           |
| Libreswan 版本   | 5.3                      | 5.3                            |
| IPsec/L2TP      | ✅                       | ✅                              |
| Cisco IPsec     | ✅                       | ✅                              |
| IKEv2           | ✅                       | ✅                              |

**註：** 若要使用基於 Debian 的映像，請將本自述文件中所有的 `hwdsl2/ipsec-vpn-server` 替換為 `hwdsl2/ipsec-vpn-server:debian`。這些映像目前與 Synology NAS 系統不相容。

<details>
<summary>
我需要使用較舊版本的 Libreswan 版本 4。
</summary>

一般建議使用最新的 [Libreswan](https://libreswan.org/) 版本 5，它是本專案的預設版本。不過，如果你想要使用較舊版本的 Libreswan 版本 4，你可以從原始碼建構 Docker 映像：

```bash
git clone https://github.com/hwdsl2/docker-ipsec-vpn-server
cd docker-ipsec-vpn-server
# Specify Libreswan version 4
sed -i 's/SWAN_VER=5\..*/SWAN_VER=4.15/' Dockerfile Dockerfile.debian
# To build Alpine-based image
docker build -t hwdsl2/ipsec-vpn-server .
# To build Debian-based image
docker build -f Dockerfile.debian -t hwdsl2/ipsec-vpn-server:debian .
```
</details>

## 如何使用本映像

### 環境變數

**註：** 所有這些變數對於本映像都是可選的，也就是說即使不定義它們也可以架設 IPsec VPN 伺服器。你可以執行 `touch vpn.env` 建立一個空的 `env` 檔案，然後跳到下一節。

此 Docker 映像使用以下幾個變數，可以在一個 `env` 檔案中定義（參見[範例](vpn.env.example)）：

```
VPN_IPSEC_PSK=your_ipsec_pre_shared_key
VPN_USER=your_vpn_username
VPN_PASSWORD=your_vpn_password
```

這將建立一個用於 VPN 登入的使用者帳戶，它可以在你的多個裝置上使用[\*](#重要提示)。IPsec PSK（預共享金鑰）由 `VPN_IPSEC_PSK` 環境變數指定。VPN 使用者名稱與密碼分別在 `VPN_USER` 和 `VPN_PASSWORD` 中定義。

支援建立額外的 VPN 使用者，如果需要，可以像下面這樣在你的 `env` 檔案中定義。使用者名稱與密碼必須分別使用空格分隔，並且使用者名稱不能重複。所有 VPN 使用者將共用同一個 IPsec PSK。

```
VPN_ADDL_USERS=additional_username_1 additional_username_2
VPN_ADDL_PASSWORDS=additional_password_1 additional_password_2
```

以上變數僅適用於 IPsec/L2TP 和 IPsec/XAuth（"Cisco IPsec"）模式。對於 IKEv2，請參見[設定並使用 IKEv2 VPN](#設定並使用-ikev2-vpn)。

**註：** 在你的 `env` 檔案中，**不要**為變數值加入 `""` 或 `''`，或在 `=` 兩側加入空格。**不要**在值中使用這些字元： `\ " '`。一個安全的 IPsec PSK 應至少包含 20 個隨機字元。

**註：** 如果在建立 Docker 容器後修改 `env` 檔案，則必須刪除並重新建立容器才能讓變更生效。請參見[更新 Docker 映像](#更新-docker-映像)。

### 其他環境變數

進階使用者可以指定一個網域名稱、客戶端名稱和/或其他 DNS 伺服器。這是可選的。

<details>
<summary>
了解如何指定一個網域名稱、客戶端名稱和/或其他 DNS 伺服器。
</summary>

進階使用者可以指定一個網域名稱作為 IKEv2 伺服器位址。這是可選的。該網域名稱必須是完整網域名稱 (FQDN)。示例如下：

```
VPN_DNS_NAME=vpn.example.com
```

你可以指定第一個 IKEv2 客戶端的名稱。該名稱不能包含空格或除 `-` `_` 之外的任何特殊字元。如果未指定，則使用預設值 `vpnclient`。

```
VPN_CLIENT_NAME=your_client_name
```

在 VPN 已連線時，客戶端預設設定為使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。你可以為所有 VPN 模式指定其他 DNS 伺服器。示例如下：

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

有關詳細資訊以及一些常見的公共 DNS 提供商列表，請參見[使用其他 DNS 伺服器](docs/advanced-usage-zh.md)。

預設情況下，匯入 IKEv2 客戶端設定時不需要密碼。你可以選擇使用隨機密碼保護客戶端設定檔。

```
VPN_PROTECT_CONFIG=yes
```

**註：** 如果在 Docker 容器中已經設定 IKEv2，則以上變數對 IKEv2 模式無效。在這種情況下，你可以移除 IKEv2 並使用自訂選項重新設定它。請參見[設定並使用 IKEv2 VPN](#設定並使用-ikev2-vpn)。
</details>

### 執行 IPsec VPN 伺服器

使用本映像建立一個新的 Docker 容器（將 `./vpn.env` 替換為你自己的 `env` 檔案）：

```bash
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

在此命令中，我們使用 `docker run` 的 `-v` 選項來建立一個名為 `ikev2-vpn-data` 的新 [Docker 卷](https://docs.docker.com/storage/volumes/)，並將它掛載到容器內的 `/etc/ipsec.d` 目錄下。IKEv2 的相關資料（例如憑證與金鑰）會保存在該卷中，之後當你需要重新建立 Docker 容器時，只需指定同一個卷。

建議在使用本映像時啟用 IKEv2。如果你不想啟用 IKEv2，而只使用 IPsec/L2TP 和 IPsec/XAuth（"Cisco IPsec"）模式連線到 VPN，可以移除上面 `docker run` 命令中的第一個 `-v` 選項。

**註：** 進階使用者也可以[在不啟用 privileged 模式下執行](docs/advanced-usage-zh.md#不启用-privileged-模式运行)。

### 取得 VPN 登入資訊

如果你在上述 `docker run` 命令中沒有指定 `env` 檔案，`VPN_USER` 會預設為 `vpnuser`，並且 `VPN_IPSEC_PSK` 和 `VPN_PASSWORD` 會自動隨機生成。要取得這些登入資訊，可以查看容器的日誌：

```bash
docker logs ipsec-vpn-server
```

在命令輸出中尋找以下幾行：

```
Connect to your new VPN with these details:

Server IP: 你的VPN伺服器IP
IPsec PSK: 你的IPsec預共享金鑰
Username: 你的VPN使用者名稱
Password: 你的VPN密碼
```

命令輸出中也會包含 IKEv2 設定資訊（如果已啟用）。

（可選步驟）將自動生成的 VPN 登入資訊（如果有）備份到目前目錄：

```bash
docker cp ipsec-vpn-server:/etc/ipsec.d/vpn-gen.env ./
```

## 使用 docker-compose

```bash
cp vpn.env.example vpn.env
# 如果需要，編輯 vpn.env，然後：
docker compose up -d
docker logs ipsec-vpn-server
```

範例 `docker-compose.yml`（已包含在內）：

```yaml
volumes:
  ikev2-vpn-data:

services:
  vpn:
    image: hwdsl2/ipsec-vpn-server
    restart: always
    env_file:
      - ./vpn.env
    ports:
      - "500:500/udp"
      - "4500:4500/udp"
    privileged: true
    hostname: ipsec-vpn-server
    container_name: ipsec-vpn-server
    volumes:
      - ikev2-vpn-data:/etc/ipsec.d
      - /lib/modules:/lib/modules:ro
```

## 下一步

*其他語言版本: [English](README.md#next-steps), [简体中文](README-zh.md#下一步), [繁體中文](README-zh-Hant.md#下一步), [Русский](README-ru.md#следующие-шаги)。*

設定你的電腦或其他裝置使用 VPN。請參見以下連結（簡體中文）：

**[設定並使用 IKEv2 VPN（推薦）](#設定並使用-ikev2-vpn)**

**[設定 IPsec/L2TP VPN 客戶端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md)**

**[設定 IPsec/XAuth ("Cisco IPsec") VPN 客戶端](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth-zh.md)**

**閱讀 [:book: VPN book](docs/vpn-book-zh-Hant.md) 以存取[額外內容](https://ko-fi.com/post/Support-this-project-and-get-access-to-supporter-o-X8X5FVFZC)。**

開始使用自己的專屬 VPN! :sparkles::tada::rocket::sparkles:

## 重要提示

**Windows 使用者** 對於 IPsec/L2TP 模式，在首次連線之前需要[修改登錄檔](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-zh.md#windows-错误-809)，以解決 VPN 伺服器或客戶端與 NAT（例如家用路由器）的相容問題。

同一個 VPN 帳戶可以在你的多個裝置上使用。但由於 IPsec/L2TP 的限制，如果需要連線到同一個 NAT（例如家用路由器）後面的多個裝置，你必須使用 [IKEv2](#設定並使用-ikev2-vpn) 或 [IPsec/XAuth](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth-zh.md) 模式。

如需新增、修改或刪除 VPN 使用者帳戶，請先更新你的 `env` 檔案，然後必須依照[下一節](#更新-docker-映像)的說明刪除並重新建立 Docker 容器。進階使用者可以[綁定掛載](docs/advanced-usage-zh.md#绑定挂载-env-文件) `env` 檔案。

對於有外部防火牆的伺服器（例如 [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)/[GCE](https://cloud.google.com/vpc/docs/firewalls)），請為 VPN 開啟 UDP 連接埠 500 和 4500。阿里雲使用者請參見 [#433](https://github.com/hwdsl2/setup-ipsec-vpn/issues/433)。

在 VPN 已連線時，客戶端設定為使用 [Google Public DNS](https://developers.google.com/speed/public-dns/)。如果偏好其他的網域解析服務，請參見[這裡](docs/advanced-usage-zh.md#使用其他的-dns-服务器)。

## 更新 Docker 映像

要更新 Docker 映像與容器，請先[下載](#下載)最新版本：

```bash
docker pull hwdsl2/ipsec-vpn-server
```

如果 Docker 映像已經是最新版本，你會看到提示：

```
Status: Image is up to date for hwdsl2/ipsec-vpn-server:latest
```

否則將會下載最新版本。要更新你的 Docker 容器，請先記下所有的 [VPN 登入資訊](#取得-vpn-登入資訊)。然後刪除 Docker 容器：`docker rm -f ipsec-vpn-server`。最後依照[如何使用本映像](#如何使用本映像)的說明重新建立它。

## 設定並使用 IKEv2 VPN

IKEv2 模式是比 IPsec/L2TP 和 IPsec/XAuth（"Cisco IPsec"）更好的連線模式，該模式不需要 IPsec PSK、使用者名稱或密碼。更多資訊請參見[這裡](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md)。

首先，查看容器的日誌以取得 IKEv2 設定資訊：

```bash
docker logs ipsec-vpn-server
```

**註：** 如果你找不到 IKEv2 設定資訊，IKEv2 可能未在容器中啟用。請嘗試依照[更新 Docker 映像](#更新-docker-映像)一節的說明更新 Docker 映像與容器。

在 IKEv2 安裝過程中會建立一個 IKEv2 客戶端（預設名稱為 `vpnclient`），並將其設定匯出到 **容器內** 的 `/etc/ipsec.d` 目錄下。你可以將設定檔複製到 Docker 主機：

```bash
# 查看容器內的 /etc/ipsec.d 目錄檔案
docker exec -it ipsec-vpn-server ls -l /etc/ipsec.d
# 範例：將一個客戶端設定檔從容器複製到 Docker 主機目前目錄
docker cp ipsec-vpn-server:/etc/ipsec.d/vpnclient.p12 ./
```

**下一步：** [設定你的裝置](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md)以使用 IKEv2 VPN。

<details>
<summary>
了解如何管理 IKEv2 客戶端。
</summary>

你可以使用輔助腳本管理 IKEv2 客戶端。示例如下。如需自訂客戶端選項，可以在不加入參數的情況下執行腳本。

```bash
# 新增一個客戶端（使用預設選項）
docker exec -it ipsec-vpn-server ikev2.sh --addclient [client name]
# 匯出一個已有客戶端的設定
docker exec -it ipsec-vpn-server ikev2.sh --exportclient [client name]
# 列出已有的客戶端
docker exec -it ipsec-vpn-server ikev2.sh --listclients
# 顯示使用說明
docker exec -it ipsec-vpn-server ikev2.sh -h
```

**註：** 如果你遇到錯誤 "executable file not found"，將上面的 `ikev2.sh` 改成 `/opt/src/ikev2.sh`。
</details>
<details>
<summary>
了解如何更改 IKEv2 伺服器位址。
</summary>

在某些情況下，你可能需要更改 IKEv2 伺服器位址。例如切換為使用網域名稱，或是在伺服器 IP 變更之後。要更改 IKEv2 伺服器位址，請先[在容器中執行 Bash shell](docs/advanced-usage-zh.md#在容器中运行-bash-shell)，然後[依照這裡的說明操作](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto-zh.md#更改-ikev2-服务器地址)。請注意，在你重新啟動 Docker 容器之前，容器日誌不會顯示新的 IKEv2 伺服器位址。
</details>
<details>
<summary>
移除 IKEv2 並使用自訂選項重新設定。
</summary>

在某些情況下，你可能需要移除 IKEv2 並使用自訂選項重新設定它。

**警告：** 這將**永久刪除**所有 IKEv2 設定（包括憑證與金鑰），並且**無法復原**！

**選項 1：** 使用輔助腳本移除 IKEv2 並重新設定。

請注意，這將覆蓋你在 `env` 檔案中指定的變數，例如 `VPN_DNS_NAME` 和 `VPN_CLIENT_NAME`，而且容器日誌將不再顯示 IKEv2 的最新資訊。

```bash
# 移除 IKEv2 並刪除所有 IKEv2 設定
docker exec -it ipsec-vpn-server ikev2.sh --removeikev2
# 使用自訂選項重新設定 IKEv2
docker exec -it ipsec-vpn-server ikev2.sh
```

**選項 2：** 移除 `ikev2-vpn-data` 並重新建立容器。

1. 在紙上記下所有的 [VPN 登入資訊](#取得-vpn-登入資訊)。
1. 刪除 Docker 容器：`docker rm -f ipsec-vpn-server`。
1. 刪除 `ikev2-vpn-data` 卷：`docker volume rm ikev2-vpn-data`。
1. 更新你的 `env` 檔案並加入自訂 IKEv2 選項，例如 `VPN_DNS_NAME` 和 `VPN_CLIENT_NAME`，然後重新建立容器。請參見[如何使用本映像](#如何使用本映像)。
</details>

## 進階用法

請參見[進階用法（簡體中文）](docs/advanced-usage-zh.md)。

- [使用其他 DNS 伺服器](docs/advanced-usage-zh.md#使用其他的-dns-服务器)
- [不啟用 privileged 模式執行](docs/advanced-usage-zh.md#不启用-privileged-模式运行)
- [選擇 VPN 模式](docs/advanced-usage-zh.md#选择-vpn-模式)
- [啟用 IKEv2 前向保密](docs/advanced-usage-zh.md#启用-ikev2-前向保密)
- [存取 Docker 主機上的其他容器](docs/advanced-usage-zh.md#访问-docker-主机上的其它容器)
- [指定 VPN 伺服器的公有 IP](docs/advanced-usage-zh.md#指定-vpn-服务器的公有-ip)
- [為 VPN 客戶端指定靜態 IP](docs/advanced-usage-zh.md#为-vpn-客户端指定静态-ip)
- [自訂 VPN 子網](docs/advanced-usage-zh.md#自定义-vpn-子网)
- [IPv6 支援](docs/advanced-usage-zh.md#ipv6-支持)
- [VPN 分流](docs/advanced-usage-zh.md#vpn-分流)
- [關於 host network 模式](docs/advanced-usage-zh.md#关于-host-network-模式)
- [啟用 Libreswan 日誌](docs/advanced-usage-zh.md#启用-libreswan-日志)
- [查看伺服器狀態](docs/advanced-usage-zh.md#查看服务器状态)
- [從原始碼建構](docs/advanced-usage-zh.md#从源代码构建)
- [在容器中執行 Bash shell](docs/advanced-usage-zh.md#在容器中运行-bash-shell)
- [綁定掛載 env 檔案](docs/advanced-usage-zh.md#绑定挂载-env-文件)
- [部署 Google BBR 壅塞控制](docs/advanced-usage-zh.md#部署-google-bbr-拥塞控制)

## 技術細節

需要執行以下兩個服務：`Libreswan (pluto)` 提供 IPsec VPN，`xl2tpd` 提供 L2TP 支援。

預設的 IPsec 設定支援以下協定：

* IPsec/L2TP with PSK
* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IKEv2

所需連接埠：`500/udp` 和 `4500/udp`（IPsec）

## 授權條款

**註：** 預先建構映像中的軟體元件（例如 Libreswan 和 xl2tpd）依其各自版權持有人所選擇的授權條款發布。對於任何預先建構映像的使用，使用者有責任確保其使用方式符合映像中所有軟體的相關授權條款。

版權所有 (C) 2016-2026 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)   
基於 [Thomas Sarlandie 的工作](https://github.com/sarfata/voodooprivacy)（版權所有 2012）

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)   
本專案採用 [Creative Commons 姓名標示-相同方式分享 3.0](http://creativecommons.org/licenses/by-sa/3.0/) 授權條款。   
必須署名：請在任何衍生作品中包含我的名字，並讓我知道你是如何改進它的！
