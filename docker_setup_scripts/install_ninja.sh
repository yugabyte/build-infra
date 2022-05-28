#!/usr/bin/env bash

set -euo pipefail -x

readonly TMP_DIR=/tmp/install_ninja
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

arch=$( uname -m )

readonly NINJA_VERSION=1.11.0
readonly NINJA_INSTALL_PREFIX=/usr/local

if [[ $arch == "x86_64" ]]; then
  readonly ARCHIVE_NAME=ninja-linux.zip
  curl -L -O --silent \
    https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/$ARCHIVE_NAME
  expected_sha256=763464859c7ef2ea3a0a10f4df40d2025d3bb9438fcb1228404640410c0ec22d
  actual_sha256=$( sha256sum $ARCHIVE_NAME | awk '{print $1}' )
  if [[ $expected_sha256 != "$actual_sha256" ]]; then
    echo "Expected $ARCHIVE_NAME SHA256 is $expected_sha256, got $actual_sha256" >&2
    exit 1
  fi
  unzip $ARCHIVE_NAME
  mkdir -p "$NINJA_INSTALL_PREFIX/bin"
  cp ninja "$NINJA_INSTALL_PREFIX/bin"
  rm -rf "$TMP_DIR"
elif [[ $arch == "aarch64" ]]; then
  export PATH=/usr/local/bin:$PATH
  git clone https://github.com/ninja-build/ninja
  cd ninja
  git checkout "v${NINJA_VERSION}"
  mkdir build
  cd build
  cmake -DCMAKE_BUILD_TYPE=Release "-DCMAKE_INSTALL_PREFIX=$NINJA_INSTALL_PREFIX" ..
  make
  make install
else
  echo >&2 "Unknown architecture: $arch"
  exit 1
fi
