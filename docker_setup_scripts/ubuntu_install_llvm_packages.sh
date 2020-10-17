#!/usr/bin/env bash

readonly CLANG_VERSION=10

set -euo pipefail

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -

cat >/etc/apt/sources.list.d/llvm10.list <<-EOT
deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-10 main
deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-10 main
EOT

apt-get update

not_installed_packages=(
    libllvm-$CLANG_VERSION-ocaml-dev
    libomp-$CLANG_VERSION-dev
)

packages=(
    clang-$CLANG_VERSION
    clang-$CLANG_VERSION-doc
    clang-format-$CLANG_VERSION
    clang-tools-$CLANG_VERSION
    clangd-$CLANG_VERSION
    libc++-$CLANG_VERSION-dev
    libc++abi-$CLANG_VERSION-dev
    libclang-$CLANG_VERSION-dev
    libclang-common-$CLANG_VERSION-dev
    libclang1-$CLANG_VERSION
    libfuzzer-$CLANG_VERSION-dev
    libllvm$CLANG_VERSION
    lld-$CLANG_VERSION
    lldb-$CLANG_VERSION
    llvm-$CLANG_VERSION
    llvm-$CLANG_VERSION-dev
    llvm-$CLANG_VERSION-doc
    llvm-$CLANG_VERSION-examples
    llvm-$CLANG_VERSION-runtime
    python3-clang-$CLANG_VERSION
)

apt-get install -y "${packages[@]}"