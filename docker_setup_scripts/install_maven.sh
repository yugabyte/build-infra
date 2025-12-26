#!/usr/bin/env bash

set -euo pipefail -x

readonly MAVEN_VERSION=3.9.11

install_maven() {
  local version=$MAVEN_VERSION
  local maven_url='https://archive.apache.org/dist/maven/maven3'
  local maven_dir_name=apache-maven-$version
  local tarball_name=$maven_dir_name-bin.tar.gz
  local url="$maven_url/$version/binaries/$tarball_name"
  local shaurl="$maven_url/$version/binaries/$tarball_name.sha512"
  local sigurl="$maven_url/$version/binaries/$tarball_name.asc"
  local maven_tmp_dir=/tmp/install_maven
  local dest_dir=/usr/share/$maven_dir_name
  local mvn_link_path=/usr/local/bin/mvn
  if [[ -d $dest_dir &&
        $(readlink "$mvn_link_path") == "$dest_dir/bin/mvn" ]]; then
    echo "Maven is already installed at $dest_dir and symlinked to /usr/local/bin"
    return
  fi
  mkdir -p "$maven_tmp_dir"
  (
    cd "$maven_tmp_dir"
    rm -rf "${maven_tmp_dir:?}/"*
    curl -O "$url"
    local actual_sha512sum
    actual_sha512sum=$( sha512sum "$tarball_name" | awk '{print $1}' )
    local expected_sha512sum=$(curl "$shaurl")
    if [[ $actual_sha512sum != "$expected_sha512sum" ]]; then
      echo "Invalid checksum: $actual_sha512sum, expected: $expected_sha512sum" >&2
      exit 1
    fi
    tar xzf "$tarball_name"
  )
  sudo rm -rf "$dest_dir"
  sudo mv "$maven_tmp_dir/$maven_dir_name" "$dest_dir"
  sudo rm -rf "$maven_tmp_dir"
  sudo mkdir -p /usr/local/bin
  local mvn_binary_path="/usr/share/$maven_dir_name/bin/mvn"
  if [[ ! -e $mvn_binary_path ]]; then
    echo "$mvn_binary_path does not exist" >&2
    exit 1
  fi
  sudo rm -f "$mvn_link_path"
  sudo ln -s "$mvn_binary_path" "$mvn_link_path"
}

install_maven
