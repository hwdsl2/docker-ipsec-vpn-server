[English](README.md) | [简体中文](README-zh.md) | [繁體中文](README-zh-Hant.md) | [Русский](README-ru.md)

# IPsec VPN сервер на Docker

[![Build Status](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml/badge.svg)](https://github.com/hwdsl2/docker-ipsec-vpn-server/actions/workflows/main-alpine.yml) [![GitHub Stars](docs/images/badges/github-stars.svg)](https://github.com/hwdsl2/docker-ipsec-vpn-server/stargazers) [![Docker Stars](docs/images/badges/docker-stars.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/) [![Docker Pulls](docs/images/badges/docker-pulls.svg)](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/)

Docker-образ для запуска сервера IPsec VPN с поддержкой IPsec/L2TP, Cisco IPsec и IKEv2.

Основан на Alpine 3.23 или Debian 12 с использованием [Libreswan](https://libreswan.org) (программное обеспечение IPsec VPN) и [xl2tpd](https://github.com/xelerance/xl2tpd) (демон L2TP).

IPsec VPN шифрует сетевой трафик, поэтому никто между вами и VPN-сервером не сможет перехватывать ваши данные во время их передачи через Интернет. Это особенно полезно при использовании незащищённых сетей, например в кофейнях, аэропортах или гостиничных номерах.

**Также доступно:** Docker-образы для [WireGuard](https://github.com/hwdsl2/docker-wireguard/blob/main/README-ru.md), [OpenVPN](https://github.com/hwdsl2/docker-openvpn/blob/main/README-ru.md), [Headscale](https://github.com/hwdsl2/docker-headscale/blob/main/README-ru.md) и [LiteLLM](https://github.com/hwdsl2/docker-litellm/blob/main/README-ru.md).

**[&raquo; :book: Книга: Privacy Tools in the Age of AI](docs/vpn-book.md) &nbsp;[Build Your Own VPN Server](docs/vpn-book.md)**

## Быстрый старт

Используйте эту команду для настройки сервера IPsec VPN в Docker:

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

Данные для входа в VPN будут сгенерированы случайным образом. См. раздел [Получение данных для входа в VPN](#получение-данных-для-входа-в-vpn).

В качестве альтернативы вы можете [настроить IPsec VPN без Docker](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/README-ru.md). Чтобы узнать больше о том, как использовать этот образ, прочитайте разделы ниже.

## Возможности

- Поддержка IKEv2 с мощными и быстрыми шифрами (например, AES-GCM)
- Генерация VPN-профилей для автоматической настройки устройств iOS, macOS и Android
- Поддержка Windows, macOS, iOS, Android, Chrome OS и Linux в качестве VPN-клиентов
- Включает вспомогательный скрипт для управления пользователями и сертификатами IKEv2

## Установка Docker

Сначала [установите Docker](https://docs.docker.com/engine/install/) на ваш Linux-сервер. Вы также можете использовать [Podman](https://podman.io) для запуска этого образа после [создания псевдонима](https://podman.io/whatis.html) для `docker`.

Продвинутые пользователи могут использовать этот образ на macOS с помощью [Docker for Mac](https://docs.docker.com/docker-for-mac/). Перед использованием режима IPsec/L2TP может потребоваться один раз перезапустить контейнер Docker с помощью `docker restart ipsec-vpn-server`. Этот образ не поддерживает Docker for Windows.

## Загрузка

Получите доверенную сборку из [реестра Docker Hub](https://hub.docker.com/r/hwdsl2/ipsec-vpn-server/):

```
docker pull hwdsl2/ipsec-vpn-server
```

В качестве альтернативы можно скачать из [Quay.io](https://quay.io/repository/hwdsl2/ipsec-vpn-server):

```
docker pull quay.io/hwdsl2/ipsec-vpn-server
docker image tag quay.io/hwdsl2/ipsec-vpn-server hwdsl2/ipsec-vpn-server
```

Поддерживаемые платформы: `linux/amd64`, `linux/arm64` и `linux/arm/v7`.

Продвинутые пользователи могут [собрать образ из исходного кода](docs/advanced-usage.md#build-from-source-code) на GitHub.

### Сравнение образов

Доступны два предварительно собранных образа. Образ на базе Alpine используется по умолчанию и имеет размер всего около ~19 MB.

|                   | На базе Alpine            | На базе Debian                 |
| ----------------- | ------------------------- | ------------------------------ |
| Имя образа        | hwdsl2/ipsec-vpn-server   | hwdsl2/ipsec-vpn-server:debian |
| Сжатый размер     | ~ 19 MB                   | ~ 62 MB                        |
| Базовый образ     | Alpine Linux 3.23         | Debian Linux 12                |
| Платформы         | amd64, arm64, arm/v7      | amd64, arm64, arm/v7           |
| Версия Libreswan  | 5.3                       | 5.3                            |
| IPsec/L2TP        | ✅                         | ✅                              |
| Cisco IPsec       | ✅                         | ✅                              |
| IKEv2             | ✅                         | ✅                              |

**Примечание:** Чтобы использовать образ на базе Debian, замените каждое `hwdsl2/ipsec-vpn-server` на `hwdsl2/ipsec-vpn-server:debian` в этом README. В настоящее время эти образы несовместимы с системами Synology NAS.

<details>
<summary>
Я хочу использовать более старую версию Libreswan 4.
</summary>

Обычно рекомендуется использовать последнюю версию [Libreswan](https://libreswan.org/) 5, которая является версией по умолчанию в этом проекте. Однако если вы хотите использовать более старую версию Libreswan 4, вы можете собрать Docker-образ из исходного кода:

```
git clone https://github.com/hwdsl2/docker-ipsec-vpn-server
cd docker-ipsec-vpn-server
# Указать версию Libreswan 4
sed -i 's/SWAN_VER=5\..*/SWAN_VER=4.15/' Dockerfile Dockerfile.debian
# Сборка образа на базе Alpine
docker build -t hwdsl2/ipsec-vpn-server .
# Сборка образа на базе Debian
docker build -f Dockerfile.debian -t hwdsl2/ipsec-vpn-server:debian .
```
</details>

## Как использовать этот образ

### Переменные окружения

**Примечание:** Все переменные для этого образа являются необязательными, что означает, что вам не нужно указывать ни одну переменную — и вы сможете получить работающий сервер IPsec VPN «из коробки»! Для этого создайте пустой файл `env` с помощью `touch vpn.env`, а затем перейдите к следующему разделу.

Этот Docker-образ использует следующие переменные, которые можно объявить в файле `env` (см. [пример](vpn.env.example)):

```
VPN_IPSEC_PSK=your_ipsec_pre_shared_key
VPN_USER=your_vpn_username
VPN_PASSWORD=your_vpn_password
```

Это создаст учетную запись пользователя для входа в VPN, которую можно использовать на нескольких ваших устройствах[\*](#важные-замечания). IPsec PSK (предварительно общий ключ) задаётся переменной окружения `VPN_IPSEC_PSK`. Имя пользователя VPN задаётся в `VPN_USER`, а пароль VPN указывается в `VPN_PASSWORD`.

Поддерживаются дополнительные пользователи VPN, и их можно при желании объявить в вашем файле `env` следующим образом. Имена пользователей и пароли должны быть разделены пробелами, а имена пользователей не могут повторяться. Все пользователи VPN будут использовать один и тот же IPsec PSK.

```
VPN_ADDL_USERS=additional_username_1 additional_username_2
VPN_ADDL_PASSWORDS=additional_password_1 additional_password_2
```

Переменные выше используются только для режимов IPsec/L2TP и IPsec/XAuth («Cisco IPsec»). Для IKEv2 см. [Настройка и использование IKEv2 VPN](#настройка-и-использование-ikev2-vpn).

**Примечание:** В файле `env` НЕ помещайте `""` или `''` вокруг значений и не добавляйте пробелы вокруг `=`. НЕ используйте внутри значений следующие специальные символы: `\ " '`. Надёжный IPsec PSK должен состоять как минимум из 20 случайных символов.

**Примечание:** Если вы измените файл `env` после того, как Docker-контейнер уже создан, необходимо удалить и создать контейнер заново, чтобы изменения вступили в силу. См. раздел [Обновление Docker-образа](#обновление-docker-образа).

### Дополнительные переменные окружения

Продвинутые пользователи могут при желании указать DNS-имя, имя клиента и/или собственные DNS-серверы.

<details>
<summary>
Узнайте, как указать DNS-имя, имя клиента и/или собственные DNS-серверы.
</summary>

Продвинутые пользователи могут при желании указать DNS-имя для адреса сервера IKEv2. DNS-имя должно быть полным доменным именем (FQDN). Пример:

```
VPN_DNS_NAME=vpn.example.com
```

Вы можете указать имя для первого клиента IKEv2. Используйте только одно слово, без специальных символов, кроме `-` и `_`. По умолчанию используется `vpnclient`, если имя не указано.

```
VPN_CLIENT_NAME=your_client_name
```

По умолчанию клиенты используют [Google Public DNS](https://developers.google.com/speed/public-dns/) при активном VPN. Вы можете указать собственные DNS-серверы для всех режимов VPN. Пример:

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

Для получения дополнительных сведений и списка популярных публичных DNS-провайдеров см. [Использование альтернативных DNS-серверов](docs/advanced-usage.md).

По умолчанию пароль не требуется при импорте конфигурации клиента IKEv2. Вы можете защитить файлы конфигурации клиента случайным паролем.

```
VPN_PROTECT_CONFIG=yes
```

**Примечание:** Переменные выше не влияют на режим IKEv2, если IKEv2 уже настроен в Docker-контейнере. В этом случае вы можете удалить IKEv2 и настроить его снова с пользовательскими параметрами. См. [Настройка и использование IKEv2 VPN](#настройка-и-использование-ikev2-vpn).
</details>

### Запуск сервера IPsec VPN

Создайте новый Docker-контейнер из этого образа (замените `./vpn.env` на ваш собственный файл `env`):

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

В этой команде используется параметр `-v` команды `docker run`, чтобы создать новый [Docker volume](https://docs.docker.com/storage/volumes/) с именем `ikev2-vpn-data` и смонтировать его в `/etc/ipsec.d` внутри контейнера. Данные, связанные с IKEv2 (такие как сертификаты и ключи), будут сохраняться в этом томе. Позже, если вам потребуется заново создать Docker-контейнер, просто укажите тот же том снова.

Рекомендуется включить IKEv2 при использовании этого образа. Однако если вы предпочитаете не использовать IKEv2 и подключаться к VPN только через режимы IPsec/L2TP и IPsec/XAuth («Cisco IPsec»), удалите первый параметр `-v` из команды `docker run`, приведённой выше.

**Примечание:** Продвинутые пользователи также могут [запускать контейнер без привилегированного режима](docs/advanced-usage.md#run-without-privileged-mode).

### Получение данных для входа в VPN

Если вы не указали файл `env` в команде `docker run` выше, значение `VPN_USER` по умолчанию будет `vpnuser`, а `VPN_IPSEC_PSK` и `VPN_PASSWORD` будут сгенерированы случайным образом. Чтобы получить их, просмотрите журналы контейнера:

```
docker logs ipsec-vpn-server
```

Найдите в выводе следующие строки:

```
Connect to your new VPN with these details:

Server IP: your_vpn_server_ip
IPsec PSK: your_ipsec_pre_shared_key
Username: your_vpn_username
Password: your_vpn_password
```

Вывод также будет содержать сведения для режима IKEv2, если он включён.

(Необязательно) Сохраните сгенерированные данные для входа в VPN (если они есть) в текущий каталог:

```
docker cp ipsec-vpn-server:/etc/ipsec.d/vpn-gen.env ./
```

## Следующие шаги

*Прочитать на других языках: [English](README.md#next-steps), [简体中文](README-zh.md#下一步), [繁體中文](README-zh-Hant.md#下一步), [Русский](README-ru.md#следующие-шаги).*

Настройте ваш компьютер или устройство для использования VPN. Пожалуйста, обратитесь к следующим инструкциям (на английском языке):

**[Настройка и использование IKEv2 VPN (рекомендуется)](#настройка-и-использование-ikev2-vpn)**

**[Настройка клиентов IPsec/L2TP VPN](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md)**

**[Настройка клиентов IPsec/XAuth («Cisco IPsec»)](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md)**

**Прочитайте [:book: книгу о VPN](docs/vpn-book.md), чтобы получить доступ к [дополнительному контенту](https://ko-fi.com/post/Support-this-project-and-get-access-to-supporter-o-O5O7FVF8J).**

Наслаждайтесь собственным VPN! :sparkles::tada::rocket::sparkles:

## Важные замечания

**Пользователи Windows**: для режима IPsec/L2TP требуется [одноразовое изменение реестра](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md#windows-error-809), если VPN-сервер или клиент находится за NAT (например, домашним роутером).

Одна и та же учетная запись VPN может использоваться на нескольких ваших устройствах. Однако из-за ограничения IPsec/L2TP, если вы хотите подключить несколько устройств из-за одного NAT (например, домашнего роутера), необходимо использовать режим [IKEv2](#настройка-и-использование-ikev2-vpn) или [IPsec/XAuth](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md).

Если вы хотите добавить, изменить или удалить учетные записи пользователей VPN, сначала обновите файл `env`, затем удалите и заново создайте Docker-контейнер, следуя инструкциям из [следующего раздела](#обновление-docker-образа). Продвинутые пользователи могут использовать [bind mount](docs/advanced-usage.md#bind-mount-the-env-file) для файла `env`.

Для серверов с внешним файрволом (например, [EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)/[GCE](https://cloud.google.com/vpc/docs/firewalls)) откройте UDP-порты 500 и 4500 для VPN. Пользователям Aliyun см. [#433](https://github.com/hwdsl2/setup-ipsec-vpn/issues/433).

Клиенты настроены использовать [Google Public DNS](https://developers.google.com/speed/public-dns/) при активном VPN. Если вы предпочитаете другого DNS-провайдера, прочитайте [этот раздел](docs/advanced-usage.md#use-alternative-dns-servers).

## Использование docker-compose

```bash
cp vpn.env.example vpn.env
# При необходимости отредактируйте vpn.env, затем:
docker compose up -d
docker logs ipsec-vpn-server
```

Пример `docker-compose.yml` (уже включён):

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

## Обновление Docker-образа

Чтобы обновить Docker-образ и контейнер, сначала [загрузите](#загрузка) последнюю версию:

```
docker pull hwdsl2/ipsec-vpn-server
```

Если Docker-образ уже обновлён, вы увидите:

```
Status: Image is up to date for hwdsl2/ipsec-vpn-server:latest
```

В противном случае будет загружена последняя версия. Чтобы обновить Docker-контейнер, сначала запишите все ваши [данные для входа в VPN](#получение-данных-для-входа-в-vpn). Затем удалите контейнер Docker с помощью `docker rm -f ipsec-vpn-server`. После этого создайте его заново, следуя инструкциям из раздела [Как использовать этот образ](#как-использовать-этот-образ).

## Настройка и использование IKEv2 VPN

Режим IKEv2 имеет преимущества по сравнению с IPsec/L2TP и IPsec/XAuth («Cisco IPsec») и не требует IPsec PSK, имени пользователя или пароля. Подробнее можно прочитать [здесь](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md).

Сначала проверьте журналы контейнера, чтобы увидеть сведения о IKEv2:

```bash
docker logs ipsec-vpn-server
```

**Примечание:** Если вы не можете найти сведения о IKEv2, возможно, IKEv2 не включён в контейнере. Попробуйте обновить Docker-образ и контейнер, следуя инструкциям из раздела [Обновление Docker-образа](#обновление-docker-образа).

Во время настройки IKEv2 создаётся клиент IKEv2 (с именем по умолчанию `vpnclient`), а его конфигурация экспортируется в `/etc/ipsec.d` **внутри контейнера**. Чтобы скопировать файл(ы) конфигурации на Docker-хост:

```
# Проверить содержимое /etc/ipsec.d в контейнере
docker exec -it ipsec-vpn-server ls -l /etc/ipsec.d
# Пример: копирование файла конфигурации клиента из контейнера
# в текущий каталог на Docker-хосте
docker cp ipsec-vpn-server:/etc/ipsec.d/vpnclient.p12 ./
```

**Следующие шаги:** [Настройте ваши устройства](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md) для использования IKEv2 VPN.

<details>
<summary>
Узнайте, как управлять клиентами IKEv2.
</summary>

Вы можете управлять клиентами IKEv2 с помощью вспомогательного скрипта. Ниже приведены примеры. Чтобы настроить параметры клиента, запустите скрипт без аргументов.

```bash
# Добавить нового клиента (с параметрами по умолчанию)
docker exec -it ipsec-vpn-server ikev2.sh --addclient [имя клиента]
# Экспортировать конфигурацию для существующего клиента
docker exec -it ipsec-vpn-server ikev2.sh --exportclient [имя клиента]
# Показать список существующих клиентов
docker exec -it ipsec-vpn-server ikev2.sh --listclients
# Показать справку
docker exec -it ipsec-vpn-server ikev2.sh -h
```

**Примечание:** Если возникает ошибка «executable file not found», замените `ikev2.sh` выше на `/opt/src/ikev2.sh`.
</details>
<details>
<summary>
Узнайте, как изменить адрес сервера IKEv2.
</summary>

В некоторых случаях может потребоваться изменить адрес сервера IKEv2. Например, чтобы перейти на использование DNS-имени или после изменения IP-адреса сервера. Чтобы изменить адрес сервера IKEv2, сначала [откройте bash-оболочку внутри контейнера](docs/advanced-usage.md#bash-shell-inside-container), затем [следуйте этим инструкциям](https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md#change-ikev2-server-address). Обратите внимание, что журналы контейнера не будут показывать новый адрес сервера IKEv2, пока вы не перезапустите Docker-контейнер.
</details>
<details>
<summary>
Удаление IKEv2 и повторная настройка с пользовательскими параметрами.
</summary>

В некоторых случаях может потребоваться удалить IKEv2 и настроить его заново с пользовательскими параметрами.

**Предупреждение:** Вся конфигурация IKEv2, включая сертификаты и ключи, будет **безвозвратно удалена**. Это **нельзя отменить**!

**Вариант 1:** Удалить IKEv2 и настроить его снова с помощью вспомогательного скрипта.

Обратите внимание, что это переопределит переменные, указанные в файле `env`, такие как `VPN_DNS_NAME` и `VPN_CLIENT_NAME`, а журналы контейнера больше не будут показывать актуальную информацию для IKEv2.

```bash
# Удалить IKEv2 и удалить всю конфигурацию IKEv2
docker exec -it ipsec-vpn-server ikev2.sh --removeikev2
# Настроить IKEv2 снова с пользовательскими параметрами
docker exec -it ipsec-vpn-server ikev2.sh
```

**Вариант 2:** Удалить `ikev2-vpn-data` и создать контейнер заново.

1. Запишите все ваши [данные для входа в VPN](#получение-данных-для-входа-в-vpn).
1. Удалите Docker-контейнер: `docker rm -f ipsec-vpn-server`.
1. Удалите том `ikev2-vpn-data`: `docker volume rm ikev2-vpn-data`.
1. Обновите файл `env` и добавьте пользовательские параметры IKEv2, такие как `VPN_DNS_NAME` и `VPN_CLIENT_NAME`, затем создайте контейнер заново. См. раздел [Как использовать этот образ](#как-использовать-этот-образ).
</details>

## Расширенное использование

См. [Расширенное использование](docs/advanced-usage.md) (на английском языке).

- [Использование альтернативных DNS-серверов](docs/advanced-usage.md#use-alternative-dns-servers)
- [Запуск без привилегированного режима](docs/advanced-usage.md#run-without-privileged-mode)
- [Выбор режимов VPN](docs/advanced-usage.md#select-vpn-modes)
- [Доступ к другим контейнерам на Docker-хосте](docs/advanced-usage.md#access-other-containers-on-the-docker-host)
- [Указание публичного IP-адреса VPN-сервера](docs/advanced-usage.md#specify-vpn-servers-public-ip)
- [Назначение статических IP-адресов клиентам VPN](docs/advanced-usage.md#assign-static-ips-to-vpn-clients)
- [Настройка подсетей VPN](docs/advanced-usage.md#customize-vpn-subnets)
- [Поддержка IPv6](docs/advanced-usage.md#ipv6-support)
- [Раздельная маршрутизация (Split tunneling)](docs/advanced-usage.md#split-tunneling)
- [О режиме сетевого хоста](docs/advanced-usage.md#about-host-network-mode)
- [Включение журналов Libreswan](docs/advanced-usage.md#enable-libreswan-logs)
- [Проверка состояния сервера](docs/advanced-usage.md#check-server-status)
- [Сборка из исходного кода](docs/advanced-usage.md#build-from-source-code)
- [Bash-оболочка внутри контейнера](docs/advanced-usage.md#bash-shell-inside-container)
- [Bind mount файла env](docs/advanced-usage.md#bind-mount-the-env-file)
- [Развёртывание алгоритма управления перегрузкой Google BBR](docs/advanced-usage.md#deploy-google-bbr-congestion-control)

## Технические детали

Запущены два сервиса: `Libreswan (pluto)` для IPsec VPN и `xl2tpd` для поддержки L2TP.

Конфигурация IPsec по умолчанию поддерживает:

* IPsec/L2TP с PSK
* IKEv1 с PSK и XAuth («Cisco IPsec»)
* IKEv2

Необходимые порты: `500/udp` и `4500/udp` (IPsec)

## Лицензия

**Примечание:** Компоненты программного обеспечения внутри предварительно собранного образа (например, Libreswan и xl2tpd) распространяются по лицензиям, выбранным их правообладателями. Как и в случае использования любого готового образа, пользователь образа несёт ответственность за то, чтобы использование этого образа соответствовало всем применимым лицензиям для программного обеспечения, содержащегося внутри.

Copyright (C) 2016-2026 [Lin Song](https://github.com/hwdsl2) [![View my profile on LinkedIn](https://static.licdn.com/scds/common/u/img/webpromo/btn_viewmy_160x25.png)](https://www.linkedin.com/in/linsongui)  
Основано на [работе Thomas Sarlandie](https://github.com/sarfata/voodooprivacy) (Copyright 2012)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/3.0/88x31.png)](http://creativecommons.org/licenses/by-sa/3.0/)  
Эта работа распространяется по лицензии [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/)  
Требуется указание авторства: пожалуйста, указывайте моё имя в любых производных работах и сообщайте мне, как вы её улучшили!
