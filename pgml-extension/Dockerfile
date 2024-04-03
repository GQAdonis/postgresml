FROM ubuntu:22.04 as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    binutils \
    gcc \
    gawk \
    bison \
    flex \
    wget \
    tar \
    ca-certificates \
    cmake \
    curl \
    git \
    gnupg \
    libclang-dev \
    libicu-dev \
    libopenblas-dev \
    libpq-dev \
    libpython3-dev \
    libreadline-dev \
    libssl-dev \
    pkg-config \
    python3 \
    python3-pip \
    zlib1g-dev \
    lld \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y gnupg2 && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" postgresql-server-dev-15 postgresql-15

ENV PATH="/usr/lib/postgresql/15/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

ENV PATH="/usr/bin:${PATH}"

WORKDIR /postgresml

COPY . .

RUN cargo install --locked cargo-pgrx
RUN cargo pgrx init

RUN cargo pgrx package

# Extract the extension name from the manifest
ENV EXTENSION_NAME=pgml

# Save the extension files for the next stage
RUN mkdir -p /build && cp target/release/${EXTENSION_NAME}.so /build/ && cp target/release/${EXTENSION_NAME}.control /build/


FROM supabase/postgres:15.1.1.36

# Copy the extension files from the builder stage
COPY --from=builder /build/ /usr/local/lib/postgresql/

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository 'deb http://apache.jfrog.io/artifactory/db-age/ age main' && \
    apt-get update && apt-get install -y age

# Install the extension in the Postgres image
RUN mkdir -p /docker-entrypoint-initdb.d
RUN echo "CREATE EXTENSION ${EXTENSION_NAME};" > /docker-entrypoint-initdb.d/init-pgml.sql
RUN echo "CREATE EXTENSION age;" > /docker-entrypoint-initdb.d/init-age.sql

# Set the necessary permissions for the extension
RUN chown -R postgres:postgres /usr/local/lib/postgresql/

CMD ["postgres", "-c", "shared_preload_libraries=age,${EXTENSION_NAME}"]