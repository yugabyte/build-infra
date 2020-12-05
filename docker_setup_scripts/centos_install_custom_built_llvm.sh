#!/usr/bin/env bash

set -euo pipefail
readonly URL_PREFIX=https://github.com/yugabyte/build-clang/releases/download

llvm_major_version=11
llvm_tarball_version_suffix=1604022592
llvm_full_version=$llvm_major_version.0.0
llvm_tarball_version=v${llvm_full_version}-${llvm_tarball_version_suffix}
llvm_dir_name=yb-llvm-$llvm_tarball_version
tarball_name=$llvm_dir_name.tar.gz
url=$URL_PREFIX/$llvm_tarball_version/$tarball_name
cd /opt/yb-build/llvm

curl -sLO "$url"
actual_sha256sum=$( sha256sum "$tarball_name" | awk '{print $1}')
expected_sha256sum=$( curl -sL "$url.sha256" | awk '{print $1}' )

if [[ $actual_sha256sum != $expected_sha256sum ]]; then
  echo "Checksum mismatch for $tarball_name: expected $expected_sha256sum," \
       "got $actual_sha256sum" >&2
  exit 1
fi

tar xzf "$tarball_name"
rm -f "$tarball_name"
installed_llvm_bin_dir=$PWD/$llvm_dir_name/bin
if [[ ! -d $installed_llvm_bin_dir ]]; then
  echo "Directory does not exist: $installed_llvm_bin_dir" >&2
  exit 1
fi

symlink_parent_dir=/usr/local/bin
mkdir -p "$symlink_parent_dir"

readonly LLVM_TOOLS_TO_LINK=( clang clang++ )

for tool_name in "${LLVM_TOOLS_TO_LINK[@]}"; do
  tool_path=$installed_llvm_bin_dir/$tool_name
  link_path=/usr/local/bin/$tool_name-$llvm_major_version
  if [[ -f $tool_path ]]; then
    ( set -x; ln -s "$tool_path" "$link_path" )
  else
    fatal "LLVM/Clang tool does not exist: $tool_path"
  fi
done