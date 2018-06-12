#!/bin/bash

source "$(git rev-parse --show-toplevel)/utils.v1.bash"

set_strict_mode

function fetch_archive_llvm_binary_release {
  # The identifier for the current system used in binary release url generation.
  local -r system_id="$1"

  local -r extracted_dirname="clang+llvm-${LLVM_VERSION}-x86_64-${system_id}"
  local -r archive_filename="${extracted_dirname}.tar.xz"

  local -r release_url="https://releases.llvm.org/${LLVM_VERSION}/${archive_filename}"

  curl_file_with_fail "$release_url" "$archive_filename"
}

readonly TARGET_PLATFORM="$1" LLVM_VERSION="$2"

case "$TARGET_PLATFORM" in
  osx)
    with_pushd "$(mkdirp_absolute_path "llvm-${LLVM_VERSION}-osx")" \
               fetch_archive_llvm_binary_release 'apple-darwin'
    ;;
  linux)
    with_pushd "$(mkdirp_absolute_path "llvm-${LLVM_VERSION}-linux")" \
               fetch_archive_llvm_binary_release 'linux-gnu-ubuntu-16.04'
    ;;
  *)
    die "llvm does not support building for '${TARGET_PLATFORM}'"
    ;;
esac
