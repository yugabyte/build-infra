#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------------

readonly CENTOS7_PER_DEVTOOLSET_PACKAGE_SUFFIXES=(
  libatomic-devel
  libasan-devel
  libtsan-devel
  libubsan-devel
)

readonly CENTOS7_DEVTOOLSETS_TO_INSTALL=( 8 9 )

# Packages installed on all supported versions of CentOS.
readonly CENTOS_COMMON_PACKAGES=(
  autoconf
  bind-utils
  bzip2
  bzip2-devel
  ccache
  curl
  gcc
  gcc-c++
  gdbm-devel
  git
  java-1.8.0-openjdk
  java-1.8.0-openjdk-devel
  less
  libatomic
  libffi-devel
  libselinux-python
  libsemanage-python
  libsqlite3x-devel
  libtool
  openssl-devel
  openssl-devel
  patch
  perl-Digest
  php
  php-common
  php-curl
  python2
  python2-pip
  readline-devel
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
)

readonly CENTOS8_ONLY_PACKAGES=(
  python38
  python38-devel
  python38-pip
)

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------

start_group() {
  echo "::group::$*"
}

end_group() {
  echo "::endgroup::"
}

detect_centos_version() {
  local redhat_release_str
  redhat_release_str=$(</etc/redhat-release)
  if [[ $redhat_release_str =~ ^CentOS\ Linux\ release\ ([0-9]+)[.].* ]]; then
    centos_major_version=${BASH_REMATCH[1]}
    if [[ ! $centos_major_version =~ ^[78]$ ]]; then
      echo "Unsupported major version of CentOS: $centos_major_version" >&2
      exit 1
    fi
  else
    echo "Could not parse /etc/redhat-release: $redhat_release_str" >&2
    exit 1
  fi
  readonly centos_major_version
}

install_packages() {
  local packages=( "${CENTOS_COMMON_PACKAGES[@]}" )

  if [[ $centos_major_version -eq 7 ]]; then
    local devtoolset_index
    for devtoolset_index in "${CENTOS7_DEVTOOLSETS_TO_INSTALL[@]}"; do
      packages+=( devtoolset-${devtoolset_index} )
      for package_suffix in "${CENTOS7_PER_DEVTOOLSET_PACKAGE_SUFFIXES[@]}"; do
        packages+=( devtoolset-${devtoolset_index}-${package_suffix} )
      done
    done
  fi

  start_group "Upgrading existing packages"
  yum upgrade -y
  end_group

  start_group "Installing epel-release"
  yum install -y epel-release
  end_group

  start_group "Installing development tools"
  yum groupinstall -y 'Development Tools'
  end_group

  if [[ $centos_major_version -eq 7 ]]; then
    # We have to install centos-release-scl before installing devtoolset-8.
    yum install -y centos-release-scl

    packages+=( "${CENTOS7_ONLY_PACKAGES[@]}" )
  fi

  if [[ $centos_major_version -eq 8 ]]; then
    packages+=( "${CENTOS8_ONLY_PACKAGES[@]}" )
  fi

  start_group "Installing CentOS packages"
  ( set -x; yum install -y "${packages[@]}" )

  for devtoolset_index in "${DEVTOOLSETS_TO_INSTALL[@]}"; do
    enable_script=/opt/rh/devtoolset-${devtoolset_index}/enable
    if [[ ! -f $enable_script ]]; then
      echo "devtoolset-${devtoolset_index} did not get installed. The script to enable it not " \
           "found at $enable_script." >&2
      exit 1
    fi
  done
  end_group
}

# -------------------------------------------------------------------------------------------------
# Main script
# -------------------------------------------------------------------------------------------------

detect_centos_version

install_packages

start_group "Installig Golang"
rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
yum install -y golang
end_group

start_group "Yum cleanup"
yum clean all
end_group

if [[ $centos_major_version -eq 7 ]]; then
  start_group "Installing Python 3 from source"
  bash /tmp/yb_docker_setup_scripts/centos_install_python3_from_source.sh
  end_group
fi

bash /tmp/yb_docker_setup_scripts/perform_common_setup.sh
bash /tmp/yb_docker_setup_scripts/centos_install_custom_built_llvm.sh

rm -rf /tmp/yb_docker_setup_scripts
