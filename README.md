# Ubuntu Server Bootstrap Script

[README на русском](README.ru.md)

The script performs initial system setup, installs common development and administration tools, configures Docker, Go, SSH security, and creates a privileged user with SSH access.

---

## Features

* Safe repeated execution (idempotent setup)
* Interactive variable input support
* Optional `setup.env` configuration file
* Automatic package installation
* Docker Engine installation from the official Docker repository
* Latest Go installation from official sources
* SSH hardening
* IPv4 priority configuration
* Automatic privileged user creation

---

## Installed Packages

The script installs the following base packages:

| Package                    | Purpose                      |
| -------------------------- | ---------------------------- |
| net-tools                  | Legacy networking tools      |
| ffmpeg                     | Media processing             |
| curl                       | HTTP client                  |
| python3                    | Python runtime               |
| ca-certificates            | SSL certificates             |
| gnupg                      | GPG support                  |
| direnv                     | Environment management       |
| bat                        | Improved `cat`               |
| mc                         | Midnight Commander           |
| traceroute                 | Network diagnostics          |
| jq                         | JSON processor               |
| wget                       | Downloader                   |
| software-properties-common | `add-apt-repository` support |

Additional software:

* Git (latest version from `git-core/ppa`)
* Go (latest official release)
* Docker Engine
* Docker Buildx
* Docker Compose plugin
* yt-dlp
* tuna

---

## User Creation

The script creates a user with the following configuration:

* Home directory
* Bash shell
* Membership in:

  * `sudo`
  * `docker`
* Password hash support
* Passwordless sudo:

```text
ALL=(ALL) NOPASSWD:ALL
```

SSH public key is automatically added to:

```text
~/.ssh/authorized_keys
```

Permissions are configured automatically:

```text
~/.ssh          -> 700
authorized_keys -> 600
```

---

## SSH Configuration

The script hardens SSH configuration by disabling root login:

```text
PermitRootLogin no
```

Then SSH service is restarted.

Public key authentication remains enabled.

Password authentication is NOT disabled by default.

---

## Docker Configuration

Docker is installed from the official Docker repository:

```text
https://download.docker.com/linux/ubuntu
```

Installed components:

* docker-ce
* docker-ce-cli
* containerd.io
* docker-buildx-plugin
* docker-compose-plugin

The script also:

* creates docker group if missing
* adds the user to docker group
* attempts to start Docker automatically

---

## Go Installation

The latest Go version is fetched dynamically from:

```text
https://go.dev/dl/?mode=json
```

Go is installed into:

```text
/usr/local/go
```

PATH configuration is added to:

```text
/etc/profile.d/go.sh
```

---

## IPv4 Priority

The script enables IPv4 priority in:

```text
/etc/gai.conf
```

by enabling or adding:

```text
precedence ::ffff:0:0/96  100
```

This improves compatibility in environments where IPv6 connectivity is unreliable.

---

## Configuration

Variables may be provided either:

* through environment variables
* through `setup.env`
* interactively during execution

Required variables:

| Variable       | Description    |
| -------------- | -------------- |
| NEW_USER       | Username       |
| USER_PASS_HASH | Password hash  |
| SSH_KEY        | SSH public key |

Example:

```bash
NEW_USER="devuser"
USER_PASS_HASH='$6$...'
SSH_KEY='ssh-ed25519 AAAA...'
```

---

## Usage

### Local execution

```bash
sudo ./setup.sh
```

### Remote execution

```bash
curl -fsSL https://raw.githubusercontent.com/mrLexx/system-init/main/setup.sh | sudo bash
```

---

## Notes

* Ubuntu-based systems only
* Requires root privileges
* Safe for repeated execution
* Intended for fresh server provisioning
