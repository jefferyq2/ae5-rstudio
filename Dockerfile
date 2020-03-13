FROM leader.telekube.local:5000/ae-editor:5.3.1-22.g6cafcc9c5
COPY . /aesrc/rstudio/
RUN set -ex \
    && cd /aesrc/rstudio \
    && if [ ! $(rpm -qa psmisc) ]; then \
          if [ ! -f psmisc-22.20-16.el7.x86_64.rpm ]; then \
             curl -O https://rpmfind.net/linux/centos/7.7.1908/os/x86_64/Packages/psmisc-22.20-16.el7.x86_64.rpm; \
          fi \
          rpm -i psmisc-22.20-16.el7.x86_64.rpm; \
       fi \
    && if [ ! -f rstudio-server-rhel-1.2.1335-x86_64.rpm ]; then \
          curl -O https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-1.2.1335-x86_64.rpm; \
       fi \
    && rpm -i rstudio-server-rhel-1.2.1335-x86_64.rpm \
    && rm *.rpm \
    && for envtxt in *.txt; do \
            envname=${envtxt%.txt}; \
            CONDARC=./condarc conda create -n $envname --file $envtxt; \
            [ -d anaconda/envs/$envname/conda-meta ] || exit -1; \
       done \
    && if [ $envname ]; then \
           sed -i "s@anaconda50_r@$envname@" rsession.sh start_rstudio.sh; \
       fi \
    && cp Rprofile /opt/continuum/.Rprofile \
    && if [ ! -f /opt/continuum/scripts/start_user.sh ]; then \
           cp startup.sh build_condarc.py run_tool.py /opt/continuum/scripts/; \
       fi \
    && cp rsession.sh start_rstudio.sh /opt/continuum/scripts/ \
    && chmod +x /opt/continuum/scripts/*.sh \
    && chown anaconda:anaconda /opt/continuum/.Rprofile /opt/continuum/scripts/*.sh
