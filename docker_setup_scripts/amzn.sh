#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

# Packages installed on all supported versions of AmazonLinux (direct copy of RedHat list).
readonly REDHAT_COMMON_PACKAGES=(
  autoconf
  bind-utils
  bzip2
  bzip2-devel
  ccache
  chrpath
  curl
  gcc
  gcc-c++
  gdbm-devel
  git
  glibc-all-langpacks
  java-1.8.0-openjdk
  java-1.8.0-openjdk-devel
  langpacks-en
  less
  libatomic
  libffi-devel
  libsqlite3x-devel
  libtool
  openssl-devel
  openssl-devel
  patch
  patchelf
  perl-core
  php
  php-common
  php-curl
  readline-devel
  rsync
  ruby
  ruby-devel
  sudo
  vim
  wget
  which
  xz
)

readonly AMZN2_ONLY_PACKAGES=(
  python38-devel
  libselinux-python
  libsemanage-python
)

# -------------------------------------------------------------------------------------------------
# Functions
# -------------------------------------------------------------------------------------------------

yb_fatal_unsupported_amzn_major_version() {
  (
    echo "Unsupported major version of AmazonLinux: $os_major_version"
    echo "(from /etc/os-release)"
    echo
    echo "--------------------------------------------------------------------------------------"
    echo "Contents of /etc/os-release"
    echo "--------------------------------------------------------------------------------------"
    cat /etc/os-release
    echo "--------------------------------------------------------------------------------------"
    echo
  ) >&2
  exit 1
}

detect_os_version() {
  os_major_version=$(
    grep -E ^VERSION= /etc/os-release | sed 's/VERSION=//; s/"//g' | awk '{print $1}'
  )
  os_major_version=${os_major_version%%.*}
  # TODO: Add 2023
  if [[ ! $os_major_version =~ ^[2]$ ]]; then
    yb_fatal_unsupported_amzn_major_version
  fi
  readonly os_major_version
}

install_packages() {
  local packages=( "${REDHAT_COMMON_PACKAGES[@]}" )

  case "${os_major_version}" in
    2)
      package_manager=yum
      packages+=( "${AMZN2_ONLY_PACKAGES[@]}" )
    ;;
    *)
      yb_fatal_unsupported_amzn_major_version
  esac

  yb_start_group "Upgrading existing packages"
  "$package_manager" upgrade -y
  yb_end_group

  yb_start_group "Installing epel-release"
  amazon-linux-extras install epel
  yb_end_group

  yb_start_group "Installing development tools"
  "$package_manager" groupinstall -y 'Development Tools'
  yb_end_group

  yb_start_group "Installing AmazonLinux $os_major_version packages"
  (
    set -x
    "${package_manager}" install -y "${packages[@]}"
  )

}

yb_configure_python38_on_amzn2() {
  amazon-linux-extras install python3.8
  rm -f /usr/bin/python3
  ln -s /usr/bin/python3.8 /usr/bin/python3
  python3 -m pip install --upgrade pip
}

# -------------------------------------------------------------------------------------------------
# Main script
# -------------------------------------------------------------------------------------------------

detect_os_version

install_packages

yb_yum_cleanup

yb_perform_universal_steps

yb_install_cmake
yb_install_ninja

if [[ $os_major_version -eq 2 ]]; then
  yb_configure_python38_on_amzn2
fi

yb_remove_build_infra_scripts
