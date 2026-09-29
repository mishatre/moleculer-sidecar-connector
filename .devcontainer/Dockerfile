FROM local/vrunner:8.3.24.1667 
# local/onescript-dev-base:2.1.0

USER root

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bash \
        ca-certificates \
        curl \
        git \
        openssh-client \
        procps \
    && rm -rf /var/lib/apt/lists/*

# The 1C client binaries link against WebKitGTK 4.0, libsoup 2.4 and
# javascriptcoregtk 4.0, which Ubuntu 24.04 no longer ships. The script installs
# them from Ubuntu 22.04 and points the platform's bundled libstdc++ at the system
# one, so `1cv8`/`1cv8c` at least load. A 1C licence is still required to run them.
COPY tools/1c-platform/install-client-runtime.sh /usr/local/bin/install-1c-client-runtime
RUN chmod +x /usr/local/bin/install-1c-client-runtime \
    && /usr/local/bin/install-1c-client-runtime

WORKDIR /workspace

ENTRYPOINT []
CMD ["sleep", "infinity"]