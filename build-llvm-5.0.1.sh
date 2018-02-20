#!/bin/sh

set -euxo pipefail

LLVM_VERSION='5.0.1'
CORRESPONDING_CLANG_BIN_VERSION='5.0'
LLVM_RELEASE_BUILD_DIRNAME='build'
LLVM_PANTS_ARCHIVE_NAME='llvm.tar.gz'

LLVM_RELEASE_UNPACKED_ARCHIVE_DIRNAME="llvm-${LLVM_VERSION}.src"
LLVM_RELEASE_ARCHIVE_NAME="${LLVM_RELEASE_UNPACKED_ARCHIVE_DIRNAME}.tar.xz"
LLVM_RELEASE_ARCHIVE_URL="http://releases.llvm.org/${LLVM_VERSION}/${LLVM_RELEASE_ARCHIVE_NAME}"

CLANG_RELEASE_UNPACKED_ARCHIVE_DIRNAME="cfe-${LLVM_VERSION}.src"
CLANG_RELEASE_ARCHIVE_NAME="${CLANG_RELEASE_UNPACKED_ARCHIVE_DIRNAME}.tar.xz"
CLANG_RELEASE_ARCHIVE_URL="http://releases.llvm.org/${LLVM_VERSION}/${CLANG_RELEASE_ARCHIVE_NAME}"

tmp_dir="llvm-${LLVM_VERSION}-tmp-workdir"

mkdir -p "$tmp_dir" && pushd "$tmp_dir"

curl -L -v -O "$LLVM_RELEASE_ARCHIVE_URL" \
  && tar xvf "$LLVM_RELEASE_ARCHIVE_NAME"

curl -L -v -O "$CLANG_RELEASE_ARCHIVE_URL" \
  && tar xvf "$CLANG_RELEASE_ARCHIVE_NAME"

mkdir -p "$LLVM_RELEASE_BUILD_DIRNAME" && pushd "$LLVM_RELEASE_BUILD_DIRNAME"

cmake \
  -DLLVM_EXTERNAL_CLANG_SOURCE_DIR="../${CLANG_RELEASE_UNPACKED_ARCHIVE_DIRNAME}" \
  -DLLVM_EXTERNAL_PROJECTS='clang' \
  "../${LLVM_RELEASE_UNPACKED_ARCHIVE_DIRNAME}"

# default to -j2
MAKE_JOBS="${MAKE_JOBS:-2}"
make -j"$MAKE_JOBS"

tar cvzf "$LLVM_PANTS_ARCHIVE_NAME" \
    bin/clang \
    bin/clang++ \
    "bin/clang-${CORRESPONDING_CLANG_BIN_VERSION}"
