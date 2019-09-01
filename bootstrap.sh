#!/bin/sh

set -eu

. /opt/mailsh.env

# Instead of passing a DKIM private key,
# generate it in the container and copy it
# to the target directory checked by 
# `install.sh` from `catatnight/postfix`
opendkim-genkey -s mail -d "$MAILSH_DOMAIN"
mkdir -p /etc/opendkim/domainkeys
mv mail.private /etc/opendkim/domainkeys
mv mail.txt /opt/

# Using `CMD` from `catatnight/postfix`
/opt/install.sh

gpg --import '/opt/test.gpg'

# `entr` exits if file doesn't exist
touch /var/mail/root

supervisor_program=watch
cat > "/etc/supervisor/conf.d/$supervisor_program.conf" <<EOF
[program:$supervisor_program]
command=/bin/bash -c 'echo /var/mail/root | entr /opt/watch.sh'
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

cat > "/opt/Caddyfile" <<EOF
$MAILSH_DOMAIN {
    tls /etc/postfix/certs/$MAILSH_DOMAIN.fullchain.crt /etc/postfix/certs/$MAILSH_DOMAIN.key
}
EOF
supervisor_program=caddy
cat > "/etc/supervisor/conf.d/$supervisor_program.conf" <<EOF
[program:$supervisor_program]
command=/opt/caddy -agree=true -conf /opt/Caddyfile -log stdout -port 443
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
