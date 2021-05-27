#!/usr/bin/env bash

set -euo pipefail

yb_remove_build_infra_scripts() {
  if [[ $yb_build_infra_scripts_dir =~ ^/tmp/ ]]; then
    ( set -x; rm -rf "$yb_build_infra_scripts_dir" )
  else
    echo >&2 "Not removing '$yb_build_infra_scripts_dir', not in /tmp."
  fi
}

yb_debian_init_locale() {
  # Based on https://serverfault.com/a/894545
  apt-get update

  # Install locales package
  apt-get install -y locales

  # Uncomment en_US.UTF-8 for inclusion in generation
  sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen

  # Generate locale
  locale-gen

  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LANGUAGE=en_US.UTF-8
}

yb_start_group() {
  echo "echo ::group::$1"
}

yb_end_group() {
  echo "::endgroup::"
}

yb_apt_get_dist_upgrade() {
  yb_start_group "apt-get update and dist-upgrade"
  apt-get update
  apt-get dist-upgrade -y
  yb_end_group
}

yb_apt_cleanup() {
  yb_start_group "apt cleanup"
  apt-get -y clean
  apt-get -y autoremove
  yb_end_group
}

readonly yb_build_infra_scripts_dir=$( cd "${BASH_SOURCE[0]%/*}" && cd .. && pwd )