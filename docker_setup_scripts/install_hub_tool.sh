#!/usr/bin/env bash

# "hub" is a tool for interacting with GitHub
# See instructions at https://github.com/github/hub

set -euo pipefail -x

# https://perlgeek.de/en/article/set-up-a-clean-utf8-environment
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

export GOPATH=$HOME/go
hub_src_dir="$GOPATH"/src/github.com/github/hub
mkdir -p "$hub_src_dir"
git clone \
  --branch v2.11.2 \
  --config transfer.fsckobjects=false \
  --config receive.fsckobjects=false \
  --config fetch.fsckobjects=false \
  https://github.com/github/hub.git "$hub_src_dir"
cd "$hub_src_dir"
# Don't build or install the documentation -- it requires packages like groff that have a lot of
# dependencies.
sed -i 's#install: bin/hub man-pages#install: bin/hub#g' Makefile
sed -i 's#for src in bin/hub .*#for src in bin/hub; do#' script/install.sh
make install prefix=/usr/local

rm -rf "$GOPATH"
