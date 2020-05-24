#!/usr/bin/env bash

set -euo pipefail -x

version=3.6.3
maven_dir_name=apache-maven-$version
tarball_name=$maven_dir_name-bin.tar.gz
url="https://apache.osuosl.org/maven/maven-3/$version/binaries/$tarball_name"
cd /tmp
curl -O "$url"
cd /usr/share
tar xzf "/tmp/$tarball_name"
mkdir -p /usr/local/bin
mvn_binary_path="/usr/share/$maven_dir_name/bin/mvn"
if [[ ! -e $mvn_binary_path ]]; then
  echo "$mvn_binary_path does not exist" >&2
  exit 1
fi
ln -s "$mvn_binary_path" /usr/local/bin