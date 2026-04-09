#!/usr/bin/env bash
set -euo pipefail

zulu_arch() {
  if [ -z ${zarch+x} ]; then # we haven't been called yet
    case $(uname -m) in
    x86_64)
      zarch=x64
      ;;
    aarch64)
      zarch=aarch64
      ;;
    *)
      echo "Uknown arch: '$(uname -m)'!"
      ;;
    esac
  fi
  echo $zarch
}

# Remove system openjdk
source /etc/os-release
case "$ID" in
  almalinux)
    dnf remove "*-openjdk-*" -y
    ;;
  *)
    echo "Not removing openjdk on $ID"
    ;;
esac

# we require curl so just quit now if it isn't available
curl --version >/dev/null

# https://cdn.azul.com/zulu/bin/zulu25.32.21-ca-jdk25.0.2-linux_aarch64.tar.gz
zulu_url=https://cdn.azul.com/zulu/bin
jvm_dir=/usr/lib/jvm
declare -A zulu_pkgs

# JDK 8
zulu_pkgs['8,version']=8.92.0.21-ca-jdk8.0.482
zulu_pkgs['8,shasum_x64']=dbb1d5580afe8379d8457397c868e4a4b9c82798ac1cf0f7ee6842dfa3e7fd5d
zulu_pkgs['8,shasum_aarch64']=14a0ca3c75676b65c97e1937664ba33c204769d71297013780a5d19dbc73dff3

# JDK 11
zulu_pkgs['11,version']=11.86.21-ca-jdk11.0.30
zulu_pkgs['11,shasum_x64']=88175af4f67ccd51a0bd0b461af11e83511cd7b38bbe79259c0a545431bf636b
zulu_pkgs['11,shasum_aarch64']=dd1ca3e89ba93cf43fa966503e2a91aeed658fa726acccb37775f5668f1ec8b7

# JDK 17
zulu_pkgs['17,version']=17.64.17-ca-jdk17.0.18
zulu_pkgs['17,shasum_x64']=819e3f09ea628901a21b2104ed8f5256e17ae91a4145b272b2eb2131f832af1d
zulu_pkgs['17,shasum_aarch64']=db57dc9e1f8222c2f8efad38c8ca360b1011d8b9fb9bea0956d86cd75e7b2dbd

# JDK 25
zulu_pkgs['25,version']=25.32.21-ca-jdk25.0.2
zulu_pkgs['25,shasum_x64']=946ad9766d98fc6ab495a1a120072197db54997f6925fb96680f1ecd5591db4e
zulu_pkgs['25,shasum_aarch64']=9903c6b19183a33725ca1dfdae5b72400c9d00995c76fafc4a0d31c5152f33f7

# Ensure the jvm directory exists
mkdir -p "${jvm_dir}"

ztmp=$(mktemp -d)
trap "{ rm -rf ${ztmp}; }" EXIT
cd ${ztmp}
for a in 8 11 17 25; do
  dest="${jvm_dir}/zulu-${a}.jdk"
  if [[ -d "${dest}" ]]; then
    echo "Skipping jdk$a as its already present"
    continue
  fi
  pkg_name="zulu${zulu_pkgs[${a},version]}-linux_$(zulu_arch).tar.gz"
  pkg_sha="${zulu_pkgs[${a},shasum_$(zulu_arch)]}"
  mkdir $a
  (
    cd $a
    curl -O "${zulu_url}/${pkg_name}"
    # set -e above so this will exit the script if the sha is wrong
    sha256sum $pkg_name | grep $pkg_sha
    tar xf "${pkg_name}"
    mv "$(basename ${pkg_name} .tar.gz)" "${jvm_dir}/zulu-${a}.jdk"
  )
done

altcmd=''
if command -v alternatives; then
  altcmd=alternatives
elif command -v update-alternatives; then
  altcmd=update-alternatives
else
  echo "no 'alternatives/update-alternatives' command found"
fi

# Ensure there is a default JAVA_HOME variable set
if [[ -d /etc/profile.d ]]; then
  echo export JAVA_HOME=${jvm_dir}/zulu-17.jdk > /etc/profile.d/java_home.sh
fi

for j in java javac jstack jinfo; do
  if [[ -n "${altcmd}" ]]; then
    ${altcmd} --install "/usr/bin/${j}" "${j}" "${jvm_dir}/zulu-17.jdk/bin/${j}" 900
  else
    # no alternatives command so just create symlinks to /usr/local/bin instead
    ln -s "${jvm_dir}/zulu-17.jdk/bin/${j}" "/usr/local/bin/${j}"
  fi
done

