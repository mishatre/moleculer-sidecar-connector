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
        inetutils-tools \
        iproute2 \
        net-tools \
        dmidecode \
        gh \
        x11-utils \
    && rm -rf /var/lib/apt/lists/*

# `gh` is how tasks, issues and pull requests are read and written from inside
# the container; it authenticates from GH_TOKEN, which docker-compose.yml passes
# through from the host (Ubuntu 24.04 carries 2.45).
# `x11-utils` carries `xdpyinfo`, the probe `tools/1c-platform/open-infobase.sh` uses
# to tell "the client cannot draw" from "the licence is missing". The base image
# already has Xvfb, dbus-x11 and the X11/WebKit libraries the client links against.

# The 1C licence check shells out to `hostname` and `ip` to collect system
# information. When they are missing, the platform cannot build that report and
# rejects the developer licence with "Использование лицензии для разработчиков
# запрещено", while the launcher logs "/bin/sh: 1: /sbin/ip: not found".
# inetutils-tools guarantees `hostname`; iproute2 and net-tools provide `ip` and
# `ifconfig`; dmidecode answers the hardware queries.

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