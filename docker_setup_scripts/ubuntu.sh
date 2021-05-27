#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

yb_apt_get_dist_upgrade

# shellcheck disable=SC1091
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
  openjdk-8-jdk-headless
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

if [[ $ubuntu_major_version -le 18 ]]; then
  packages+=(
    python-pip
    python-dev
    gcc-8
    g++-8
  )
fi

yb_debian_init_locale

export DEBIAN_FRONTEND=noninteractive

yb_apt_install_packages_separately "${packages[@]}"

yb_debian_install_llvm_packages

yb_apt_cleanup

bash "$yb_build_infra_scripts_dir/perform_common_setup.sh"

yb_remove_build_infra_scripts
