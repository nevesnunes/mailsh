#!/bin/sh

set -eux

. ./mailsh.env
. ./request.env

sender_address=$REQUEST_MAIL
request_command_file=$1
[ -f "$request_command_file" ]
request_name=$(basename "$request_command_file")
request_attachment_name="$request_name.asc"

rm -f "$request_attachment_name"
gpg \
  --output "$request_attachment_name" \
  --local-user "$REQUEST_USER" \
  --armor \
  --sign "$request_name"

(
echo 'To: root <root@localhost>
From: test <'"$sender_address"'>
Subject: Test '"$(date +%s)"'

Please run me :)'

uuencode "$request_attachment_name" "$request_attachment_name"
) | \
  mailx \
    -S smtp-use-starttls \
    -S smtp=smtp://"$MAILSH_DOMAIN":587 \
    -S smtp-auth-user=test \
    -S smtp-auth-password=test \
    -S from="$sender_address" \
    -t \
    -v
