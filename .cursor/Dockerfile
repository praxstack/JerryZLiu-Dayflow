FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Swift 6.3 Ubuntu 24.04 runtime packages from https://swift.org/install/linux/tarball/
# plus ca-certificates/curl (image bootstrap), sqlite3/libsqlite3-dev (dayflow-cli),
# and build-essential (C compiler for SwiftPM native targets).
# ubuntu:24.04 already has an `ubuntu` user — do not useradd it or the image build fails.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      build-essential \
      binutils \
      gnupg2 \
      unzip \
      zip \
      pkg-config \
      libc6-dev \
      libcurl4-openssl-dev \
      libedit2 \
      libgcc-13-dev \
      libncurses-dev \
      libpython3-dev \
      libsqlite3-0 \
      libsqlite3-dev \
      libstdc++-13-dev \
      libxml2-dev \
      libz3-dev \
      zlib1g-dev \
      sqlite3 \
      python3 \
      tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV SWIFTLY_HOME_DIR=/opt/swiftly
ENV SWIFTLY_BIN_DIR=/opt/swiftly/bin
ENV SWIFTLY_TOOLCHAINS_DIR=/opt/swiftly/toolchains
ENV PATH="/usr/local/bin:/opt/swiftly/bin:${PATH}"

RUN curl -fsSL https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz \
      | tar xz -C /tmp \
    && /tmp/swiftly init --no-modify-profile --skip-install --assume-yes \
    && /opt/swiftly/bin/swiftly install --use 6.3.3 \
    && ln -sf /opt/swiftly/toolchains/6.3.3/usr/bin/swift /usr/local/bin/swift \
    && ln -sf /opt/swiftly/toolchains/6.3.3/usr/bin/swiftc /usr/local/bin/swiftc \
    && ln -sf /opt/swiftly/bin/swiftly /usr/local/bin/swiftly \
    && rm -rf /tmp/swiftly /tmp/.swift-version /.swift-version

USER ubuntu
