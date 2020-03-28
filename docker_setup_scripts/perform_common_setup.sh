#!/usr/bin/env bash

set -euo pipefail

adduser --disabled-password --gecos "" yugabyteci

cd "${BASH_SOURCE[0]%/*}"

./install_hub_tool.sh
./install_ninja.sh
./install_shellcheck.sh
