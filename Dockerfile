FROM alpine:3.13

LABEL org.opencontainers.image.source="https://github.com/muratgozel/postgresql-pgbackrest"
LABEL org.opencontainers.image.title="PostgreSQL pgBackRest"
LABEL org.opencontainers.image.description="PostgreSQL server with pgBackRest backup/restore tool."

ENV PGVERSION=13.3
ENV PGPORT=5432
ENV PGUSER=postgres
ENV PGDATA=/usr/local/pgsql/data
ENV PG_BACKREST_VERSION=2.35
ENV PGUSER_UID=2001
ENV PGUSER_GID=2001
ENV LANG=en_US.utf8

COPY ./entrypoint.sh /entrypoint.sh

# install dependencies
RUN apk add --no-cache --virtual .build-deps gcc g++ make wget pkgconf dpkg-dev pcre-dev \
    openssl-dev zlib-dev icu-dev readline-dev libxslt-dev libxml2-dev \
    bzip2-dev zlib-dev libuuid linux-headers \
    tzdata yaml-dev util-linux-dev && \
    apk add --no-cache git bash python3 py3-pip icu libxml2 lz4-dev zstd-dev \
    postgresql-dev && \
    # configure dependencies
    ln -sf python3 /usr/bin/python && \
    mkdir -p /downloads && \
    addgroup --gid ${PGUSER_GID} $PGUSER && \
    adduser --disabled-password --uid ${PGUSER_UID} --ingroup $PGUSER --gecos "" -s /bin/bash $PGUSER && \
    # download pgbackrest
    cd /downloads && \
    wget https://github.com/pgbackrest/pgbackrest/archive/release/$PG_BACKREST_VERSION.tar.gz && \
    tar xf $PG_BACKREST_VERSION.tar.gz && \
    rm $PG_BACKREST_VERSION.tar.gz && \
    # install pgbackrest
    cd /downloads/pgbackrest-release-$PG_BACKREST_VERSION/src && \
    ./configure && make && cp pgbackrest /usr/bin/ && \
    rm -r /downloads/pgbackrest-release-$PG_BACKREST_VERSION && \
    # configure pgbackrest
    chmod 755 /usr/bin/pgbackrest && \
    mkdir -p -m 750 /var/log/pgbackrest && chown -R $PGUSER:$PGUSER /var/log/pgbackrest && \
    mkdir -p -m 750 /var/lib/pgbackrest && chown -R $PGUSER:$PGUSER /var/lib/pgbackrest && \
    mkdir -p -m 750 /var/spool/pgbackrest && chown -R $PGUSER:$PGUSER /var/spool/pgbackrest && \
    # download postgresql
    cd /downloads && \
    wget https://ftp.postgresql.org/pub/source/v$PGVERSION/postgresql-$PGVERSION.tar.gz && \
    gunzip postgresql-$PGVERSION.tar.gz && tar xf postgresql-$PGVERSION.tar && \
    rm postgresql-$PGVERSION.tar && \
    # install postgresql
    cd /downloads/postgresql-$PGVERSION && \
    ./configure --with-icu --with-openssl --with-libxml --with-libxslt --with-uuid=e2fs && \
    make world && make install-world && \
    rm -r /downloads/postgresql-$PGVERSION && \
    # configure postgresql
    cd / && \
    mkdir -p -m 775 /var/run/postgresql && chown $PGUSER:$PGUSER /var/run/postgresql && \
    mkdir -p -m 750 $PGDATA && chown $PGUSER:$PGUSER $PGDATA && \
    chmod +x /entrypoint.sh && \
    apk del --no-network .build-deps

USER $PGUSER

STOPSIGNAL SIGINT

# start database service
ENV PATH=/usr/local/pgsql/bin:$PATH
ENTRYPOINT ["/entrypoint.sh"]
CMD ["postgres"]
