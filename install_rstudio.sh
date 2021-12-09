#!/bin/bash

echo "+-----------------------+"
echo "| AE5 RStudio Installer |"
echo "+-----------------------+"

if [[ -z "$TOOL_PROJECT_URL" || -z "$TOOL_HOST" || -z "$TOOL_OWNER" ]]; then
    echo 'ERROR: this script must be run within an AE5 session.'
    exit -1
elif ! grep -q /tools/ /opt/continuum/scripts/start_user.sh; then
    echo 'ERROR: this version of the RStudio Installer requires AE5.5.1 or later.'
    exit -1
elif [ -z "$RSTUDIO_PREFIX" ]; then
    RSTUDIO_PREFIX=/tools/rstudio
elif [ $RSTUDIO_PREFIX = /tools/rstudio ]; then
    :
elif [ $RSTUDIO_PREFIX != /usr/lib/rstudio-server ]; then
    echo "ERROR: RStudio must be installed in one of the following directories:"
    echo "- /tools/rstudio"
    echo "- /usr/lib/rstudio-server"
    echo "The first is strongly preferred. Please refer to README.md for details."
    exit -1
fi

RSTUDIO_PARENT=$(dirname $RSTUDIO_PREFIX)
if [[ -d $RSTUDIO_PREFIX || $RSTUDIO_PREFIX != /tools/rstudio ]]; then
    if [ ! -d $RSTUDIO_PREFIX ]; then
        echo "The directory $RSTUDIO_PREFIX is missing. Please add this volume"
        echo "to your configuration, then stop and restart this session."
        exit -1
    elif [ ! -w $RSTUDIO_PREFIX ]; then
        echo "The directory $RSTUDIO_PREFIX is readonly. Please ensure that its"
        echo "volume is set to read-write, then stop and restart this session."
        exit -1
    elif [ ! -z "$(ls -A $RSTUDIO_PREFIX)" ]; then
        echo "The directory $RSTUDIO_PREFIX is not empty. To prevent overwriting an"
        echo "existing installation, the script expects this directory to be empty."
        echo "Please manually remove the contents before proceeding."
        ls -A $RSTUDIO_PREFIX
        exit -1
    fi
elif [ ! -d $RSTUDIO_PARENT ]; then
    echo "ERROR: The directory $RSTUDIO_PARENT is missing. Please follow the instructions"
    echo "in README.md to create this volume, and stop and restart this session."
    exit -1
elif [ ! -w $RSTUDIO_PARENT ]; then
    echo "ERROR: The directory $RSTUDIO_PARENT is readonly. Please follow the instructions"
    echo "in README.md to set it to read-write, and stop and restart this session."
    exit -1
fi

if [[ ! -f rs-centos8.rpm && ! -f data/rs-centos8.rpm || ! -f rs-centos7.rpm && ! -f data/rs-centos7.rpm ]]; then
    echo 'ERROR: the RStudio Server binaries are not present. Please follow the'
    echo 'directions in README.md to bring these binaries into the project.'
    exit -1
fi
missing=
for fname in Rprofile rsession.conf rsession.sh start_rstudio.sh default_env.py; do
    [ -f $fname ] || missing=$missing"$fname "
done
if [ ! -z "$missing" ]; then
    echo "One or more of the installer support files is missing:"
    echo "- $missing"
    echo "Please restore the full contents of the installer project."
    exit -1
fi

echo "- Install prefix: $RSTUDIO_PREFIX"

for os_ver in 8 7; do
    fname=rs-centos$os_ver.rpm
    [ -f $fname ] || fname=data/$fname
    echo "- Verifying $fname"
    if ! rpm2cpio $fname >/dev/null; then
        echo "- ERROR: $fname is not a valid RPM package. Please remove this file and re-download it."
        exit -1
    fi
done

if [ ! -d $RSTUDIO_PREFIX ]; then
    echo "- Creating directory $RSTUDIO_PREFIX"
    if ! mkdir -p $RSTUDIO_PREFIX; then
        echo "ERROR: The directory $RSTUDIO_PREFIX could not be created. Because the"
        echo "parent directory $RSTUDIO_PARENT is writable, this is unexpected. Please correct"
        echo "this issue before proceeding further."
        exit -1
    fi
fi

echo "- Staging full RHEL8/CentOS8 package"
mkdir -p $RSTUDIO_PREFIX/staging8/usr/lib/rstudio-server
fname=rs-centos8.rpm
[ -f $fname ] || fname=data/$fname
rpm2cpio $fname | (cd $RSTUDIO_PREFIX/staging8 && cpio -ic "./usr/lib/rstudio-server/*")

echo "- Staging RHEL7/CentOS7 rsession binary"
mkdir -p $RSTUDIO_PREFIX/staging7/usr/lib/rstudio-server/bin
fname=rs-centos7.rpm
[ -f $fname ] || fname=data/$fname
rpm2cpio $fname | (cd $RSTUDIO_PREFIX/staging7 && cpio -ic ./usr/lib/rstudio-server/bin/rsession)

echo "- Moving files into final position"
mv $RSTUDIO_PREFIX/staging8/usr/lib/rstudio-server/* $RSTUDIO_PREFIX
mv $RSTUDIO_PREFIX/staging7/usr/lib/rstudio-server/bin/rsession $RSTUDIO_PREFIX/bin/rsession10
rm -rf $RSTUDIO_PREFIX/{staging7,staging8}

echo "- Installing support files"
cp Rprofile rsession.conf rsession.sh start_rstudio.sh default_env.py $RSTUDIO_PREFIX/
chmod +x $RSTUDIO_PREFIX/{start_rstudio.sh,rsession.sh}

echo "+-----------------------+"
echo "RStudio installation is complete."
echo "Once you have verified the installation, feel free to"
echo "shut down this session and delete the project."
echo "+-----------------------+"
