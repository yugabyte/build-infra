#!/usr/bin/env bash

set -euo pipefail

readonly yb_build_infra_scripts_dir=$( cd "${BASH_SOURCE[0]%/*}" && pwd )

yb_remove_build_infra_scripts() {
  if [[ $yb_build_infra_scripts_dir =~ ^/tmp/ ]]; then
    ( set -x; rm -rf "$yb_build_infra_scripts_dir" )
  else
    echo >&2 "Not removing '$yb_build_infra_scripts_dir', not in /tmp."
  fi
}

yb_debian_init_locale() {
  # Based on https://serverfault.com/a/894545

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

yb_debian_init() {
  export DEBIAN_FRONTEND=noninteractive
  yb_debian_init_locale
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

yb_heading() {
  echo
  echo "------------------------------------------------------------------------------------------"
  echo "$*"
  echo "------------------------------------------------------------------------------------------"
  echo
}

yb_apt_install_packages_separately() {
  yb_start_group "Installing Debian/Ubuntu packages"
  local failed_packages=()
  local num_succeeded=0
  local num_failed=0
  for package in "$@"; do
    yb_heading "Installing package $package and its dependencies"
    if apt-get install -y "$package"; then
      (( num_succeeded+=1 ))
    else
      failed_packages+=( "$package" )
      (( num_failed+=1 ))
    fi
    yb_heading "Finished installing package $package and its dependencies"
  done
  yb_end_group

  if [[ $num_failed -gt 0 ]]; then
    echo >&2 "Failed to install packages: ${failed_packages[*]}"
    return 1
  fi
  return 0
}

yb_debian_install_llvm_packages() {
  yb_start_group "Installing LLVM/Clang packages"
  bash "$yb_build_infra_scripts_dir/debian_install_llvm_packages.sh"
  yb_end_group
}

yb_perform_common_setup() {
  bash "$yb_build_infra_scripts_dir/perform_common_setup.sh"
}

yb_debian_configure_and_install_packages() {
  local packages=( "$@" )

  yb_apt_get_dist_upgrade
  yb_debian_init
  yb_apt_install_packages_separately "${packages[@]}"
  yb_debian_install_llvm_packages
  yb_apt_cleanup
  yb_remove_build_infra_scripts
}
