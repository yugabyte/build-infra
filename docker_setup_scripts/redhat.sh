#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

readonly TOOLSET_PACKAGE_SUFFIXES_COMMON=(
  libatomic-devel
  libasan-devel
  libtsan-devel
  libubsan-devel
)

readonly TOOLSET_PACKAGE_SUFFIXES_RHEL8_GCC11=(
  toolchain
)

readonly TOOLSET_PACKAGE_SUFFIXES_RHEL8_9=(
  gcc
  gcc-c++
)

readonly RHEL8_GCC_TOOLSETS_TO_INSTALL=( 11 12 13 )
readonly RHEL9_GCC_TOOLSETS_TO_INSTALL=( 12 13 )

# Packages installed on all supported versions of CentOS.
readonly REDHAT_COMMON_PACKAGES=(
  autoconf
  bind-utils
  bzip2
  bzip2-devel
  ccache
  chrpath
  gcc
  gcc-c++
  git
  glibc-all-langpacks
  java-1.8.0-openjdk
  java-1.8.0-openjdk-devel
  java-11-openjdk
  java-11-openjdk-devel
  java-17-openjdk
  java-17-openjdk-devel
  langpacks-en
  less
  libatomic
  libffi-devel
  libsqlite3x-devel
  libtool
  npm
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

readonly RHEL8_ONLY_PACKAGES=(
  libselinux
  libselinux-devel
  python38
  python38-devel
  python38-pip
  python38-psutil

  glibc-locale-source
  glibc-langpack-en

  gdbm-devel
  curl
)

# Attempting to install curl on AlmaLinux 9 leads to the following error:
#
# https://gist.githubusercontent.com/mbautin/65b076bdb6a621de721df91ff66c1579/raw
#
# We are making sure that curl-minimal is installed instead, for clarity. However, it is required by
# dnf so it will always be installed anyway.
readonly RHEL9_ONLY_PACKAGES=(
  perl-FindBin
  curl-minimal
  python3-devel
)

# -------------------------------------------------------------------------------------------------
# Functions
# -------------------------------------------------------------------------------------------------

yb_fatal_unsupported_rhel_major_version() {
  (
    echo "Unsupported major version of CentOS/AlmaLinux/RHEL: $os_major_version"
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
  if [[ ! $os_major_version =~ ^[89]$ ]]; then
    yb_fatal_unsupported_rhel_major_version
  fi
  readonly os_major_version
}

install_packages() {
  local packages=( "${REDHAT_COMMON_PACKAGES[@]}" )

  # The settings below are used on RHEL 8 and later.
  local toolset_prefix="gcc-toolset"
  local package_manager=dnf

  local gcc_toolsets_to_install=()
  local toolset_package_suffixes=( "${TOOLSET_PACKAGE_SUFFIXES_COMMON[@]}" )
  case "${os_major_version}" in
    8)
      gcc_toolsets_to_install=( "${RHEL8_GCC_TOOLSETS_TO_INSTALL[@]}" )
      toolset_package_suffixes+=(
        "${TOOLSET_PACKAGE_SUFFIXES_RHEL8_9[@]}"
      )
      packages+=( "${RHEL8_ONLY_PACKAGES[@]}" )
    ;;
    9)
      gcc_toolsets_to_install=( "${RHEL9_GCC_TOOLSETS_TO_INSTALL[@]}" )
      toolset_package_suffixes+=(
        "${TOOLSET_PACKAGE_SUFFIXES_RHEL8_9[@]}"
      )
      package_manager=dnf
      packages+=( "${RHEL9_ONLY_PACKAGES[@]}" )
    ;;
    *)
      yb_fatal_unsupported_rhel_major_version
  esac

  local gcc_toolset_version
  for gcc_toolset_version in "${gcc_toolsets_to_install[@]}"; do
    local versioned_prefix="${toolset_prefix}-${gcc_toolset_version}"
    packages+=( "${versioned_prefix}" )
    current_toolset_package_suffixes=( "${toolset_package_suffixes[@]}" )
    if [[ $gcc_toolset_version -eq 11 && $os_major_version -eq 8 ]]; then
      current_toolset_package_suffixes+=(
        "${TOOLSET_PACKAGE_SUFFIXES_RHEL8_GCC11[@]}"
      )
    fi
    for package_suffix in "${current_toolset_package_suffixes[@]}"; do
      packages+=( "${versioned_prefix}-${package_suffix}" )
    done
  done

  yb_start_group "Upgrading existing packages"
  "$package_manager" upgrade -y
  yb_end_group

  yb_start_group "Installing epel-release"
  "$package_manager" install -y epel-release
  yb_end_group

  yb_start_group "Installing development tools"
  "$package_manager" groupinstall -y 'Development Tools'
  yb_end_group

  yb_start_group "Installing AlmaLinux $os_major_version packages"
  (
    set -x
    "${package_manager}" install -y "${packages[@]}"
  )

  for devtoolset_index in "${gcc_toolsets_to_install[@]}"; do
    enable_script=/opt/rh/${toolset_prefix}-${devtoolset_index}/enable
    if [[ ! -f $enable_script ]]; then
      echo "${toolset_prefix}-${devtoolset_index} did not get installed." \
           "The script to enable it not found at $enable_script." >&2
      exit 1
    fi
  done
  yb_end_group
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

if [[ $os_major_version -lt 9 ]]; then
  yb_redhat_init_locale
fi

yb_remove_build_infra_scripts
