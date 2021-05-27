#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

yb_apt_get_dist_upgrade
yb_debian_init_locale

packages=(
    apt-file
    apt-utils
    automake
    bison
    curl
    flex
    git
    golang
    groff-base
    less
    libasan5
    libbz2-dev
    libicu-dev
    libncurses5-dev
    libreadline-dev
    libssl-dev
    libtool
    libtsan0
    locales
    maven
    pkg-config
    python3-dev
    python3-pip
    python3-venv
    python3-wheel
    rsync
    sudo
    tzdata
    unzip
    uuid-dev
    vim
    wget
    xz-utils
)

export DEBIAN_FRONTEND=noninteractive

yb_start_group "Installing Debian packages"
for package in "${packages[@]}"; do
  echo "------------------------------------------------------------------------------------------"
  echo "Installing package $package and its dependencies"
  echo "------------------------------------------------------------------------------------------"
  echo
  apt-get install -y "$package"
  echo
  echo "------------------------------------------------------------------------------------------"
  echo "Finished installing package $package and its dependencies"
  echo "------------------------------------------------------------------------------------------"
  echo
done
yb_end_group

yb_start_group "Installing LLVM/Clang packages"
bash "$yb_build_infra_scripts_dir/debian_install_llvm_packages.sh"
yb_end_group

yb_apt_cleanup

yb_remove_build_infra_scripts
