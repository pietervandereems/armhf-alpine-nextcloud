FROM hypriot/rpi-alpine-scratch
MAINTAINER Pieter van der Eems <docker@eemco.nl>

ARG NEXTCLOUD_VERSION=10.0.0
ARG GPG_nextcloud="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"
ARG S6_OVERLAY_VERSION=v1.18.1.5
ARG NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"
ARG BUILD_DEPS="gnupg tar"

ENV UID=991 GID=991

RUN apk update
RUN apk add bind-tools curl && \
    curl -sSL https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-armhf.tar.gz \
    | tar xfz - -C /

#RUN echo " https://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
# && echo "@testing https://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
#RUN BUILD_DEPS="gnupg tar" \
RUN apk -U add \
    ${BUILD_DEPS} \
    nginx \
    openssl \
    ca-certificates \
    libsmbclient \
    samba-client \
    su-exec \
    php \
    php-fpm \
    php-intl \
    php-curl \
    php-gd \
    php-mcrypt \
    php-opcache \
    php-json \
#    php-session \
    php-pdo \
    php-dom \
    php-ctype \
    php-iconv \
    php-pdo_mysql \
    php-pdo_pgsql \
    php-pgsql \
    php-pdo_sqlite \
    php-sqlite3 \
    php-zlib \
    php-zip \
    php-xmlreader \
    php-posix \
    php-openssl \
    php-ldap \
    php-ftp \
    php-apcu 
 RUN mkdir /nextcloud && cd /tmp \
 && NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
 && echo "Getting Nextcloud ${NEXTCLOUD_TARBALL}" \
 && curl -O https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL} \
 && curl -O https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha256 \
 && curl -O https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc \
 && curl -O https://nextcloud.com/nextcloud.asc \
 && echo "Verifying both integrity and authenticity of ${NEXTCLOUD_TARBALL}..." \
 && CHECKSUM_STATE=$(echo -n $(sha256sum -c ${NEXTCLOUD_TARBALL}.sha256) | tail -c 2) \
 && if [ "${CHECKSUM_STATE}" != "OK" ]; then echo "Warning! Checksum does not match!" && exit 1; fi \
 && gpg --import nextcloud.asc \
 && FINGERPRINT="$(LANG=C gpg --verify ${NEXTCLOUD_TARBALL}.asc ${NEXTCLOUD_TARBALL} 2>&1 \
  | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
 && if [ -z "${FINGERPRINT}" ]; then echo "Warning! Invalid GPG signature!" && exit 1; fi \
 && if [ "${FINGERPRINT}" != "${GPG_nextcloud}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi \
 && echo "All seems good, now unpacking ${NEXTCLOUD_TARBALL}..." \
 && tar xjf ${NEXTCLOUD_TARBALL} --strip 1 -C /nextcloud \
 && apk del ${BUILD_DEPS} \
 && rm -rf /var/cache/apk/* /tmp/* /root/.gnupg

COPY nginx.conf /etc/nginx/nginx.conf
COPY php-fpm.conf /etc/php7/php-fpm.conf
#COPY opcache.ini /etc/php7/conf.d/00_opcache.ini
#COPY apcu.ini /etc/php7/conf.d/apcu.ini
COPY run.sh /usr/local/bin/run.sh
COPY occ /usr/local/bin/occ
COPY cron /etc/periodic/15min/nextcloud
COPY s6.d /etc/s6.d

RUN chmod +x /usr/local/bin/* /etc/periodic/15min/nextcloud /etc/s6.d/*/*

VOLUME /data /config /apps2

EXPOSE 8888

LABEL description="A server software for creating file hosting services" \
      nextcloud="Nextcloud v${NEXTCLOUD_VERSION}"

CMD ["run.sh"]
