#!/usr/bin/env bash

set -euo pipefail

echo "::group::apt update"
apt update
apt dist-upgrade -y
echo "::endgroup::"

. /etc/lsb-release
ubuntu_major_version=${DISTRIB_RELEASE%%.*}

packages=(
    apt-file
    apt-utils
    automake
    bison
    curl
    flex
    git
    golang
    less
    libbz2-dev
    libicu-dev
    libncurses5-dev
    libreadline-dev
    libssl-dev
    libtool
    locales
    maven
    openjdk-8-jdk-headless
    pkg-config
    python3-dev
    python3-pip
    python3-venv
    python3-wheel
    rsync
    sudo
    unzip
    uuid-dev
    vim
    wget
    xz-utils
    groff-base
    libasan5
    libtsan0
)

if [[ $ubuntu_major_version -le 18 ]]; then
  packages+=(
    python-pip
    python-dev
    gcc-8
    g++-8
  )
fi

export LANG=en_US.UTF-8

echo "::group::Installing Ubuntu packages"
for package in "${packages[@]}"; do
  echo "Installing package: $package"
  apt install -y "$package"
done
echo "::endgroup::"

echo "::group::Installing LLVM/Clang packages"
bash /tmp/yb_docker_setup_scripts/ubuntu_install_llvm_packages.sh
echo "::endgroup::"

echo "::group::apt cleanup"
apt -y clean
apt -y autoremove
echo "::endgroup::"

locale-gen en_US.UTF-8

bash /tmp/yb_docker_setup_scripts/perform_common_setup.sh

rm -rf /tmp/yb_docker_setup_scripts
