#!/usr/bin/env bash

set -euo pipefail
version=3.31.0
work_dir=/tmp/install_cmake
mkdir -p "$work_dir"
cd "$work_dir"
dest_dir_name=cmake-$version
arch=$( uname -m )
extracted_dir_name=${dest_dir_name}-linux-${arch}
dest_dir=/usr/share/${dest_dir_name}
tarball_name=$extracted_dir_name.tar.gz

# We want these URLs:
# https://github.com/Kitware/CMake/releases/download/v3.31.0/cmake-3.31.0-linux-x86_64.tar.gz
# https://github.com/Kitware/CMake/releases/download/v3.31.0/cmake-3.31.0-linux-aarch64.tar.gz

url=https://github.com/Kitware/CMake/releases/download/v$version/$tarball_name
rm -f "$tarball_name"
curl --silent -LO "$url"
actual_sha256sum=$( sha256sum "$tarball_name" | awk '{print $1}' )

if [[ $arch == "x86_64" ]]; then
  expected_sha256sum=0fcb338b4515044f9ac77543550ac92c314c58f6f95aafcac5cd36aa75db6924
elif [[ $arch == "aarch64" ]]; then
  expected_sha256sum=e0f74862734c2d14ef8ac5a71941691531db0bbebee0a9c20a8e96e8a97390f9
else
  echo >&2 "Unknown architecture: $arch"
  exit 1
fi

if [[ $actual_sha256sum != "$expected_sha256sum" ]]; then
  echo "Invalid checksum: $actual_sha256sum, expected: $expected_sha256sum" >&2
  exit 1
fi

tar xzf "$tarball_name"
rm -rf "$dest_dir"
mv "$extracted_dir_name" "$dest_dir"
rm -f /usr/local/bin/{cmake,ctest}
ln -s "$dest_dir/bin/cmake" /usr/local/bin/cmake
ln -s "$dest_dir/bin/ctest" /usr/local/bin/ctest
