FROM scratch

ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"

ARG BUILD_DATE
ARG ALPINE_ARCHITECTURE
ARG ALPINE_RELEASE
ARG ALPINE_VERSION
ARG ALPINE_VERSION_DATE

ADD Alpine/Cache/alpine-v$ALPINE_VERSION/$ALPINE_ARCHITECTURE/alpine-minirootfs-$ALPINE_VERSION-$ALPINE_ARCHITECTURE.tar.gz /

RUN apk --no-cache add cmake make musl-dev gcc gettext-dev libintl

WORKDIR /tmp

ADD Alpine/Docker/musl-locales/ /tmp

RUN mkdir build && \
    cd build && \ 
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_POLICY_DEFAULT_CMP0175=OLD && \
    make && \
    make install && \
    locale -a

FROM scratch

ARG BUILD_DATE
ARG ALPINE_ARCHITECTURE
ARG ALPINE_RELEASE
ARG ALPINE_VERSION
ARG ALPINE_VERSION_DATE

# set our environment variable
ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"

LABEL \
    maintainer="Mauro Cardillo <mauro.cardillo@gmail.com>" \
    architecture="$ALPINE_ARCHITECTURE" \
    alpine-version="$ALPINE_VERSION" \
    build="$BUILD_DATE" \
    org.opencontainers.image.title="alpine" \
    org.opencontainers.image.description="Alpine Linux Docker Image with Multilanguage e Timezone support" \
    org.opencontainers.image.authors="Mauro Cardillo <mauro.cardillo@gmail.com>" \
    org.opencontainers.image.vendor="Mauro Cardillo" \
    org.opencontainers.image.version="v$ALPINE_VERSION" \
    org.opencontainers.image.url="https://hub.docker.com/r/maurosoft1973/alpine/" \
    org.opencontainers.image.source="https://gitlab.com/maurosoft1973-docker/alpine" \
    org.opencontainers.image.created=$BUILD_DATE

ADD Alpine/Cache/alpine-v$ALPINE_VERSION/$ALPINE_ARCHITECTURE/alpine-minirootfs-$ALPINE_VERSION-$ALPINE_ARCHITECTURE.tar.gz /

ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"

RUN apk --no-cache add libintl tzdata bash

COPY --from=0 /etc/profile.d/00locale.sh /etc/profile.d/00locale.sh

COPY --from=0 /usr/bin/locale /usr/bin/locale

COPY --from=0 /usr/share/locale/* /usr/share/locale/

COPY --from=0 /usr/share/i18n/locales/musl/* /usr/share/i18n/locales/musl/

COPY Alpine/Docker/scripts /scripts/

RUN chmod -R 755 /scripts

ENTRYPOINT ["/scripts/run-alpine.sh"]
