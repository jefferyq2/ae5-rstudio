#!/bin/bash
set -ex

# Add anaconda-project to PATH if not present
source /opt/continuum/anaconda/bin/activate root
if ! which anaconda-project; then
  ln -s /opt/continuum/anaconda/envs/lab_launch/bin/anaconda-project /usr/local/bin/
fi

# Install psmisc for 5.4.x
if [ ! $(rpm -qa psmisc) ]; then
   if [ ! -f psmisc-22.20-16.el7.x86_64.rpm ]; then
      curl -O http://mirror.centos.org/centos/7/os/x86_64/Packages/psmisc-22.20-16.el7.x86_64.rpm
   fi
   rpm -i psmisc-22.20-16.el7.x86_64.rpm
fi

# Install RStudio server
if [ ! -f rstudio-server-rhel-1.2.5042-x86_64.rpm ]; then
   curl -O https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-1.2.5042-x86_64.rpm
fi
rpm -i rstudio-server-rhel-1.2.5042-x86_64.rpm
rm *.rpm

# Create the custom environments
for envtxt in *.txt; do
    # if there are no text files, envtxt will actually be *.txt
    [ -e "$envtxt" ] || continue
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

# 5.3.x back compatibility fixes
if [ ! -f /opt/continuum/scripts/start_user.sh ]; then
    cp startup.sh build_condarc.py run_tool.py /opt/continuum/scripts/
fi

# Rstudio scripts
if [ ! -f /opt/continuum/.Rprofile ]; then
    cp Rprofile /opt/continuum/.Rprofile
    cp rsession.sh start_rstudio.sh /opt/continuum/scripts/
    chmod +x /opt/continuum/scripts/*.sh
    chown anaconda:anaconda /opt/continuum/.Rprofile /opt/continuum/scripts/*.sh
fi
