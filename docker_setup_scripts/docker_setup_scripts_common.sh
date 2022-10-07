#!/usr/bin/env bash

set -euo pipefail

yb_build_infra_scripts_dir=$( cd "${BASH_SOURCE[0]%/*}" && pwd )
readonly yb_build_infra_scripts_dir

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
  # Locales required by Postgres.
  local locale_names=(
    "de_DE"
    "es_ES"
    "fr_FR"
    "it_IT"
    "ja_JP"
    "ko_KR"
    "pl_PL"
    "ru_RU"
    "sv_SE"
    "tr_TR"
    "zh_CN"
  )
  local locale_name
  for locale_name in "${locale_names[@]}"; do
    local localedef_err_path=/tmp/localedef.err
    set +e
    (
      set -x;
      localedef -v -c -i "${locale_name}" -f UTF-8 "${locale_name}.UTF-8" --quiet \
        2>"${localedef_err_path}"
    )
    local localedef_exit_code=$?
    set -e
    local failure=false
    if [[ ${localedef_exit_code} -ne 0 &&
          ${localedef_exit_code} -ne 1 ]]; then
      echo >&2 "localedef returned exit code ${localedef_exit_code} (expecting 0 or 1)"
      failure=true
    fi
    if [[ -s ${localedef_err_path} ]]; then
      echo >&2 "Non-empty error output from localedef:"
      cat >&2 "/tmp/localedeferr"
      failure=true
    fi
    rm -f "${localedef_err_path}"
    if [[ ${failure} == "true" ]]; then
      exit 1
    fi
  done
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
    if "${package_manager}" install -y "$package"; then
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

yb_perform_common_setup() {
  bash "$yb_build_infra_scripts_dir/perform_common_setup.sh"
}

yb_debian_configure_and_install_packages() {
  local packages=( "$@" )

  yb_apt_get_dist_upgrade
  yb_debian_init
  yb_apt_install_packages_separately "${packages[@]}"
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

yb_install_ninja() {
  yb_start_group "Instaling the Ninja build system"
  bash "$yb_build_infra_scripts_dir/install_ninja.sh"
  yb_end_group
}

yb_install_cmake() {
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

yb_yum_cleanup() {
  yb_start_group "Yum cleanup"
  ( set -x; yum clean all )
  yb_end_group
}

yb_install_golang() {
  yb_start_group "Installing Golang"

  local go_version=1.19.2
  local expected_sha256
  local arch_in_pkg_name
  case "$( uname -m )" in
    aarch64)
      expected_sha256=b62a8d9654436c67c14a0c91e931d50440541f09eb991a987536cb982903126d
      arch_in_pkg_name=arm64
    ;;
    x86_64)
      expected_sha256=5e8c5a74fe6470dd7e055a461acda8bb4050ead8c2df70f227e3ff7d8eb7eeb6
      arch_in_pkg_name=amd64
    ;;
    *)
      echo >&2 "Unknown architecture $( uname -m )"
      exit 1
    ;;
  esac

  local go_archive_name="go${go_version}.linux-${arch_in_pkg_name}.tar.gz"
  local go_url="https://go.dev/dl/${go_archive_name}"
  local tmp_dir="/tmp/go_installation"
  local go_install_parent_dir="/opt/go"
  local go_install_path="${go_install_parent_dir}/go-${go_version}"
  local go_latest_dir_link="${go_install_parent_dir}/latest"
  mkdir -p "${tmp_dir}"
  (
    cd "${tmp_dir}"
    curl --location --silent --remote-name "${go_url}"
    actual_sha256=$( sha256sum "${go_archive_name}" | awk '{print $1}' )
    if [[ ${actual_sha256} != "${expected_sha256}" ]]; then
      echo >&2 "Invalid SHA256 sum of ${go_archive_name}: expected ${expected_sha256}, got" \
               "${actual_sha256}"
      exit 1
    fi
    tar xzf "${go_archive_name}"
    mkdir -p "${go_install_parent_dir}"
    mv go "${go_install_path}"
    mkdir -p /usr/local/bin
    ln -s "${go_install_path}" "${go_latest_dir_link}"
    for binary_name in go gofmt; do
      ln -s "${go_latest_dir_link}/bin/${binary_name}" "/usr/local/bin/${binary_name}"
    done
  )
  rm -rf "${tmp_dir}"
  yb_end_group
}

yb_perform_os_independent_steps() {
  yb_create_yugabyteci_user
  yb_install_golang
  yb_install_hub_tool
  yb_install_shellcheck
  yb_install_maven
  yb_create_opt_yb_build_hierarchy
  yb_install_spark
}
