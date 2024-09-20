#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

# shellcheck disable=SC1091
. /etc/lsb-release
ubuntu_major_version=${DISTRIB_RELEASE%%.*}

set_ubuntu_packages() {
  ubuntu_packages=(
    apt-file
    apt-utils
    automake
    bison
    cmake
    curl
    flex
    git
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
    ninja-build
    openjdk-8-jdk-headless
    patchelf
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
  local gcc_versions=()
  if [[ $ubuntu_major_version -eq 20 ]]; then
    gcc_versions+=( 10 )
  fi

  if [[ $ubuntu_major_version -ge 22 ]]; then
    gcc_versions+=( 11 12  )
  fi
  if [[ $ubuntu_major_version -ge 24 ]]; then
    gcc_versions+=( 13 )
  fi
  for gcc_version in "${gcc_versions[@]}"; do
    # Apparently apt interprets the argument as a regex, which could result in matching Clang
    # for GCC (or there might be some internal logic for that). Let's quote the pluses for safety.
    packages+=(
      "gcc-${gcc_version}"
      "g[+][+]-${gcc_version}"
    )
  done
}

set_ubuntu_packages
yb_debian_configure_and_install_packages "${ubuntu_packages[@]}"
yb_perform_universal_steps
yb_remove_build_infra_scripts
