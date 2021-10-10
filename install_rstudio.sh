#!/bin/bash

echo "- AE5 RStudio Server Installer"

if ! grep -q /tools/ /opt/continuum/scripts/start_user.sh; then
    echo "ERROR: This version of the RStudio installer requires AE5.5.1 or later."
    exit -1
fi
    
CURRENT_DIR=$PWD
SOURCE_DIR=$(dirname "${BASH_SOURCE[0]}")
missing=
for sfile in Rprofile rsession.conf rsession.sh start_rstudio.sh; do
    spath=$CURRENT_DIR/$sfile
    [ -f $spath ] || spath=$SOURCE_DIR/$sfile
    [ -f $spath ] || missing="$missing $sfile"
done
if [ ! -z "$missing" ]; then
    echo "ERROR: missing support files:$missing"
    exit -1
fi

[ $RSTUDIO_VERSION ] || RSTUDIO_VERSION=2021.09.0-351
echo "- Target version: ${RSTUDIO_VERSION}"
[ $RSTUDIO_PREFIX ] || RSTUDIO_PREFIX=/tools/rstudio
echo "- Install prefix: ${RSTUDIO_PREFIX}"
if [ ! -d $RSTUDIO_PREFIX ]; then
    echo "ERROR: install location does not exist"
    exit -1
elif [ ! -w $RSTUDIO_PREFIX ]; then
    echo "ERROR: install location not writable"
    ls -ald $RSTUDIO_PREFIX
    id
    exit -1
elif [ ! -z "$(ls -A $RSTUDIO_PREFIX)" ]; then
    echo "ERROR: install location not empty"
    ls -al $RSTUDIO_PREFIX
    exit -1
fi

[ $RSTUDIO_WORKDIR ] || cleanup=yes
[ $RSTUDIO_WORKDIR ] || RSTUDIO_WORKDIR=$(mktemp -d) 
echo "- Working directory: ${RSTUDIO_WORKDIR}"
if [ ! -d $RSTUDIO_WORKDIR ]; then
    echo "ERROR: working directory does not exist"
    exit -1
elif [ ! -w $RSTUDIO_WORKDIR ]; then
    echo "ERROR: working directory is not writable"
    ls -ald $RSTUDIO_WORKDIR
    id
    exit -1
fi

pushd $RSTUDIO_WORKDIR

# We actually need two RPM packages: the CentOS 8 version is the version we
# use in full, but we need to extract a single binary (rsession) from the CentOS 7
# version to offer compatibility with older versions of R.
for os_ver in 8 7; do
    what_os="RHEL${os_ver}/CentOS${os_ver}"
    osdir=centos${os_ver}
    fname=rs-$osdir.rpm
    if [ -f $CURRENT_DIR/$fname ]; then
        ln -s $CURRENT_DIR/$fname .
    else
        echo "- Downloading $what_os RPM file to $fname"
        url=https://download2.rstudio.org/server/$osdir/x86_64/rstudio-server-rhel-${RSTUDIO_VERSION}-x86_64.rpm
        echo "- URL: $url"
        if ! curl -o $fname -L $url; then
           echo "- ERROR: unexpected error downloading this package. Please resolve the error and try again."
           exit -1
        elif grep -q NoSuchKey $fname; then
           echo "- ERROR: package not found as expected. Please verify the URL and try again."
           rm -f $fname
           exit -1
        fi
    fi
    echo "- Verifying $fname"
    if ! rpm2cpio $fname >/dev/null; then
        echo "- ERROR: $fname is not a valid RPM package. Please remove this file and re-download it."
        exit -1
    fi
done

echo "- Staging full RHEL8/CentOS8 package"
mkdir -p $RSTUDIO_PREFIX/staging8/usr/lib/rstudio-server
rpm2cpio rs-centos8.rpm | (cd $RSTUDIO_PREFIX/staging8 && cpio -ic "./usr/lib/rstudio-server/*")

echo "- Staging $what_os rsession binary"
mkdir -p $RSTUDIO_PREFIX/staging7/usr/lib/rstudio-server/bin
rpm2cpio $fname | (cd $RSTUDIO_PREFIX/staging7 && cpio -ic ./usr/lib/rstudio-server/bin/rsession)

echo "- Moving files into final position"
mv $RSTUDIO_PREFIX/staging8/usr/lib/rstudio-server/* $RSTUDIO_PREFIX
mv $RSTUDIO_PREFIX/staging7/usr/lib/rstudio-server/bin/rsession $RSTUDIO_PREFIX/bin/rsession10
rm -rf $RSTUDIO_PREFIX/{staging7,staging8}

echo "- Installing support files"
missing=
for sfile in Rprofile rsession.conf rsession.sh start_rstudio.sh; do
    spath=$CURRENT_DIR/$sfile
    [ -f $spath ] || spath=$SOURCE_DIR/$sfile
    cp $spath $RSTUDIO_PREFIX
done
chmod +x $RSTUDIO_PREFIX/{start_rstudio.sh,rsession.sh}

if [ $cleanup ]; then
    echo "- Cleaning up temporary files"
    popd 2>/dev/null || :
    rm -rf $RSTUDIO_WORKDIR
fi

echo "- Installed. You can shut down this session, and/or remove rs-centos8.rpm and $fname."
