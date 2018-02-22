#!/bin/bash

# Only for MacOS: this is a path to an osx binary for llvm-config, which is
# needed to compile cctools. After running ./build-llvm-5.0.1.sh, llvm-config
# should be located at something like:
# llvm-build/clang+llvm-5.0.1-final-x86_64-apple-darwin/bin/llvm-config
LLVM_CONFIG_LOCATION="$1"

# Put safe mode below extracting arguments so we don't choke if this is run with
# no arguments (valid for Linux).
set -euxo pipefail

LINKER_TOOLS_SUPPORTDIR='build-support/bin/linker-tools'
LINKER_TOOLS_PANTS_ARCHIVE_NAME='linker-tools.tar.gz'
# NB: This script produces a tar archive with the same file paths for linux and
# osx, but the file contents are platform-specific. Linux uses the binutils 2.30
# release ($BINUTILS_VERSION), while OSX uses a SHA from a github repo
# ($CCTOOLS_SHA). Combining the versions in this way makes it more difficult to
# accidentally use incorrect versions.
LINKER_TOOLS_VERSION='2.30-e527b6f8'
LINKER_TOOLS_BUILD_TMP_DIR='linker-tools'

# default to -j2
MAKE_JOBS="${MAKE_JOBS:-2}"


## Linux (binutils, from source release)
BINUTILS_VERSION='2.30'
BINUTILS_TMP_ARCHIVE_CREATION_DIR='binutils-tmp'

function make_binutils {
  if ! hash xz; then
    cat >&2 <<EOF
'xz' is required to run this script. You may have to install it using your
operating system's package manager.
EOF
    exit 1
  fi

  mkdir -p "$LINKER_TOOLS_BUILD_TMP_DIR"
  pushd "$LINKER_TOOLS_BUILD_TMP_DIR"

  curl -L -O "https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.xz"
  tar xf "binutils-${BINUTILS_VERSION}.tar.xz"
  pushd "binutils-${BINUTILS_VERSION}"

  ./configure
  make -j"$MAKE_JOBS"

  popd

  rm -rf "$BINUTILS_TMP_ARCHIVE_CREATION_DIR"
  mkdir "$BINUTILS_TMP_ARCHIVE_CREATION_DIR"
  pushd "$BINUTILS_TMP_ARCHIVE_CREATION_DIR"

  mkdir bin
  cp "../binutils-${BINUTILS_VERSION}/ld/ld-new" bin/ld
  tar cvzf "$LINKER_TOOLS_PANTS_ARCHIVE_NAME" \
      bin/ld
  local linker_tools_linux_packaged_abs="$(pwd)/${LINKER_TOOLS_PANTS_ARCHIVE_NAME}"

  popd

  popd

  mkdir -p "${LINKER_TOOLS_SUPPORTDIR}/linux/x86_64/${LINKER_TOOLS_VERSION}"
  cp "$linker_tools_linux_packaged_abs" "${LINKER_TOOLS_SUPPORTDIR}/linux/x86_64/${LINKER_TOOLS_VERSION}/${LINKER_TOOLS_PANTS_ARCHIVE_NAME}"
}



## MacOS (cctools, from github source)
MACOS_REVS=(
  10.7
  10.8
  10.9
  10.10
  10.11
  10.12
  10.13
)

CCTOOLS_REPO_URL='https://github.com/tpoechtrager/cctools-port'
CCTOOLS_SHA='e527b6f87f0613de7ec6d214f81d41fb5621a5b0'
CCTOOLS_TMP_ARCHIVE_CREATION_DIR='cctools-tmp'

function make_cctools {
  # Compilation fails if any gnu tools are used -- since this isn't run in a
  # virtual machine, ensure that default osx tools are used instead of
  # e.g. homebrew.
  local prevpath="$PATH"
  PATH="/bin:/usr/bin:${prevpath}"

  mkdir -p "$LINKER_TOOLS_BUILD_TMP_DIR"
  pushd "$LINKER_TOOLS_BUILD_TMP_DIR"

  rm -rf 'cctools-port'
  git clone --depth 1 "$CCTOOLS_REPO_URL"
  pushd 'cctools-port'
  git checkout "$CCTOOLS_SHA"

  pushd 'cctools'

  ./configure --with-llvm-config="$LLVM_CONFIG_LOCATION"

  make -j"$MAKE_JOBS"

  popd
  popd

  mkdir -p "$CCTOOLS_TMP_ARCHIVE_CREATION_DIR"
  pushd "$CCTOOLS_TMP_ARCHIVE_CREATION_DIR"

  mkdir -p bin
  cp '../cctools-port/cctools/ld64/src/ld/ld' bin/ld
  tar cvzf "$LINKER_TOOLS_PANTS_ARCHIVE_NAME" \
      bin/ld
  local linker_tools_macos_packaged_abs="$(pwd)/${LINKER_TOOLS_PANTS_ARCHIVE_NAME}"
  popd

  popd

  for rev in ${MACOS_REVS[@]}; do
    dest_base="${LINKER_TOOLS_SUPPORTDIR}/mac/${rev}/${LINKER_TOOLS_VERSION}"
    mkdir -p "$dest_base"
    cp "$linker_tools_macos_packaged_abs" "${dest_base}/${LINKER_TOOLS_PANTS_ARCHIVE_NAME}"
  done

  PATH="${prevpath}"
}


## Run the appropriate build function.
cur_plat="$(uname)"

case "$cur_plat" in
  ( Darwin )
  if [[ ! -x "$LLVM_CONFIG_LOCATION" ]]; then
    cat >&2 <<EOF
The first argument '$LLVM_CONFIG_LOCATION' does not exist or is not an
executable file. Please run this script again with the first argument pointing
to a binary for the llvm-config tool.
EOF
    exit 1
  fi
  make_cctools
  ;;
  ( Linux )
  make_binutils
  ;;
  ( * )
  echo "unrecognized platform '${cur_plat}'" >&2
  exit 1
esac
