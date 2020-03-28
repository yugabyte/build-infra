#!/usr/bin/env bash

set -euo pipefail

yum upgrade -y
yum install -y epel-release
yum groupinstall -y 'Development Tools'

packages=(
    autoconf
    bind-utils
    bzip2
    bzip2-devel
    ccache
    centos-release-scl
    cmake3
    ctest3
    curl
    devtoolset-8
    epel-release
    gcc
    gcc-c++
    gdbm-devel
    git
    java-1.8.0-openjdk
    java-1.8.0-openjdk-devel
    less
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
echo "::endgroup::"
    
# TODO: install CMake from the binary package instead.
mkdir -p /usr/local/bin
ln -s /usr/bin/cmake3 /usr/local/bin/cmake
ln -s /usr/bin/ctest3 /usr/local/bin/ctest

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