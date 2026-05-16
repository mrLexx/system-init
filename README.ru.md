# Скрипт первичной настройки Ubuntu Server

[English version](README.md)

Скрипт выполняет первичную настройку системы, устанавливает набор утилит для разработки и администрирования, настраивает Docker, Go, SSH и создаёт привилегированного пользователя с доступом по SSH-ключу.

---

## Возможности

* Безопасный повторный запуск (idempotent setup)
* Интерактивный ввод переменных
* Поддержка optional `setup.env`
* Автоматическая установка пакетов
* Установка Docker Engine из официального репозитория
* Установка последней версии Go
* Усиление безопасности SSH
* Настройка приоритета IPv4
* Автоматическое создание пользователя

---

## Устанавливаемые пакеты

Базовые пакеты:

| Пакет                      | Назначение         |
| -------------------------- | ------------------ |
| net-tools                  | Сетевые утилиты    |
| ffmpeg                     | Работа с медиа     |
| curl                       | HTTP-клиент        |
| python3                    | Python             |
| ca-certificates            | SSL сертификаты    |
| gnupg                      | GPG                |
| direnv                     | Управление env     |
| bat                        | Улучшенный cat     |
| mc                         | Midnight Commander |
| traceroute                 | Диагностика сети   |
| jq                         | Работа с JSON      |
| wget                       | Загрузчик          |
| software-properties-common | add-apt-repository |

Дополнительно устанавливаются:

* Git (последняя версия из `git-core/ppa`)
* Go (последняя официальная версия)
* Docker Engine
* Docker Buildx
* Docker Compose plugin
* yt-dlp
* tuna

---

## Создание пользователя

Скрипт создаёт пользователя со следующими настройками:

* домашняя директория
* shell `/bin/bash`
* группы:

  * `sudo`
  * `docker`
* поддержка password hash
* passwordless sudo:

```text
ALL=(ALL) NOPASSWD:ALL
```

SSH-ключ автоматически добавляется в:

```text
~/.ssh/authorized_keys
```

Права выставляются автоматически:

```text
~/.ssh          -> 700
authorized_keys -> 600
```

---

## Настройки SSH

Скрипт отключает вход под root:

```text
PermitRootLogin no
```

После чего выполняется перезапуск SSH.

Аутентификация по SSH-ключам остаётся включённой.

PasswordAuthentication по умолчанию НЕ отключается.

---

## Настройка Docker

Docker устанавливается из официального репозитория Docker:

```text
https://download.docker.com/linux/ubuntu
```

Устанавливаются:

* docker-ce
* docker-ce-cli
* containerd.io
* docker-buildx-plugin
* docker-compose-plugin

Дополнительно скрипт:

* создаёт группу docker
* добавляет пользователя в docker
* пытается автоматически запустить Docker

---

## Установка Go

Последняя версия Go автоматически определяется через:

```text
https://go.dev/dl/?mode=json
```

Go устанавливается в:

```text
/usr/local/go
```

PATH добавляется через:

```text
/etc/profile.d/go.sh
```

---

## Приоритет IPv4

Скрипт включает приоритет IPv4 в:

```text
/etc/gai.conf
```

через настройку:

```text
precedence ::ffff:0:0/96  100
```

Это помогает в окружениях с нестабильным IPv6.

---

## Конфигурация

Переменные могут передаваться:

* через environment variables
* через `setup.env`
* интерактивно

Обязательные переменные:

| Переменная     | Назначение       |
| -------------- | ---------------- |
| NEW_USER       | Имя пользователя |
| USER_PASS_HASH | Hash пароля      |
| SSH_KEY        | SSH public key   |

Пример:

```bash
NEW_USER="devuser"
USER_PASS_HASH='$6$...'
SSH_KEY='ssh-ed25519 AAAA...'
```

---

## Использование

### Локальный запуск

```bash
sudo ./setup.sh
```

### Удалённый запуск

```bash
curl -fsSL https://raw.githubusercontent.com/mrLexx/system-init/main/setup.sh | sudo bash
```

---

## Примечания

* Только для Ubuntu-based систем
* Требуются root-права
* Поддерживает повторный запуск
* Предназначен для первичной настройки сервера
