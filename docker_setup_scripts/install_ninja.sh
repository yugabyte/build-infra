#!/usr/bin/env bash

set -euo pipefail -x

tmp_dir=/tmp/build_ninja
rm -rf "$tmp_dir"
mkdir -p "$tmp_dir"
cd "$tmp_dir"

git clone --depth 1 --branch v1.10.0 https://github.com/ninja-build/ninja

cd ninja
./configure.py --bootstrap
cp ninja /usr/local/bin

rm -rf "$tmp_dir"