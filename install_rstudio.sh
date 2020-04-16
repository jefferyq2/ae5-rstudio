#!/bin/bash
set -ex

# Install psmisc for 5.4.x
if [ ! $(rpm -qa psmisc) ]; then
   if [ ! -f psmisc-22.20-16.el7.x86_64.rpm ]; then
      curl -O https://rpmfind.net/linux/centos/7.7.1908/os/x86_64/Packages/psmisc-22.20-16.el7.x86_64.rpm
   fi
   rpm -i psmisc-22.20-16.el7.x86_64.rpm
fi

# Install RStudio server
if [ ! -f rstudio-server-rhel-1.2.5033-x86_64.rpm ]; then
   curl -O https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-1.2.5033-x86_64.rpm
fi
rpm -i rstudio-server-rhel-1.2.5033-x86_64.rpm
rm *.rpm


# 5.3.x back compatibility fixes
if [ ! -f /opt/continuum/scripts/start_user.sh ]; then
    cp startup.sh build_condarc.py run_tool.py /opt/continuum/scripts/
fi

# Rstudio scripts
cp Rprofile /opt/continuum/.Rprofile
cp rsession.sh start_rstudio.sh /opt/continuum/scripts/

# Fix ownership and permissions
chmod +x /opt/continuum/scripts/*.sh
chown anaconda:anaconda /opt/continuum/.Rprofile /opt/continuum/scripts/*.sh

# for some reason on AE541 ae-editor, conda is not in path and build fail - using full path... 
conda=conda
[[ command -v $conda ]] || conda='/opt/continuum/anaconda/condabin/conda'
[[ -f $conda ]] || exit 1

# Create the custom environments
envs=$(ls *.txt 2>/dev/null)
for envtxt in $envs; do
    envname=${envtxt%.txt}
    CONDARC=./condarc conda create -n $envname --file $envtxt
    [ -d /opt/continuum/anaconda/envs/$envname/conda-meta ] || exit -1
    chown -fR anaconda:anaconda /opt/continuum/anaconda/envs/$envname
    chmod -fR g+rwX /opt/continuum/anaconda/envs/$envname
    find /opt/continuum/anaconda/envs/$envname -type d -exec chmod g+s {} \;
done
if [ $envname ]; then
    sed -i "s@anaconda50_r@$envname@" rsession.sh start_rstudio.sh
    rm -rf /opt/continuum/anaconda/pkgs/*
    conda clean --all
fi

