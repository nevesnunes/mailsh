#!/bin/sh

set -eux

. ../../request.env

tmp_parameters_file=$(mktemp)
cleanup() {
  err=$?
  sudo rm -f "$tmp_parameters_file"
  trap '' EXIT
  exit $err
}
trap cleanup EXIT INT QUIT TERM

cat >"$tmp_parameters_file" <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: ELG-E
Subkey-Length: 4096
Name-Real: $REQUEST_USER
Name-Comment: Test
Name-Email: $REQUEST_MAIL
Expire-Date: 0
Passphrase: test
EOF

gpg --batch --yes --gen-key "$tmp_parameters_file"
gpg --output test.gpg --armor --export "$REQUEST_MAIL"
