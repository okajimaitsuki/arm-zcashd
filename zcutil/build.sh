#!/usr/bin/env /bin/bash

echo "if this script finished with exec format error, Enter this command and try again."
echo "   rm $(pwd)/depends/aarch64-unknown-linux-gnu/native/bin/rustc"
echo "   ln -x /usr/bin/rustc $(pwd)/depends/aarch64-unknown-linux-gnu/native/bin/rustc"
read -p "Press return to continue..."

if [ -e SetupProccessFinished ]
    then
    echo "Noticed that this script is running for more than 2 times."
    echo "Skipping Setup Process..."
    else
    echo Installing clang to avoid downloading amd64 version clang...
    sudo apt install clang
    echo True > SetupProccessFinished
    sudo ln -s /usr/bin/g++ /usr/local/bin/aarch64-unknown-linux-gnu-g++
    sudo ln -s /usr/bin/ar /usr/local/bin/aarch64-unknown-linux-gnu-ar
    sudo ln -s /usr/bin/ranlib /usr/local/bin/aarch64-unknown-linux-gnu-ranlib
    sudo ln -s /usr/bin/gcc /usr/local/bin/aarch64-unknown-linux-gnu-gcc
    sudo ln -s /usr/bin/nm /usr/local/bin/aarch64-unknown-linux-gnu-nm
fi

export LC_ALL=C
set -eu -o pipefail
set +x

function cmd_pref() {
    if type -p "$2" > /dev/null; then
        eval "$1=$2"
    else
        eval "$1=$3"
    fi
}

# If a g-prefixed version of the command exists, use it preferentially.
function gprefix() {
    cmd_pref "$1" "g$2" "$2"
}

gprefix READLINK readlink
cd "$(dirname "$("$READLINK" -f "$0")")/.."

# Allow user overrides to $MAKE. Typical usage for users who need it:
#   MAKE=gmake ./zcutil/build.sh -j$(nproc)
if [[ -z "${MAKE-}" ]]; then
    MAKE=make
fi

# Allow overrides to $BUILD and $HOST for porters. Most users will not need it.
#   BUILD=i686-pc-linux-gnu ./zcutil/build.sh
if [[ -z "${BUILD-}" ]]; then
    BUILD="$(./depends/config.guess)"
fi
if [[ -z "${HOST-}" ]]; then
    HOST="$BUILD"
fi

# Allow users to set arbitrary compile flags. Most users will not need this.
if [[ -z "${CONFIGURE_FLAGS-}" ]]; then
    CONFIGURE_FLAGS=""
fi

if [ "x$*" = 'x--help' ]
then
    cat <<EOF
Usage:

$0 --help
  Show this help message and exit.

$0 [ MAKEARGS... ]
  Build Zcash and most of its transitive dependencies from
  source. MAKEARGS are applied to both dependencies and Zcash itself.

  Pass flags to ./configure using the CONFIGURE_FLAGS environment variable.
  For example, to enable coverage instrumentation (thus enabling "make cov"
  to work), call:

      CONFIGURE_FLAGS="--enable-lcov --disable-hardening" ./zcutil/build.sh

  For verbose output, use:
      ./zcutil/build.sh V=1
EOF
    exit 0
fi

set -x

eval "$MAKE" --version
as --version

HOST="$HOST" BUILD="$BUILD" "$MAKE" "$@" -C ./depends/

if [ "${BUILD_STAGE:-all}" = "depends" ]
then
    exit 0
fi

./autogen.sh
CONFIG_SITE="$PWD/depends/$HOST/share/config.site" ./configure $CONFIGURE_FLAGS
"$MAKE" "$@"
