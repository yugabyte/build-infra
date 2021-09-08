#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

packages=(
  # The default GCC version on OpenSUSE Leap 15 is GCC 7.
  gcc
  gcc-c++
  gcc8
  gcc8-c++
  gcc9
  gcc9-c++
  gcc10
  gcc10-c++
  git
  vim
  wget
  curl
  sudo
  tar
  gzip
  pigz
  bzip2
  make
  autoconf
  automake
  libtool
  zlib-devel
  openssl
  libopenssl-devel
  libffi-devel
  which
  rsync
  patch
  cmake
  ninja
  unzip
  byacc
  ncurses-devel
  java-1_8_0-openjdk
  # groff provides the soelim program needed by openldap build.
  groff
)

# -------------------------------------------------------------------------------------------------
# Main script
# -------------------------------------------------------------------------------------------------

yb_zypper_install_packages_separately "${packages[@]}"
yb_perform_os_independent_steps
yb_remove_build_infra_scripts

zypper clean