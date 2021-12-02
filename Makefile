SHELL := /bin/bash -euxo pipefail

build:
	docker build -t fuhrysteve/pg-repack-shell:latest .

build-no-cache:
	docker build --no-cache -t fuhrysteve/pg-repack-shell:latest .

push:
	docker push fuhrysteve/pg-repack-shell:latest
