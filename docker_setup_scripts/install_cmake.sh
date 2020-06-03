#!/usr/bin/env bash

set -euo pipefail
version=3.17.3
work_dir=/tmp/install_cmake
mkdir -p "$work_dir"
cd "$work_dir"
dest_dir_name=cmake-$version
extracted_dir_name=$dest_dir_name-Linux-x86_64
dest_dir=/usr/share/$dest_dir_name
tarball_name=$extracted_dir_name.tar.gz
url=https://github.com/Kitware/CMake/releases/download/v$version/$tarball_name
rm -f "$tarball_name"
curl --silent -LO "$url"
actual_sha256sum=$( sha256sum "$tarball_name" | awk '{print $1}' )
expected_sha256sum=da8093956f0b4ae30293c9db498da9bdeaeea4e7a2b1f2d1637ddda064d06dd0
if [[ $actual_sha256sum != $expected_sha256sum ]]; then
  echo "Invalid checksum: $actual_sha256sum, expectded: $expected_sha256sum" >&2
  exit 1
fi
tar xzf "$tarball_name"
rm -rf "$dest_dir"
mv "$extracted_dir_name" "$dest_dir"
rm -f /usr/local/bin/{cmake,ctest}
ln -s "$dest_dir/bin/cmake" /usr/local/bin/cmake
ln -s "$dest_dir/bin/ctest" /usr/local/bin/ctest
