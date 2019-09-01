FROM catatnight/postfix

ENV DEBIAN_FRONTEND noninteractive

# Workaround for [apt-get update very slow when ulimit -n is big](https://bugs.launchpad.net/ubuntu/+source/apt/+bug/1332440)
RUN ulimit -n 1024 && \
    apt-get update && \
    apt-get -y install --no-install-recommends \
        entr \
        heirloom-mailx \
        sharutils && \
    rm -rf /var/lib/apt/lists/*
# Workaround for [x509: certificate signed by unknown authority](https://github.com/abiosoft/caddy-docker/issues/173)
RUN ulimit -n 1024 && \
    apt-get update && \
    apt-get -y install --no-install-recommends \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# SSL ports for SMTP: 465, IMAP 993, POP3 995
EXPOSE \
    25/tcp \
    80/tcp \
    110/tcp \
    143/tcp \
    443/tcp \
    465/tcp \
    587/tcp \
    993/tcp \
    995/tcp \
    10025/tcp \
    10143/tcp

COPY \
    assets/caddy/caddy \
    assets/gpg/test.gpg \
    bootstrap.sh \
    mailsh.env \
    watch.sh \
    /opt/
COPY \
    assets/ssl/* \
    /etc/postfix/certs/

CMD /opt/bootstrap.sh

# Reference:
# https://github.com/Mailu/Mailu/blob/master/core/postfix/Dockerfile
HEALTHCHECK --start-period=350s CMD echo QUIT | \
    nc localhost 25 | \
    grep "220 .* ESMTP Postfix"
