#!/usr/bin/env bash

# shellcheck disable=SC1091
source scl_source enable devtoolset-8

set -euo pipefail -x

python_tmp_dir=/tmp/python_install_from_source
mkdir -p "$python_tmp_dir"
python_version=3.8.2
python_src_dir_name="Python-$python_version"
cd "$python_tmp_dir"
python_src_tarball_name="$python_src_dir_name.tgz"
python_src_tarball_url="https://www.python.org/ftp/python/$python_version/$python_src_tarball_name"
wget "$python_src_tarball_url"
actual_md5sum=$( md5sum "$python_src_tarball_name" | awk '{print $1}')
expected_md5sum="f9f3768f757e34b342dbc06b41cbc844"
if [[ $actual_md5sum != "$expected_md5sum" ]]; then
  echo >&2 "Checksum mismatch: actual=$actual_md5sum, expected=$expected_md5sum"
fi
python_build_dir="$python_tmp_dir/$python_src_dir_name"
sudo rm -rf "$python_build_dir"
tar xzf "$python_src_tarball_name"
cd "$python_build_dir"
python_prefix="/usr/share/python-$python_version"
export CFLAGS="-mno-avx -mno-bmi -mno-bmi2 -mno-fma -march=core-avx-i"
export CXXFLAGS=$CFLAGS
export LDFLAGS="-Wl,-rpath=$python_prefix/lib"
echo "CFLAG=$CFLAGS"
echo "LDFLAGS=$LDFLAGS"
./configure "--prefix=$python_prefix" "--with-optimizations"
make
sudo make install
# Upgrade pip
sudo "$python_prefix/bin/pip3" install -U pip

for binary_name in python3 pip3 python3-config; do
  sudo update-alternatives --install "/usr/local/bin/$binary_name" "$binary_name" \
                           "$python_prefix/bin/$binary_name" 1000
done