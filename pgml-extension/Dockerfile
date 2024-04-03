FROM debian:bullseye-slim as builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    binutils \
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
    && rm -rf /var/lib/apt/lists/*

RUN wget -c https://ftp.gnu.org/gnu/glibc/glibc-2.35.tar.gz && \
    tar -zxvf glibc-2.35.tar.gz && cd glibc-2.35 && \
    mkdir glibc-build && cd glibc-build && \
    ../configure --prefix=/opt/glibc && \
    make && \
    make install

# Add the PostgreSQL APT repository
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/postgresql.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-server-dev-15 \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /postgresml

COPY . .

# RUN apt-get update -y && apt-get upgrade -y
# RUN apt-get install -y --no-install-recommends --no-install-suggests cmake build-essential git libclang-dev libpython3-dev libssl-dev libopenblas-dev pkg-config libicu-dev libreadline-dev zlib1g-dev flex bison libpq-dev

RUN cargo install --locked cargo-pgrx
RUN cargo pgrx init

RUN cargo pgrx package

# Extract the extension name from the manifest
RUN export EXTENSION_NAME=$(grep 'name =' Cargo.toml | head -n 1 | cut -d '"' -f 2)

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

CMD ["postgres", "-c", "shared_preload_libraries=age,pgml"]