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
    "en_US"
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
      set -x
      # See the link below regarding avoiding some of the errors.
      # We treat any errors in stderr as fatal.
      # https://stackoverflow.com/questions/30736238/centos-7-docker-image-and-locale-compilation
      localedef --force \
                --quiet \
                "--inputfile=${locale_name}" \
                "--charmap=UTF-8" \
                "${locale_name}.UTF-8" \
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
      cat >&2 "${localedef_err_path}"
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
  if [[ $ubuntu_major_version -ne 22 ]]; then
    apt-get install software-properties-common -y
    add-apt-repository ppa:deadsnakes/ppa -y
  fi
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

# Sets the ubuntu_packages global variable to the list of packages to be installed.
yb_determine_ubuntu_packages() {
  if [[ -z "${ubuntu_major_version:-}" ]]; then
    echo >&2 "ubuntu_major_version is not set"
    exit 1
  fi
  ubuntu_packages=(
    apt-file
    apt-utils
    automake
    bison
    curl
    flex
    git
    groff-base
    less
    libasan5
    libbz2-dev
    libicu-dev
    libncurses5-dev
    libreadline-dev
    libssl-dev
    libtool
    libtsan0
    locales
    maven
    ninja-build
    openjdk-8-jdk-headless
    patchelf
    pkg-config
    python3-dev
    python3-pip
    python3-venv
    python3-wheel
    python3.11
    python3.11-venv
    rsync
    sudo
    tzdata
    unzip
    uuid-dev
    vim
    wget
    xz-utils
  )
  local gcc_versions=()
  if [[ $ubuntu_major_version -eq 20 ]]; then
    gcc_versions+=( 10 )
  fi

  if [[ $ubuntu_major_version -ge 22 ]]; then
    gcc_versions+=( 11 12  )
  fi
  if [[ $ubuntu_major_version -ge 24 ]]; then
    gcc_versions+=( 13 )
  fi
  echo "Ubuntu major version: $ubuntu_major_version"
  echo "The following GCC versions will be installed: ${gcc_versions[*]}"
  for gcc_version in "${gcc_versions[@]}"; do
    # Apparently apt interprets the argument as a regex, which could result in matching Clang
    # for GCC (or there might be some internal logic for that). Let's quote the pluses for safety.
    ubuntu_packages+=(
      "gcc-${gcc_version}"
      "g[+][+]-${gcc_version}"
    )
  done
  echo "Full list of packages to be installed: ${ubuntu_packages[*]}"
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
    if [[ -f /etc/redhat-release ]]; then
      adduser "$user_name"
    elif grep -q 'ID="amzn' /etc/os-release; then
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

yb_install_spark() {
  yb_start_group "Installing Spark"
  bash "$yb_build_infra_scripts_dir/install_spark.sh"
  yb_end_group
}

yb_install_rust() {
  yb_start_group "Installing Rust"
  bash "$yb_build_infra_scripts_dir/install_rust.sh"
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

yb_install_bazel() {
  local bazel_version=5.3.1
  yb_start_group "Installing Bazel ${bazel_version}"

  local expected_sha256
  local arch_in_pkg_name
  case "$( uname -m )" in
    aarch64)
      expected_sha256=42b92684d39c1a7a14f73ca3543d57f22689ec7ccc80b4dcaac061abffccd288
      arch_in_pkg_name=arm64
    ;;
    x86_64)
      expected_sha256=f680a8a35789fb550c966a9a6661349af6993edd5ebf85bfb0f22e968c78115a
      arch_in_pkg_name=x86_64
    ;;
    *)
      echo >&2 "Unknown architecture $( uname -m )"
      exit 1
    ;;
  esac

  local bazel_archive_name="bazel-${bazel_version}-linux-${arch_in_pkg_name}"
  local bazel_downloads_url="https://github.com/bazelbuild/bazel/releases/download/${bazel_version}"
  local bazel_url="${bazel_downloads_url}/${bazel_archive_name}"
  local bazel_install_parent_dir="/opt/bazel"
  local bazel_install_path="${bazel_install_parent_dir}/${bazel_archive_name}"

  (
    mkdir -p "${bazel_install_parent_dir}"
    cd "${bazel_install_parent_dir}"
    curl --location --remote-name "${bazel_url}"
    chmod +x "${bazel_archive_name}"
    actual_sha256=$( sha256sum "${bazel_archive_name}" | awk '{print $1}' )
    if [[ ${actual_sha256} != "${expected_sha256}" ]]; then
      echo >&2 "Invalid SHA256 sum of ${bazel_archive_name}: expected ${expected_sha256}, got" \
                "${actual_sha256}"
      exit 1
    fi
    mkdir -p /usr/local/bin
    ln -s "${bazel_install_path}" "/usr/local/bin/bazel"
  )

  # Test that Bazel works.
  bazel --version
  yb_end_group
}

readonly GO_PACKAGES=( github.com/bazelbuild/buildtools/buildozer@5.1.0 )
yb_install_go_packages() {
  GOPATH=$HOME/go
  local package
  for package in "${GO_PACKAGES[@]}"; do
    go install "${package}"
  done
  mv "$GOPATH/bin/"* /usr/local/bin
  rm -rf "$GOPATH"
}

yb_perform_universal_steps() {
  yb_create_yugabyteci_user
  yb_install_golang
  yb_install_hub_tool
  yb_install_shellcheck
  yb_install_maven
  yb_create_opt_yb_build_hierarchy
  yb_install_spark
  yb_install_rust
  yb_install_go_packages
  yb_install_bazel
  yb_install_cmake
}

run_cmd_hide_output_if_ok() {
  local out_prefix
  out_prefix=/tmp/cmd_output_$( date +%Y-%m-%dT%H_%M_%S )_${RANDOM}_${RANDOM}_${RANDOM}
  local stdout_path=${out_prefix}.out
  local stderr_path=${out_prefix}.err
  set +e
  ( set -x; "$@" >"${stdout_path}" 2>"${stderr_path}" )
  local exit_code=$?
  set -e
  if [[ ${exit_code} != 0 ]]; then
    (
      echo "Command failed with with exit code ${exit_code}: $*"
      echo "Standard output from command: $*"
      cat "${stdout_path}"
      echo "Standard error from command: $*"
      cat "${stderr_path}"
    ) >&2
    exit "${exit_code}"
  fi
  rm -f "${stdout_path}" "${stderr_path}"
}

yb_fatal_unknown_architecture() {
  echo >&2 "Unknown architecture: $( uname -m )"
  exit 1
}
