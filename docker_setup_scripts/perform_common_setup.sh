#!/usr/bin/env bash

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

# Setup shared between multiple systems

set -euo pipefail

yb_start_group "Creating the yugabyteci user"
if [[ $OSTYPE == linux* ]]; then
  if [[ -f /etc/redhat-release ]]; then
    adduser yugabyteci
  else
    adduser --disabled-password --gecos "" yugabyteci
  fi
fi
yb_end_group

cd "${BASH_SOURCE[0]%/*}"

yb_start_group "Creating the /opt/yb-build directory hierarchy"
bash ./create_opt_yb-build_dirs.sh
yb_end_group

# These scripts might not executable once copied into the Docker container.
yb_start_group "Installing the hub tool for interacting with GitHub"
bash ./install_hub_tool.sh
yb_end_group

yb_start_group "Instaling the Ninja build system"
bash ./install_ninja.sh
yb_end_group

yb_start_group "Installing CMake"
bash ./install_cmake.sh
yb_end_group

yb_start_group "Installing shellcheck"
bash ./install_shellcheck.sh
yb_end_group

yb_start_group "Installing Apache Maven"
bash ./install_maven.sh
yb_end_group
