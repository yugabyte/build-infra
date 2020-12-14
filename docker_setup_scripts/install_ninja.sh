#!/usr/bin/env bash

set -euo pipefail -x

readonly TMP_DIR=/tmp/download_ninja
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

readonly NINJA_VERSION=1.10.2
readonly ARCHIVE_NAME=ninja-linux.zip
curl -L -O --silent \
  https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/$ARCHIVE_NAME
expected_sha256=763464859c7ef2ea3a0a10f4df40d2025d3bb9438fcb1228404640410c0ec22d
actual_sha256=$( sha256sum $ARCHIVE_NAME | awk '{print $1}' )
if [[ $expected_sha256 != $actual_sha256 ]]; then
  echo "Expected $ARCHIVE_NAME SHA256 is $expected_sha256, got $actual_sha256" >&2
  exit 1
fi
unzip $ARCHIVE_NAME
mkdir -p /usr/local/bin
cp ninja /usr/local/bin
rm -rf "$TMP_DIR"