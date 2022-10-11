#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

# shellcheck disable=SC1091
. /etc/lsb-release
ubuntu_major_version=${DISTRIB_RELEASE%%.*}

packages=(
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

if [[ $( uname -m ) == "x86_64" ]]; then
  # TODO: figure out how to install Bazel on aarch64.
  packages+=( bazel )
fi

if [[ $ubuntu_major_version -ge 20 ]]; then
  packages+=( g++-10 )
fi

if [[ $ubuntu_major_version -ge 22 ]]; then
  packages+=( g++-11 )
fi

yb_debian_configure_and_install_packages "${packages[@]}"
yb_perform_os_independent_steps
yb_remove_build_infra_scripts
