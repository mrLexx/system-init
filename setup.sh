#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    echo "Error: this script must be run with bash, not sh" >&2
    exit 1
fi

# Прерывать выполнение при ошибках
set -euo pipefail

norm="$(printf '\033[0m')" #returns to "normal"
bold="$(printf '\033[1m')" #set bold
red="$(printf '\033[31m')" #set red
gray="$(printf '\033[90m')" #set red
boldred="$(printf '\033[1;31m')" #set bold, and set red.

error_echo ()
{
    local default_msg=""

    local message=${1:-$default_msg}
    echo -e "\033[31m    $message\033[0m"
    tput sgr0
    return
}


head_echo ()
{
    local default_msg=""

    local message=${1:-$default_msg}
    echo -e "\033[32m$message\033[0m"
    tput sgr0
    return
}

head2_echo ()
{
    local default_msg=""

    local message=${1:-$default_msg}
    echo -e "\033[32m--- $message\033[0m"
    tput sgr0
    return
}

simple_echo ()
{
    local default_msg=""

    local message=${1:-$default_msg}
    echo -e "\033[32m    $message\033[0m"
    tput sgr0
    return
}


ask_var() {
    local var_name="$1"
    local prompt="$2"
    local secret="${3:-false}"

    if [[ -n "${!var_name:-}" ]]; then
        return 0
    fi

    if [[ "$secret" == "true" ]]; then
        read -r -s -p "$prompt: " "$var_name" < /dev/tty
        echo
    else
        read -r -p "$prompt: " "$var_name" < /dev/tty
    fi

    if [[ -z "${!var_name:-}" ]]; then
        error_echo "Error: $var_name cannot be empty"
        exit 1
    fi
}

ENV_FILE="${ENV_FILE:-./setup.env}"

if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
fi

ask_var NEW_USER "Enter username"
ask_var USER_PASS_HASH "Enter password hash" true
ask_var SSH_KEY "Enter SSH public key"

head_echo "### NEW_USER=$NEW_USER"

head_echo "### Waiting for APT locks to be released"
locks=(/var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock)
for l in "${locks[@]}"; do
    while fuser "$l" >/dev/null 2>&1; do 
        simple_echo "Waiting for $l..."; sleep 2; 
    done
done

head_echo "### Updating system and installing dependencies"
export DEBIAN_FRONTEND=noninteractive
apt-get update
packages=(net-tools ffmpeg curl python3 ca-certificates gnupg direnv bat mc traceroute jq wget software-properties-common)

to_install=()
for pkg in "${packages[@]}"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || to_install+=("$pkg")
done

if ((${#to_install[@]})); then
    apt-get install -y "${to_install[@]}"
else
    simple_echo "All basic packages are already installed"
fi


head_echo "### Creating user $NEW_USER"

getent group docker >/dev/null || groupadd docker

if ! id "$NEW_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -p "$USER_PASS_HASH" -G sudo,docker "$NEW_USER"
fi

sudoers_file="/etc/sudoers.d/90-$NEW_USER"
if [[ ! -f "$sudoers_file" ]]; then
    echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "$sudoers_file"
    chmod 440 "$sudoers_file"
fi

# ssh key
auth="/home/$NEW_USER/.ssh/authorized_keys"
mkdir -p "/home/$NEW_USER/.ssh"

if [[ ! -f "$auth" ]] || ! grep -qxF "$SSH_KEY" "$auth"; then
    echo "$SSH_KEY" >> "$auth"
fi

chown -R "$NEW_USER:$NEW_USER" "/home/$NEW_USER/.ssh"
chmod 700 "/home/$NEW_USER/.ssh"
chmod 600 "$auth"


head_echo "### Installing additional applications"

simple_echo "yt-dlp "
if ! command -v yt-dlp >/dev/null 2>&1; then
    curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
    chmod a+rx /usr/local/bin/yt-dlp
    cp /usr/local/bin/yt-dlp /bin/yt-dlp
fi

simple_echo "tuna"
if ! command -v tuna >/dev/null 2>&1; then
    curl -sSLf https://get.tuna.am | sh
fi

simple_echo "git"
if ! grep -Rqs "ppa.launchpadcontent.net/git-core/ppa" /etc/apt/sources.list /etc/apt/sources.list.d; then
    add-apt-repository -y ppa:git-core/ppa
    apt-get update
fi
dpkg -s git >/dev/null 2>&1 || apt-get install -y git

simple_echo "go"
LATEST_GO="$(curl -s 'https://go.dev/dl/?mode=json' | jq -r '.[0].version')"

current_go=""
if [[ -x /usr/local/go/bin/go ]]; then
    current_go="$(/usr/local/go/bin/go version | awk '{print $3}')"
fi

if [[ "$current_go" != "$LATEST_GO" ]]; then
    rm -rf /usr/local/go
    wget "https://go.dev/dl/${LATEST_GO}.linux-amd64.tar.gz"
    tar -C /usr/local -xzf "${LATEST_GO}.linux-amd64.tar.gz"
    rm "${LATEST_GO}.linux-amd64.tar.gz"
fi

if [[ ! -f /etc/profile.d/go.sh ]]; then
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
fi

head_echo "### Installing Docker Engine (Official Repo)"
# Add Docker's official GPG key:
if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
fi



# Add the repository to Apt sources:
if [[ ! -f /etc/apt/sources.list.d/docker.sources ]]; then
    tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    apt-get update
fi

docker_packages=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
to_install=()
for pkg in "${docker_packages[@]}"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || to_install+=("$pkg")
done
if ((${#to_install[@]})); then
    apt-get install -y "${to_install[@]}"
fi


if ! systemctl is-active --quiet docker; then
    error_echo "Docker is not running. Trying to start..."
    # Starting Docker
    sudo systemctl start docker
   
    # Waiting for startup to ensure it is up and running
    sleep 2
    
    if systemctl is-active --quiet docker; then
        simple_echo "Docker started successfully"
    else
        error_echo "Error: Failed to start Docker"
    fi
else
    simple_echo "Docker is already running"
fi



head_echo "### Configuring SSH security"

if ! grep -qE '^PermitRootLogin no$' /etc/ssh/sshd_config; then
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
    systemctl restart ssh
else
    simple_echo "SSH is already configured"
fi

head_echo "### IPv4 priority"

FILE="/etc/gai.conf"

if grep -qE '^[[:space:]]*#[[:space:]]*precedence[[:space:]]+::ffff:0:0/96[[:space:]]+100' "$FILE"; then
    sed -i 's|^[[:space:]]*#[[:space:]]*\(precedence[[:space:]]\+::ffff:0:0/96[[:space:]]\+100\)|\1|' "$FILE"
    simple_echo "IPv4 priority is enabled"
elif grep -qE '^[[:space:]]*precedence[[:space:]]+::ffff:0:0/96[[:space:]]+100' "$FILE"; then
    simple_echo "IPv4 priority is already enabled"
else
    echo 'precedence ::ffff:0:0/96  100' >> "$FILE"
    simple_echo "IPv4 priority added"
fi

head_echo "Setup completed!"
head_echo "You can now log in: ssh $NEW_USER@$(hostname -I | awk '{print $1}')"
