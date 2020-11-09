#!/usr/bin/env bash

set -euo pipefail

packages=(
  autoconf
  bind-utils
  bzip2
  bzip2-devel
  ccache
  curl
  epel-release
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
  python-devel
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

readonly PER_DEVTOOLSET_PACKAGE_SUFFIXES=(
  libatomic-devel
  libasan-devel
  libtsan-devel
  libubsan-devel
)

readonly DEVTOOLSETS_TO_INSTALL=( 8 9 )
for devtoolset_index in "${DEVTOOLSETS_TO_INSTALL[@]}"; do
  packages+=( devtoolset-${devtoolset_index} )
  for package_suffix in "${PER_DEVTOOLSET_PACKAGE_SUFFIXES[@]}"; do
    packages+=( devtoolset-${devtoolset_index}-${package_suffix} )
  done
done

yum upgrade -y
yum install -y epel-release
yum groupinstall -y 'Development Tools'

# We have to install centos-release-scl before installing devtoolset-8.
yum install -y centos-release-scl

echo "::group::Installing CentOS packages"
( set -x; yum install -y "${packages[@]}" )

for devtoolset_index in "${DEVTOOLSETS_TO_INSTALL[@]}"; do
  enable_script=/opt/rh/devtoolset-${devtoolset_index}/enable
  if [[ ! -f $enable_script ]]; then
    echo "devtoolset-${devtoolset_index} did not get installed. The script to enable it not found" \
         "at $enable_script." >&2
    exit 1
  fi
fi
echo "::endgroup::"

echo "::group::Installig Golang"
rpm --import https://mirror.go-repo.io/centos/RPM-GPG-KEY-GO-REPO
curl -s https://mirror.go-repo.io/centos/go-repo.repo | tee /etc/yum.repos.d/go-repo.repo
yum install -y golang
echo "::endgroup::"

echo "::group::Yum cleanup"
yum clean all
echo "::endgroup::"

echo "::group::Installing Python 3 from source"
bash /tmp/yb_docker_setup_scripts/centos_install_python3_from_source.sh
echo "::endgroup::"

bash /tmp/yb_docker_setup_scripts/perform_common_setup.sh
bash /tmp/yb_docker_setup_scripts/centos_install_custom_built_llvm.sh

rm -rf /tmp/yb_docker_setup_scripts
