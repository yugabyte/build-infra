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

readonly TOOLSET_PACKAGE_SUFFIXES_RHEL8=(
  toolchain
  gcc
  gcc-c++
)

readonly CENTOS7_GCC_TOOLSETS_TO_INSTALL_X86_64=( 11 )
readonly CENTOS7_GCC_TOOLSETS_TO_INSTALL_AARCH64=( 10 )
readonly RHEL8_GCC_TOOLSETS_TO_INSTALL=( 11 )

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
  perl-Digest
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

readonly CENTOS7_ONLY_PACKAGES=(
  python-devel
  libselinux-python
  libsemanage-python
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
)

readonly RHEL7_8_ONLY_PACKAGES=(
  gdbm-devel
  python2
  python2-pip
  curl
)

readonly RHEL9_ONLY_PACKAGES=(
  perl-FindBin
)

# -------------------------------------------------------------------------------------------------
# Functions
# -------------------------------------------------------------------------------------------------

detect_os_version() {
  os_major_version=$(
    grep -E ^VERSION= /etc/os-release | sed 's/VERSION=//; s/"//g' | awk '{print $1}'
  )
  os_major_version=${os_major_version%%.*}
  if [[ ! $os_major_version =~ ^[789]$ ]]; then
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
  fi
  readonly os_major_version
}

install_packages() {
  local packages=( "${REDHAT_COMMON_PACKAGES[@]}" )

  local toolset_prefix
  local gcc_toolsets_to_install
  local package_manager
  local toolset_package_suffixes=( "${TOOLSET_PACKAGE_SUFFIXES_COMMON[@]}" )
  if [[ $os_major_version -eq 7 ]]; then
    toolset_prefix="devtoolset"
    local gcc_toolsets_to_install
    case "$( uname -m )" in
      x86_64)
        gcc_toolsets_to_install=( "${CENTOS7_GCC_TOOLSETS_TO_INSTALL_X86_64[@]}" )
      ;;
      aarch64)
        gcc_toolsets_to_install=( "${CENTOS7_GCC_TOOLSETS_TO_INSTALL_AARCH64[@]}" )
      ;;
      *)
        echo >&2 "Unknown architecture: $( uname -m )"
        exit 1
      ;;
    esac
    package_manager=yum
    packages+=( "${CENTOS7_ONLY_PACKAGES[@]}" )
    packages+=( "${RHEL7_8_ONLY_PACKAGES[@]}" )
  elif [[ $os_major_version -eq 8 ]]; then
    toolset_prefix="gcc-toolset"
    gcc_toolsets_to_install=( "${RHEL8_GCC_TOOLSETS_TO_INSTALL[@]}" )
    toolset_package_suffixes+=( "${TOOLSET_PACKAGE_SUFFIXES_RHEL8[@]}" )
    package_manager=dnf
    packages+=( "${RHEL8_ONLY_PACKAGES[@]}" )
    packages+=( "${RHEL7_8_ONLY_PACKAGES[@]}" )
  elif [[ $os_major_version -eq 9 ]]; then
    gcc_toolsets_to_install=()
    package_manager=dnf
    packages+=( "${RHEL9_ONLY_PACKAGES[@]}" )
  else
    echo "Unknown RHEL family OS major version: $os_major_version" >&2
    exit 1
  fi

  local gcc_toolset_version
  for gcc_toolset_version in "${gcc_toolsets_to_install[@]}"; do
    local versioned_prefix="${toolset_prefix}-${gcc_toolset_version}"
    packages+=( "${versioned_prefix}" )
    for package_suffix in "${toolset_package_suffixes[@]}"; do
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

  if [[ $os_major_version -eq 7 ]]; then
    # We have to install centos-release-scl before installing devtoolsets.
    "$package_manager" install -y centos-release-scl
  fi

  yb_start_group "Installing CentOS $os_major_version packages"
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

if [[ $os_major_version -eq 7 ]]; then
  yb_install_python3_from_source
fi

if [[ $os_major_version -lt 9 ]]; then
  yb_redhat_init_locale
fi

yb_remove_build_infra_scripts
