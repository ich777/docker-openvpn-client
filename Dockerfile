FROM ich777/debian-baseimage

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/ich777/docker-openvpn-client"

# Install openvpn
RUN apt-get update && \
    echo resolvconf resolvconf/linkify-resolvconf boolean false | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl openvpn tzdata iptables kmod iputils-ping resolvconf && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -s /bin/bash vpn

ADD /scripts/ /opt/scripts/
RUN chmod -R 770 /opt/scripts/

ENV IF=eth0
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV DATA_DIR=/vpn

HEALTHCHECK --interval=60s --timeout=15s --start-period=120s \
             CMD curl -LSs 'https://api.ipify.org'

VOLUME ["/vpn"]

ENTRYPOINT ["/opt/scripts/start.sh"]