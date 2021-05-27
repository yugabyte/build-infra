#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

readonly LLVM_VERSIONS=( 10 11 12 )

wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -

# shellcheck disable=SC1091,SC2153
codename=$(
  . /etc/os-release
  if [[ -n ${UBUNTU_CODENAME:-} ]]; then
    echo "$UBUNTU_CODENAME"
  else
    echo "$VERSION_CODENAME"
  fi
)

if [[ -z ${codename:-} ]]; then
  echo >&2 "Failed to get Ubuntu codename"
  exit 1
fi

echo "Debian/Ubuntu codename: $codename"

for llvm_version in "${LLVM_VERSIONS[@]}"; do
  (
    echo "deb http://apt.llvm.org/$codename/ \
llvm-toolchain-$codename-$llvm_version main"
    echo "deb-src http://apt.llvm.org/$codename/ \
llvm-toolchain-$codename-$llvm_version main"
  ) >"/etc/apt/sources.list.d/llvm$llvm_version.list"
done

apt-get update

for llvm_version in "${LLVM_VERSIONS[@]}"; do
  # Not installing packages:
  #   libllvm-$llvm_version-ocaml-dev
  #   libomp-$llvm_version-dev
  packages=(
      "clang-$llvm_version"
      "clang-$llvm_version-doc"
      "clang-format-$llvm_version"
      "clang-tools-$llvm_version"
      "clangd-$llvm_version"
      "libc++-$llvm_version-dev"
      "libc++abi-$llvm_version-dev"
      "libclang-$llvm_version-dev"
      "libclang-common-$llvm_version-dev"
      "libclang1-$llvm_version"
      "libfuzzer-$llvm_version-dev"
      "libllvm$llvm_version"
      "lld-$llvm_version"
      "lldb-$llvm_version"
      "llvm-$llvm_version"
      "llvm-$llvm_version-dev"
      "llvm-$llvm_version-doc"
      "llvm-$llvm_version-examples"
      "llvm-$llvm_version-runtime"
      "python3-clang-$llvm_version"
  )

  apt-get install -y "${packages[@]}"
done