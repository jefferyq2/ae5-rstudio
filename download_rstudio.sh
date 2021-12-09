#!/bin/bash

echo "+------------------------+"
echo "| AE5 RStudio Downloader |"
echo "+------------------------+"

[ $RSTUDIO_VERSION ] || RSTUDIO_VERSION=2021.09.1-372
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
    osdir=centos${os_ver}
    fname=${fdir}rs-$osdir.rpm
    echo "- Downloading $what_os RPM file to $fname"
    url=https://download2.rstudio.org/server/$osdir/x86_64/rstudio-server-rhel-${RSTUDIO_VERSION}-x86_64.rpm
    echo "- URL: $url"
    if ! curl -o $fname -L $url; then
       echo "- ERROR: unexpected error downloading this package. Please resolve the error and try again."
       exit -1
    elif grep -q NoSuchKey $fname; then
       echo "- ERROR: package not found as expected. Please verify the URL and try again."
       rm -f $fname
       exit -1basin 
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
