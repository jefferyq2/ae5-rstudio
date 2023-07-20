#!/bin/bash

echo "+------------------------+"
echo "| AE5 RStudio Downloader |"
echo "+------------------------+"

[ $RSTUDIO_VERSION ] || RSTUDIO_VERSION=2023.06.1-524
echo "- Target version: ${RSTUDIO_VERSION}"

if [[ ! -z "$TOOL_PROJECT_URL" && -d data ]]; then
   echo "- Downloading into the data directory"
   fdir=data/
fi

# We actually need two RPM packages: the CentOS 8 version is the version we
# use in full, but we need to extract a single binary (rsession) from the
# CentOS 7 version to offer compatibility with older versions of R.
for os_ver in 8 7; do
    what_os="RHEL${os_ver}/CentOS${os_ver}"
    fname=${fdir}rs-centos${os_ver}.rpm
    echo "- Downloading $what_os RPM file to $fname"
    for os_base in rhel centos; do
        url=https://download2.rstudio.org/server/${os_base}${os_ver}/x86_64/rstudio-server-rhel-${RSTUDIO_VERSION}-x86_64.rpm
        echo "- URL: $url"
        if ! curl -o $fname -L $url; then
           echo "- unexpected error with curl"
           continue
        elif grep -q NoSuchKey $fname; then
           echo "- bucket error downoading package"
           rm -f $fname
           continue
        fi
        break
    done
    if [ ! -f $fname ]; then
        echo "- ERROR: could not find package as expected. Please check URLs."
        exit -1
    fi
    if which rpm2cpio &>/dev/null; then
        echo "- Verifying $fname"
        if ! rpm2cpio $fname >/dev/null; then
            echo "- ERROR: $fname is not a valid RPM package. Please remove this file and re-download it."
            exit -1
        fi
    fi
done

echo "+------------------------+"
echo "The RStudio binaries have been downloaded."
if [ -z "$TOOL_PROJECT_URL" ]; then
    echo "Upload these files to your installer session to proceed."
else
    echo "You may now proceed with the installation step."
fi
echo "See the README.md file for more details."
echo "+------------------------+"
