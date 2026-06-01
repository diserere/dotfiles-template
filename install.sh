#!/usr/bin/env bash

# Script to add basic dev packets on Ubuntu fresh install

sudo apt update && sudo apt upgrade
sudo apt install \
    build-essential \
    curl \
    git \
    gnome-shell-extension-manager \
    gnome-tweaks \
    gparted \
    htop \
    jq \
    meld \
    python3-venv \
    ssh \
    tree \
    unrar \
    vim \
    wget \
&& echo "=== Installing APT packages is done."
echo

# Chrome install
read -p "Install Chrome? y/N: " response
if [[ "${response,,}" =~ ^(y|yes)$ ]]; then
    echo "Starting Chrome installation..."
    wget -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install /tmp/google-chrome-stable_current_amd64.deb && rm /tmp/google-chrome-stable_current_amd64.deb
else
    echo "Chrome Install skipped."
fi

echo "You could manually install following packages:"
echo "- Github CLI: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian"
echo "- Docker Engine: https://docs.docker.com/engine/install/ubuntu/"
echo "- VScode: Use App Center"

echo "========================"
echo "All done! Have a nice work )"
