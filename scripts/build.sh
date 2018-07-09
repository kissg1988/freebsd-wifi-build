#!/usr/local/bin/bash -eu

# NOTE: this script should be placed in the parent directory of the dir where freebsd-wifi-build is residing, ie.:
# | freebsd_build -> place this script here
# |-- freebsd-wifi-build
# |-- src

### CONFIGURATION ###
# FreeBSD branch to use - eg. master, release/X.Y.Z
export FREEBSD_BRANCH="release/11.2.0"
# name of freebsd-wifi configuration file to use
export FBSDWIFI_CFG="tl-wr1043nd"
#####################

if [ ! -x $(which sudo) ]
then
    echo "*** ERROR: please install sudo first and configure it so that the current user"
    echo "*** can issue commands as root without entering the password."
    exit 1
fi

sudo pkg -o ASSUME_ALWAYS_YES=true install fakeroot gmake bison dialog4ports git wget subversion lzma libtool mips-xtoolchain-gcc rsync

export BASEDIR=$(pwd)

mkdir -p "${BASEDIR}"/{src,freebsd-wifi-build}

trap "cd \"${BASEDIR}\"" TERM INT EXIT ERR

cat > "${HOME}/.freebsd-wifi-build-settings.cfg" << EOF
X_SKIP_MORE_STUFF=YES
X_FORCE_TFTPCP=YES
X_SETX_DEBUG=NO
EOF

cd "${BASEDIR}/freebsd-wifi-build"

[ -d .git ] && \
    git pull || \
    git clone https://github.com/kissg1988/freebsd-wifi-build.git .

cd "${BASEDIR}/src"

[ -d .git ] && \
    git pull || \
    git clone git://github.com/freebsd/freebsd.git --branch "${FREEBSD_BRANCH}" --single-branch .

# Copy customized kernel config
#cp -f "${BASEDIR}/WN-1043ND_custom" "${BASEDIR}/src/sys/mips/conf"
#cp -f "${BASEDIR}/WN-1043ND_custom.hints" "${BASEDIR}/src/sys/mips/conf"

# Copy customized build cfg
#cp -f "${BASEDIR}/wr1043nd_custom" "${BASEDIR}/freebsd-wifi-build/build/cfg"

# Patch bsdbox
if [ ! -f "${BASEDIR}/.bsdbox_patched" ]
then
	git apply -v < ../freebsd-wifi-build/bsdbox_add-commands.patch
	touch "${BASEDIR}/.bsdbox_patched"
fi

../freebsd-wifi-build/build/bin/build "${FBSDWIFI_CFG}" cleanobj cleanroot
rm -rf "${BASEDIR}/mfsroot/"{${FBSDWIFI_CFG},METALOG.${FBSDWIFI_CFG}*}
../freebsd-wifi-build/build/bin/build "${FBSDWIFI_CFG}"

echo "*** DONE! ***"
