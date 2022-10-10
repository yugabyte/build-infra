#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

packages=(
  apt-file
  apt-utils
  apt-transport-https
  automake
  bazel
  bison
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

yb_debian_configure_and_install_packages "${packages[@]}"
yb_perform_os_independent_steps
yb_remove_build_infra_scripts
