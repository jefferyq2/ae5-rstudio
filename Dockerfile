ARG WORKSPACE
FROM ${WORKSPACE}
COPY --chown anaconda:anaconda . /aesrc/rstudio/
RUN set -ex \
    && cd /aesrc/rstudio \
    && [ -f rstudio-server-rhel-1.2.1335-x86_64.rpm ] || \
       curl -O https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-1.2.1335-x86_64.rpm \
    && yum install -y rstudio-server-rhel-1.2.1335-x86_64.rpm \
    && yum clean all \
    && rm -rf /var/cache/yum/* rstudio-server-rhel-1.2.1335-x86_64.rpm \
    && cp Rprofile /opt/continuum/.Rprofile \
    && cp rsession.sh start_rstudio.sh /opt/continuum/scripts \
    && chmod +x /opt/continuum/scripts/{rsession,start_rstudio}
