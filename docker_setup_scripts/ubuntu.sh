#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=docker_setup_scripts/docker_setup_scripts_common.sh
. "${BASH_SOURCE%/*}/docker_setup_scripts_common.sh"

# shellcheck disable=SC1091
. /etc/lsb-release
ubuntu_major_version=${DISTRIB_RELEASE%%.*}

yb_determine_ubuntu_packages
yb_debian_configure_and_install_packages "${ubuntu_packages[@]}"
yb_perform_universal_steps
yb_install_arc
yb_remove_build_infra_scripts
