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

readonly CENTOS7_GCC_TOOLSETS_TO_INSTALL_X86_64=( 8 9 10 11 )
readonly CENTOS7_GCC_TOOLSETS_TO_INSTALL_AARCH64=( 8 9 10 )
readonly RHEL8_GCC_TOOLSETS_TO_INSTALL=( 9 10 11 )

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

readonly RHEL8_ONLY_PACKAGES=(
  libselinux
  libselinux-devel
  llvm-toolset
  python38
  python38-devel
  python38-pip
  python38-psutil

  glibc-locale-source
  glibc-langpack-en
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
  elif [[ $centos_major_version -eq 8 ]]; then
    toolset_prefix="gcc-toolset"
    gcc_toolsets_to_install=( "${RHEL8_GCC_TOOLSETS_TO_INSTALL[@]}" )
    toolset_package_suffixes+=( "${TOOLSET_PACKAGE_SUFFIXES_RHEL8[@]}" )
    package_manager=dnf
    packages+=( "${RHEL8_ONLY_PACKAGES[@]}" )
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

  local go_version=1.19.2
  local expected_sha256
  local arch_in_pkg_name
  case "$( uname -m )" in
    aarch64)
      expected_sha256=b62a8d9654436c67c14a0c91e931d50440541f09eb991a987536cb982903126d
      arch_in_pkg_name=arm64
    ;;
    x86_64)
      expected_sha256=16f8047d7b627699b3773680098fbaf7cc962b7db02b3e02726f78c4db26dfde
      arch_in_pkg_name=amd64
    ;;
    *)
      echo >&2 "Unknown architecture $( uname -m )"
      exit 1
    ;;
  esac

  local go_archive_name="go${go_version}.linux-${arch_in_pkg_name}.tar.gz"
  local go_url="https://go.dev/dl/${go_archive_name}"
  local tmp_dir="/tmp/go_installation"
  local go_install_parent_dir="/opt/go"
  local go_install_path="${go_install_parent_dir}/go-${go_version}"
  local go_latest_dir_link="${go_install_parent_dir}/latest"
  mkdir -p "${tmp_dir}"
  (
    cd "${tmp_dir}"
    wget "${go_url}"
    actual_sha256=$( sha256sum "${go_archive_name}" | awk '{print $1}' )
    if [[ ${actual_sha256} != "${expected_sha256}" ]]; then
      echo >&2 "Invalid SHA256 sum of ${go_archive_name}: expected ${expected_sha256}, got" \
               "${actual_sha256}"
      exit 1
    fi
    tar xzf "${go_archive_name}"
    mkdir -p "${go_install_parent_dir}"
    mv go "${go_install_path}"
    mkdir -p /usr/local/bin
    ln -s "${go_install_path}" "${go_latest_dir_link}"
    for binary_name in go gofmt; do
      ln -s "${go_latest_dir_link}/bin/${binary_name}" "/usr/local/bin/${binary_name}"
    done
  )
  rm -rf "${tmp_dir}"
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

yb_install_cmake
yb_install_ninja

if [[ $centos_major_version -eq 7 ]]; then
  yb_install_python3_from_source
fi

if [[ $centos_major_version -eq 8 ]]; then
  yb_redhat_init_locale
fi

yb_remove_build_infra_scripts
