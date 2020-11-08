#!/usr/bin/env

set -euo pipefail
readonly URL_PREFIX=https://github.com/yugabyte/build-clang/releases/download

llvm_major_version=11
llvm_tarball_version=v${llvm_major_version}.0.0-v4
llvm_dir_name=llvm-$llvm_tarball_version
tarball_name=$llvm_dir_name.tar.gz
url=$URL_PREFIX/$llvm_tarball_version/$tarball_name
cd /opt/yb-build/llvm
wget "$url"

actual_sha256sum=$( sha256sum "$tarball_name" | awk '{print $1}')
expected_sha256sum="85618e7fb91e80a37c26e02e7113d5fbbd4edc50779ca78b0170d6f7911f03b4"
if [[ $actual_sha256sum != $expected_sha256sum ]]; then
  echo "Checksum mismatch for $tarball_name: expected $expected_sha256sum," \
       "got $actual_sha256sum" >&2
  exit 1
fi

tar xzf "$tarball_name"
rm -f "$tarball_name"
installed_llvm_bin_dir=$PWD/$llvm_dir_name/bin
if [[ ! -d $installed_llvm_bin_dir ]]; then
  echo "Directory does not exist: $installed_llvm_bin_dir" >&2
  exit 1
fi

symlink_parent_dir=/usr/local/bin
mkdir -p "$symlink_parent_dir"

# This is based on symlinks created by LLVM/Clang packages in /usr/bin on Ubuntu.
readonly LLVM_TOOLS_TO_LINK=(
    FileCheck
    bugpoint
    c-index-test
    clang
    clang++
    clang-apply-replacements
    clang-change-namespace
    clang-check
    clang-cl
    clang-cpp
    clang-doc
    clang-extdef-mapping
    clang-format
    clang-include-fixer
    clang-move
    clang-offload-bundler
    clang-offload-wrapper
    clang-query
    clang-refactor
    clang-rename
    clang-reorder-fields
    clang-scan-deps
    clangd
    count
    diagtool
    dsymutil
    find-all-symbols
    git-clang-format
    hmaptool
    ld.lld
    ld64.lld
    llc
    lld
    lld-link
    lldb
    lldb-argdumper
    lldb-instr
    lldb-server
    lldb-vscode
    lli
    lli-child-target
    llvm-PerfectShuffle
    llvm-addr2line
    llvm-ar
    llvm-as
    llvm-bcanalyzer
    llvm-c-test
    llvm-cat
    llvm-cfi-verify
    llvm-config
    llvm-cov
    llvm-cvtres
    llvm-cxxdump
    llvm-cxxfilt
    llvm-cxxmap
    llvm-diff
    llvm-dis
    llvm-dlltool
    llvm-dwarfdump
    llvm-dwp
    llvm-elfabi
    llvm-exegesis
    llvm-extract
    llvm-gsymutil
    llvm-ifs
    llvm-install-name-tool
    llvm-jitlink
    llvm-lib
    llvm-link
    llvm-lipo
    llvm-lto
    llvm-lto2
    llvm-mc
    llvm-mca
    llvm-ml
    llvm-modextract
    llvm-mt
    llvm-nm
    llvm-objcopy
    llvm-objdump
    llvm-opt-report
    llvm-pdbutil
    llvm-profdata
    llvm-ranlib
    llvm-rc
    llvm-readelf
    llvm-readobj
    llvm-reduce
    llvm-rtdyld
    llvm-size
    llvm-split
    llvm-stress
    llvm-strings
    llvm-strip
    llvm-symbolizer
    llvm-tblgen
    llvm-undname
    llvm-xray
    modularize
    not
    obj2yaml
    opt
    pp-trace
    sancov
    sanstats
    verify-uselistorder
    wasm-ld
    yaml-bench
    yaml2obj
)

for tool_name in "${LLVM_TOOLS_TO_LINK[@]}"; do
  tool_path=$installed_llvm_bin_dir/$tool_name
  link_path=/usr/local/bin/$tool_name-$llvm_major_version
  if [[ -f $tool_path ]]; then
    ( set -x; ln -s "$tool_path" "$link_path" )
  else
    echo "LLVM/Clang tool does not exist: $tool_path, not creating a symlink at" \
         "$link_path" >&2
  fi
done