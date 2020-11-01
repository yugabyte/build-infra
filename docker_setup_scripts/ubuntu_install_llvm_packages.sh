#!/usr/bin/env bash

set -euo pipefail -x

readonly LLVM_VERSIONS=( 10 11 )

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -

for llvm_version in "${LLVM_VERSIONS[@]}"; do
  (
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-$llvm_version main"
    echo "deb-src http://apt.llvm.org/bionic/ llvm-toolchain-bionic-$llvm_version main"
  ) >"/etc/apt/sources.list.d/llvm$llvm_version.list"
done

apt-get update

for llvm_version in "${LLVM_VERSIONS[@]}"; do
  # Not installing packages:
  #   libllvm-$llvm_version-ocaml-dev
  #   libomp-$llvm_version-dev
  packages=(
      clang-$llvm_version
      clang-$llvm_version-doc
      clang-format-$llvm_version
      clang-tools-$llvm_version
      clangd-$llvm_version
      libc++-$llvm_version-dev
      libc++abi-$llvm_version-dev
      libclang-$llvm_version-dev
      libclang-common-$llvm_version-dev
      libclang1-$llvm_version
      libfuzzer-$llvm_version-dev
      libllvm$llvm_version
      lld-$llvm_version
      lldb-$llvm_version
      llvm-$llvm_version
      llvm-$llvm_version-dev
      llvm-$llvm_version-doc
      llvm-$llvm_version-examples
      llvm-$llvm_version-runtime
      python3-clang-$llvm_version
  )

  apt-get install -y "${packages[@]}"
done