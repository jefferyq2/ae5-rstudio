FROM leader.telekube.local:5000/ae-editor:5.3.1-22.g6cafcc9c5
COPY . /aesrc/rstudio/
RUN set -ex \
    && cd /aesrc/rstudio \
    && if [ ! -f rstudio-server-rhel-1.2.1335-x86_64.rpm ]; then \
          curl -O https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-1.2.1335-x86_64.rpm; \
       fi \
    && yum install -y rstudio-server-rhel-1.2.1335-x86_64.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum/* rstudio-server-rhel-1.2.1335-x86_64.rpm \
    && cp Rprofile /opt/continuum/.Rprofile \
    && if [ ! -f /opt/continuum/scripts/start_user.sh ]; then \
           cp startup-5.3.1.sh /opt/continuum/scripts/startup.sh; \
           chmod +x /opt/continuum/scripts/startup.sh; \
       fi \
    && cp rsession.sh start_rstudio.sh /opt/continuum/scripts/ \
    && chmod +x /opt/continuum/scripts/{rsession.sh,start_rstudio.sh} \
    && chown anaconda:anaconda /opt/continuum/scripts/{rsession.sh,start_rstudio.sh}
