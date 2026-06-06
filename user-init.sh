#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    echo "Error: this script must be run with bash, not sh" >&2
    exit 1
fi

set -euo pipefail

norm="$(printf '\033[0m')" #returns to "normal"
bold="$(printf '\033[1m')" #set bold
red="$(printf '\033[31m')" #set red
gray="$(printf '\033[90m')" #set red
boldred="$(printf '\033[1;31m')" #set bold, and set red.

head_echo ()
{
    local default_msg=""

    local message=${1:-$default_msg}
    echo -e "\033[32m$message\033[0m"
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

head_echo "### Configuring environment"

simple_echo ".bashrc.d"

BASHRC="$HOME/.bashrc"

\rm -rf -- "$HOME/.bashrc.d"
\mkdir -p "$HOME/.bashrc.d"

BLOCK='
if [[ -d "$HOME/.bashrc.d" ]]; then
    for file in "$HOME"/.bashrc.d/*.sh; do
        [[ -r "$file" ]] && source "$file"
    done
fi
'

if ! grep -q '\.bashrc\.d' "$BASHRC"; then
    printf '\n%s\n' "$BLOCK" >> "$BASHRC"
    simple_echo "~/.bashrc.d processing added to $BASHRC"
else
    simple_echo "~/.bashrc.d processing is already configured in $BASHRC"
fi

simple_echo "Initializing environment"

ARCHIVE="$HOME/user-settings-archive.tar.gz"

if [[ -f "$ARCHIVE" ]]; then
    tar -xzvf "$ARCHIVE"
else
    becho "Archive not found: $ARCHIVE"
fi

head_echo "Init completed!"
