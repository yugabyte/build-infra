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

readonly TOOLSET_PACKAGE_SUFFIXES_CENTOS8=(
  toolchain
  gcc
  gcc-c++
)

readonly CENTOS7_GCC_TOOLSETS_TO_INSTALL=( 8 9 )
readonly CENTOS8_GCC_TOOLSETS_TO_INSTALL=( 9 )

# Packages installed on all supported versions of CentOS.
readonly CENTOS_COMMON_PACKAGES=(
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
  perl-Digest
  php
  php-common
  php-curl
  python2
  python2-pip
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

readonly CENTOS8_ONLY_PACKAGES=(
  libselinux
  libselinux-devel
  llvm-toolset
  python38
  python38-devel
  python38-pip
)

# -------------------------------------------------------------------------------------------------
# Functions
# -------------------------------------------------------------------------------------------------

start_group() {
  yb_start_group "$*"
}

end_group() {
  yb_end_group
}

detect_centos_version() {
  centos_major_version=$(
    grep -E ^VERSION= /etc/os-release | sed 's/VERSION=//; s/"//g' | awk '{print $1}'
  )
  centos_major_version=${centos_major_version%%.*}
  if [[ ! $centos_major_version =~ ^[78]$ ]]; then
    (
      echo "Unsupported major version of CentOS: $centos_major_version (from /etc/os-release)"
      echo
      echo "--------------------------------------------------------------------------------------"
      echo "Contents of /etc/os-release"
      echo "--------------------------------------------------------------------------------------"
      cat /etc/os-release
      echo "--------------------------------------------------------------------------------------"
      echo
    )
    exit 1
  fi
  readonly centos_major_version
}

install_packages() {
  local packages=( "${CENTOS_COMMON_PACKAGES[@]}" )

  local toolset_prefix
  local gcc_toolsets_to_install
  local package_manager
  local toolset_package_suffixes=( "${TOOLSET_PACKAGE_SUFFIXES_COMMON[@]}" )
  if [[ $centos_major_version -eq 7 ]]; then
    toolset_prefix="devtoolset"
    gcc_toolsets_to_install=( "${CENTOS7_GCC_TOOLSETS_TO_INSTALL[@]}" )
    package_manager=yum
    packages+=( "${CENTOS7_ONLY_PACKAGES[@]}" )
  elif [[ $centos_major_version -eq 8 ]]; then
    toolset_prefix="gcc-toolset"
    gcc_toolsets_to_install=( "${CENTOS8_GCC_TOOLSETS_TO_INSTALL[@]}" )
    toolset_package_suffixes+=( "${TOOLSET_PACKAGE_SUFFIXES_CENTOS8[@]}" )
    package_manager=dnf
    packages+=( "${CENTOS8_ONLY_PACKAGES[@]}" )
  else
    echo "Unknown CentOS major version: $centos_major_version" >&2
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

  start_group "Upgrading existing packages"
  "$package_manager" upgrade -y
  end_group

  start_group "Installing epel-release"
  "$package_manager" install -y epel-release
  end_group

  start_group "Installing development tools"
  "$package_manager" groupinstall -y 'Development Tools'
  end_group

  if [[ $centos_major_version -eq 7 ]]; then
    # We have to install centos-release-scl before installing devtoolsets.
    "$package_manager" install -y centos-release-scl
  fi

  start_group "Installing CentOS $centos_major_version packages"
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
  end_group
}

install_golang() {
  start_group "Installing Golang"
  if [[ $centos_major_version -eq 7 ]]; then
    rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
    curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
  fi
  yum install -y golang
  end_group
}

# -------------------------------------------------------------------------------------------------
# Main script
# -------------------------------------------------------------------------------------------------

detect_centos_version

install_packages

install_golang

yb_yum_cleanup

yb_perform_os_independent_steps

yb_install_ninja_from_source
yb_install_cmake_from_source

if [[ $centos_major_version -eq 7 ]]; then
  yb_install_python3_from_source
  yb_install_custom_built_llvm
fi

if [[ $centos_major_version -eq 8 ]]; then
  yb_redhat_init_locale
fi

yb_remove_build_infra_scripts
