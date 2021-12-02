FROM postgres:13

RUN apt-get update --fix-missing && apt-get install -y \
        gcc \
        libreadline-dev \
        libssl-dev \
        make \
        postgresql-common \
        postgresql-server-dev-$PG_MAJOR \
        unzip \
        wget \
        zlib1g-dev \
    && wget -q -O pg_repack.zip "https://api.pgxn.org/dist/pg_repack/1.4.7/pg_repack-1.4.7.zip" \
    && unzip pg_repack.zip && rm pg_repack.zip \
    && cd pg_repack-* \
    && make \
    && make install \
    && cd .. \
    && rm -rf pg_repack-* \
    && apt-get remove --auto-remove -y \
        gcc \
        libreadline-dev \
        libssl-dev \
        make \
        unzip \
        wget \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
