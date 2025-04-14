SHELL := /bin/bash -euxo pipefail

REPACK_MIN := 1.5.0
PG_MIN_MAJOR := 15

PGXN_REPACK_JSON := https://api.pgxn.org/dist/pg_repack.json
PG_SUPPORTED := $(shell curl -s 'https://registry.hub.docker.com/v2/repositories/library/postgres/tags?page_size=100' \
  | jq -r '.results[].name' \
  | grep -E '^[0-9]+-bullseye$$' \
  | cut -d '-' -f1 \
  | sort -n \
  | awk -v min=$(PG_MIN_MAJOR) '$$1 >= min' \
  | uniq \
  | xargs)


-include repack_versions.mk

.PHONY: all
all: install check-tools fetch-versions build-all push-latest

.PHONY: install
install:
	sudo apt-get update
	sudo apt-get install -y jq yq

.PHONY: check-tools
check-tools:
	command -v jq >/dev/null || (echo "Install jq first (or run 'make install')" && exit 1)
	command -v yq >/dev/null || (echo "Install yq first (or run 'make install')" && exit 1)

.PHONY: fetch-versions
fetch-versions:
	curl -s $(PGXN_REPACK_JSON) \
	| jq -r '.releases.stable[].version' \
	| sort -V \
	| awk -v min="$(REPACK_MIN)" 'BEGIN { print "REPACK_VERSIONS :=" } { if ($$0 >= min) print "REPACK_VERSIONS += " $$0 }' \
	> repack_versions.mk
	@echo "====== Generated repack_versions.mk ======"
	@cat repack_versions.mk

.PHONY: build-all
build-all:
	@for pg in $(PG_SUPPORTED); do \
	  for repack in $(REPACK_VERSIONS); do \
	    echo "Building for Postgres $$pg and pg_repack $$repack..."; \
	    cp Dockerfile.template Dockerfile; \
	    docker build --build-arg PG_MAJOR=$$pg --build-arg REPACK_VERSION=$$repack \
	      -t fuhrysteve/pg-repack-shell:pg$$pg-$$repack .; \
	    rm Dockerfile; \
	  done; \
	done


.PHONY: build-missing
build-missing:
	@for pg in $(PG_SUPPORTED); do \
	  for repack in $(REPACK_VERSIONS); do \
	    tag="pg$$pg-$$repack"; \
	    echo "🔍 Checking tag $$tag..."; \
	    exists=$$(curl -s -o /dev/null -w "%{http_code}" https://hub.docker.com/v2/repositories/fuhrysteve/pg-repack-shell/tags/$$tag); \
	    if [ "$$exists" = "200" ]; then \
	      echo "✅ Image exists: $$tag"; \
	    else \
	      echo "🚧 Building image for: $$tag"; \
	      cp Dockerfile.template Dockerfile; \
	      docker build --build-arg PG_MAJOR=$$pg --build-arg REPACK_VERSION=$$repack \
	        -t fuhrysteve/pg-repack-shell:$$tag .; \
	      rm Dockerfile; \
	    fi; \
	  done; \
	done


.PHONY: push-all
push-all:
	@for pg in $(PG_SUPPORTED); do \
	  for repack in $(REPACK_VERSIONS); do \
	    docker push fuhrysteve/pg-repack-shell:pg$$pg-$$repack; \
	  done; \
	done

.PHONY: push-latest
push-latest:
	@if [ -z "$(REPACK_VERSIONS)" ]; then \
	  echo "❌ No REPACK_VERSIONS found. Did fetch-versions fail?"; \
	  exit 1; \
	fi; \
	latest_pg=$$(echo $(PG_SUPPORTED) | tr ' ' '\n' | sort -nr | head -n1); \
	latest_repack=$$(echo $(REPACK_VERSIONS) | tr ' ' '\n' | sort -V | tail -n1); \
	echo "✅ Tagging pg$$latest_pg-$$latest_repack as latest..."; \
	docker tag fuhrysteve/pg-repack-shell:pg$$latest_pg-$$latest_repack fuhrysteve/pg-repack-shell:latest; \
	docker push fuhrysteve/pg-repack-shell:latest

