.POSIX:

SHELL := /bin/bash

include mailsh.env

container-hostname := $(MAILSH_DOMAIN)
container-name := mailsh
container-tag := mailsh/mailsh

caddy-obj := assets/caddy/caddy
$(caddy-obj):
	cd assets/caddy && \
		curl 'https://caddyserver.com/download/linux/amd64?license=personal&telemetry=off' -o caddy.tar.gz && \
		tar xzvf caddy.tar.gz

gpg-obj := assets/gpg/test.gpg
$(gpg-obj):
	./assets/gpg/generate-gpg-key.sh

ssl-generated-dir := dehydrated/certs/$(MAILSH_DOMAIN)
ssl-dir := $(shell readlink -f assets/ssl)
ssl-obj := \
	$(ssl-dir)/$(MAILSH_DOMAIN).key \
	$(ssl-dir)/$(MAILSH_DOMAIN).fullchain.crt
$(ssl-obj):
	rm -rf dehydrated
	git clone --depth=1 https://github.com/lukas2511/dehydrated
	echo "$(MAILSH_DOMAIN)" > assets/dehydrated/domains.txt
	cp assets/dehydrated/* dehydrated/
	# `|| true`: Ignoring unknown hook errors
	cd dehydrated && \
		chmod 755 hook.sh && \
		chmod +x dehydrated && \
		./dehydrated --register  --accept-terms && \
		./dehydrated -c || true
	mkdir -p $(ssl-dir)
	cp $(ssl-generated-dir)/privkey.pem $(ssl-dir)/$(MAILSH_DOMAIN).key
	cp $(ssl-generated-dir)/fullchain.pem $(ssl-dir)/$(MAILSH_DOMAIN).fullchain.crt

script-obj := $(shell find . -type f -iname '*.sh')
docker-obj := Dockerfile.timestamp
$(docker-obj): Dockerfile Makefile $(caddy-obj) $(gpg-obj) $(script-obj) $(ssl-obj)
	sudo docker build --tag $(container-tag) .
	sudo docker rm --force $(container-name) || true
	touch $@

# `--ulimit`: Workaround for `entr` out of memory on mmap() call
all: $(docker-obj)
	sudo docker run \
		-e maildomain=$(container-hostname) \
		-e smtp_user=test:test \
		--cap-add=NET_ADMIN \
		--detach \
		--hostname $(container-hostname) \
		--name $(container-name) \
		--ulimit nofile=8192:8192 \
		$(container-tag)

.DEFAULT_GOAL := all
.PHONY: all
