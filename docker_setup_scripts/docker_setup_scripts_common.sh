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

  apt-get install -y locales

  # Uncomment en_US.UTF-8 for inclusion in locale generation.
  sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen

  # Generate locale
  locale-gen

  export LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LANGUAGE=en_US.UTF-8
}

yb_redhat_init_locale() {
  set +e
  local localedef_err_path=/tmp/localedef.err
  ( set -x; localedef -v -c -i en_US -f UTF-8 en_US.UTF-8 --quiet 2>"$localedef_err_path" )
  # localedef, if executed without --quiet, will usually show some warnings like
  # [warning] LC_IDENTIFICATION: field `audience' not defined
  # [warning] LC_IDENTIFICATION: field `application' not defined
  # [warning] LC_IDENTIFICATION: field `abbreviation' not defined
  # [verbose] LC_CTYPE: table for class "upper": 3264919828641826143 bytes
  # [verbose] LC_CTYPE: table for class "lower": 4051037683542732370 bytes
  # [verbose] LC_CTYPE: table for class "alpha": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "digit": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "xdigit": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "space": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "print": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "graph": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "blank": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "cntrl": 18446744069414584898 bytes
  # [verbose] LC_CTYPE: table for class "punct": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "alnum": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "combining": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for class "combining_level3": 18446744073709551615 bytes
  # [verbose] LC_CTYPE: table for map "toupper": 0 bytes
  # [verbose] LC_CTYPE: table for map "totitle": 50331645 bytes
  # [verbose] LC_CTYPE: table for width: 0 bytes
  local localedef_exit_code=$?
  set -e
  echo "localedef returned exit code $localedef_exit_code (expecting 0 or 1)"
  if [[ -s $localedef_err_path ]]; then
    echo >&2 "Non-empty error output from localedef:"
    cat >&2 "/tmp/localedeferr"
    exit 1
  fi
  rm -f "$localedef_err_path"
  if [[ $localedef_exit_code -ne 0 && $localedef_exit_code -ne 1 ]]; then
    echo >&2 "Unexpected exit code from localedef, expected 0 or 1, got: $localedef_exit_code"
    exit 1
  fi
}

yb_debian_init() {
  export DEBIAN_FRONTEND=noninteractive
  yb_debian_init_locale
}

yb_start_group() {
  if [[ $# -ne 1 ]]; then
    echo >&2 "The yb_start_group requires exactly one parameter"
  fi
  echo "::group::$1"
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

yb_install_packages_separately() {
  local package_type=$1
  local package_manager=$2
  shift 2

  yb_start_group "Installing $package_type packages"
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

yb_apt_install_packages_separately() {
  yb_install_packages_separately "Debian/Ubuntu (apt)" "apt-get" "$@"
}

yb_zypper_install_packages_separately() {
  yb_install_packages_separately "OpenSUSE Zypper (rpm)" "zypper" "$@"
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
}

yb_create_opt_yb_build_hierarchy() {
  local dir_name
  local top_level_dir=/opt/yb-build
  mkdir -p "$top_level_dir"
  chmod 777 "$top_level_dir"

  for dir_name in brew download_cache thirdparty tmp llvm spark; do
    dir_path=$top_level_dir/$dir_name
    (
      set -x
      mkdir -p "$dir_path"
      chmod 777 "$dir_path"
    )
  done
}

yb_create_yugabyteci_user() {
  local user_name=yugabyteci
  yb_start_group "Creating the $user_name user"
  if [[ $OSTYPE == linux* ]]; then
    # Note there is no closing double quote in the string that we search for to detect OpenSUSE.
    if grep -q 'ID="opensuse' /etc/os-release; then
      useradd "$user_name" --create-home
    elif [[ -f /etc/redhat-release ]]; then
      adduser "$user_name"
    else
      adduser --disabled-password --gecos "" "$user_name"
    fi
  fi
  yb_end_group
}

yb_install_hub_tool() {
  yb_start_group "Installing the hub tool for interacting with GitHub"
  bash "$yb_build_infra_scripts_dir/install_hub_tool.sh"
  yb_end_group
}

yb_install_ninja_from_source() {
  yb_start_group "Instaling the Ninja build system"
  bash "$yb_build_infra_scripts_dir/install_ninja.sh"
  yb_end_group
}

yb_install_cmake_from_source() {
  yb_start_group "Installing CMake"
  bash "$yb_build_infra_scripts_dir/install_cmake.sh"
  yb_end_group
}

yb_install_shellcheck() {
  yb_start_group "Installing shellcheck"
  bash "$yb_build_infra_scripts_dir/install_shellcheck.sh"
  yb_end_group
}

yb_install_maven() {
  yb_start_group "Installing Apache Maven"
  bash "$yb_build_infra_scripts_dir/install_maven.sh"
  yb_end_group
}

yb_install_python3_from_source() {
  yb_start_group "Installing Python 3 from source"
  bash "$yb_build_infra_scripts_dir/install_python3_from_source.sh"
  yb_end_group
}

yb_install_spark() {
  yb_start_group "Installing Spark"
  bash "$yb_build_infra_scripts_dir/install_spark.sh"
  yb_end_group
}

yb_perform_os_independent_steps() {
  yb_create_yugabyteci_user
  yb_install_hub_tool
  yb_install_shellcheck
  yb_install_maven
  yb_create_opt_yb_build_hierarchy
  yb_install_spark
}

yb_yum_cleanup() {
  start_group "Yum cleanup"
  yum clean all
  end_group
}