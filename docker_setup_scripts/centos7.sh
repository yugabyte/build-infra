#!/usr/bin/env bash

set -euo pipefail

yum upgrade -y
yum install -y epel-release
yum groupinstall -y 'Development Tools'

# We have to install centos-release-scl before installing devtoolset-8.
yum install -y centos-release-scl

packages=(
    autoconf
    bind-utils
    bzip2
    bzip2-devel
    ccache
    curl
    devtoolset-8
    devtoolset-8-libatomic-devel
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

echo "::group::Installing CentOS packages"
yum install -y "${packages[@]}"

if [[ ! -f /opt/rh/devtoolset-8/enable ]]; then
  echo "devtoolset-8 did not get installed" >&2
  exit 1
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

rm -rf /tmp/yb_docker_setup_scripts