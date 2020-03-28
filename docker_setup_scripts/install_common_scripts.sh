#!/usr/bin/env bash

# Setup shared between multiple systems

set -euo pipefail

if [[ $OSTYPE == linux* ]]; then
  adduser --disabled-password --gecos "" yugabyteci
fi

cd "${BASH_SOURCE[0]%/*}"

./install_hub_tool.sh
./install_ninja.sh
./install_shellcheck.sh