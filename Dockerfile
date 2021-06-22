ARG IMAGENAME
FROM ${IMAGENAME} as build

USER root
COPY r8.rpm .
COPY r6.rpm .
RUN set -ex \
    && rpm -i --nodeps r8.rpm \
    && mkdir -p usr/lib/rstudio-server/bin \
    && rpm2cpio r6.rpm | cpio -icv ./usr/lib/rstudio-server/bin/rsession \
    && mv ./usr/lib/rstudio-server/bin/rsession /usr/lib/rstudio-server/bin/rsession10

FROM ${IMAGENAME}
COPY --from=build /usr/lib/rstudio-server/ /usr/lib/rstudio-server/
