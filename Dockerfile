FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    iputils-ping \
    iptables \
    net-tools \
    iproute2 \
    vim \
    less \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

CMD [ "bash" ]
