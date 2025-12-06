# Multi-stage build for safer, reproducible, smaller image

###########################
# Stage 1 — Debian builder
###########################
FROM debian:stable-slim AS deb-builder

COPY build/fetch_binaries.sh /tmp/fetch_binaries.sh

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       curl wget ca-certificates \
    && chmod +x /tmp/fetch_binaries.sh \
    && /tmp/fetch_binaries.sh \
    && rm -rf /var/lib/apt/lists/*


###########################
# Stage 2 — Final Alpine image
###########################
FROM alpine:3.22.2

# Add only required edge repos (pin to specific versions if needed)
RUN set -ex \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk update

# Install tools — avoid apk upgrade, avoid enabling full edge
RUN apk add --no-cache \
    apache2-utils \
    bash \
    bind-tools \
    bird \
    bridge-utils \
    busybox-extras \
    conntrack-tools \
    curl \
    dhcping \
    drill \
    ethtool \
    file \
    fping \
    iftop \
    iperf \
    iperf3 \
    iproute2 \
    ipset \
    iptables \
    iptraf-ng \
    iputils \
    ipvsadm \
    httpie \
    jq \
    yq \
    libc6-compat \
    liboping \
    ltrace \
    mtr \
    net-snmp-tools \
    netcat-openbsd \
    nftables \
    ngrep \
    nmap \
    nmap-nping \
    nmap-scripts \
    openssl \
    py3-pip \
    py3-setuptools \
    scapy \
    socat \
    speedtest-cli \
    openssh \
    strace \
    tcpdump \
    tcptraceroute \
    trippy \
    tshark \
    util-linux \
    vim \
    git \
    zsh \
    websocat \
    swaks \
    perl-crypt-ssleay \
    perl-net-ssleay


###########################################
# Copy pre-fetched binaries from builder
###########################################
COPY --from=deb-builder /tmp/ctop /usr/local/bin/ctop
COPY --from=deb-builder /tmp/calicoctl /usr/local/bin/calicoctl
COPY --from=deb-builder /tmp/termshark /usr/local/bin/termshark
COPY --from=deb-builder /tmp/grpcurl /usr/local/bin/grpcurl
COPY --from=deb-builder /tmp/fortio /usr/local/bin/fortio

RUN chmod +x /usr/local/bin/*


###########################################
# ZSH setup (vendored instead of curl|sh)
###########################################
# Copy a vendored Oh My Zsh directory (recommended)
# If you want me to generate this vendored approach, ask!
# For now: safer installation
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

###########################################
# Permissions
###########################################
RUN chmod -R g=u /root \
    && chown root:root /usr/bin/dumpcap


###########################################
# Runtime settings
###########################################
USER root
WORKDIR /root
ENV HOSTNAME=netshoot

CMD ["zsh"]
