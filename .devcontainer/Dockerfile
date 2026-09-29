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

WORKDIR /workspace

ENTRYPOINT []
CMD ["sleep", "infinity"]