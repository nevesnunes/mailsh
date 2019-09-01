#!/bin/sh

set -eux

tmp_mail_dir=$(mktemp -d)
tmp_mail_name=$(mktemp --tmpdir="$tmp_mail_dir")
cleanup() {
  err=$?
  sudo rm -rf "$tmp_mail_dir"
  trap '' EXIT
  exit $err
}
trap cleanup EXIT INT QUIT TERM

(
  cd "$tmp_mail_dir"

  # Retrieve request (i.e. most recent mail)
  echo "w $ $tmp_mail_name" | mailx
  uudecode "$tmp_mail_name"

  # Validate and evaluate request
  if gpg --output script.sh --decrypt request.txt.asc; then
    bash script.sh > response-stdout.txt
  else
    echo "[ERROR] Invalid signature in request." > response-stdout.txt
  fi

  # Send response
  printf '%s\n' \
    'replysender $' \
    "$(cat response-stdout.txt)" | mailx -S smtp-use-starttls
)
