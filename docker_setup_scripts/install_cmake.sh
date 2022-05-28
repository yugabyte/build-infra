#!/usr/bin/env bash

set -euo pipefail
version=3.23.2
work_dir=/tmp/install_cmake
mkdir -p "$work_dir"
cd "$work_dir"
dest_dir_name=cmake-$version
arch=$( uname -m )
extracted_dir_name=${dest_dir_name}-linux-${arch}
dest_dir=/usr/share/${dest_dir_name}
tarball_name=$extracted_dir_name.tar.gz

# We want these URLs:
# https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2-linux-x86_64.tar.gz
# https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2-linux-aarch64.tar.gz

url=https://github.com/Kitware/CMake/releases/download/v$version/$tarball_name
rm -f "$tarball_name"
curl --silent -LO "$url"
actual_sha256sum=$( sha256sum "$tarball_name" | awk '{print $1}' )

if [[ $arch == "x86_64" ]]; then
  expected_sha256sum=aaced6f745b86ce853661a595bdac6c5314a60f8181b6912a0a4920acfa32708
elif [[ $arch == "aarch64" ]]; then
  expected_sha256sum=f2654bf780b53f170bbbec44d8ac67d401d24788e590faa53036a89476efa91e
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
