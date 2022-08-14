FROM alpine:latest

COPY postgresql /usr/src/postgresql

RUN set -eux; apk add gcc coreutils libc-dev libxml2 libxml2-dev perl bison flex make linux-headers cmake

RUN set -eux; cd /usr/src/postgresql && \
    ./configure --without-readline --without-zlib --with-blocksize=4 && \
    make world-bin -j

RUN cd /usr/src/postgresql && make install

ENV PATH=/usr/local/pgsql/bin:$PATH

RUN set -eux; apk add bash

COPY SSB-sqlite/ssb-dbgen /usr/src/ssb-dbgen

RUN addgroup pggroup && adduser -DH -G pggroup pguser
RUN cd /usr/src/ssb-dbgen/ && \
    cmake . && cmake --build . && \
    ./dbgen -f -s 1 && \
    mkdir -p tables && mv *.tbl tables/

RUN mkdir -p /opt/ssb-db && \
    chown pguser:pggroup /opt/ssb-db

USER pguser

COPY schema.sql /opt/ssb-schema.sql
COPY load-tables.sh /opt/load-tables.sh

ENV PGDATA=/opt/ssb-db/
ENV PATH=/usr/local/pgsql/bin:$PATH
RUN initdb -A trust && pg_ctl -D /opt/ssb-db/ -l /opt/ssb-db/logfile start \
    && createdb ssb \
    && psql -d ssb < /opt/ssb-schema.sql \
    && bash -ex /opt/load-tables.sh

CMD pg_ctl -D /opt/ssb-db/ -l /opt/ssb-db/logfile start; psql -d ssb
