include .makerc

.PHONY: help all generate-bundle-file generate-credentials show-credentials build install upgrade uninstall publish docker-login docker-logout
.DEFAULT_GOAL := help

#COLORING
RED:=\e[31m
NC:=\e[0m

#Make sure registry credentials are set
ifndef DOCKER_REGISTRY_URL
$(error Required variable DOCKER_REGISTRY_URL is not set.)
endif
ifndef DOCKER_REGISTRY_USERNAME
$(error Required variable DOCKER_REGISTRY_USERNAME is not set.)
endif
ifndef DOCKER_REGISTRY_TOKEN
$(error Required variable DOCKER_REGISTRY_TOKEN is not set.)
endif

export DOCKER_BUILDKIT=1
export DOCKER_FLAG=--force
TIMESTAMP := $(shell date +%Y-%m-%dT%H:%M:%S.0000000000Z)
CI_COMMIT_REF_NAME ?= -$(shell git rev-parse --abbrev-ref HEAD)
KUBECONFIG ?= $(HOME)/.kube/config

# Set common porter var env
PORTER_LOCAL_VERSION:=$(shell echo $$(porter version) | cut -d' ' -f2)
PORTER_DIR := $(HOME)/.porter
PORTER_CREDENTIAL_DIR := $(PORTER_DIR)/credentials
PORTER_CLAIM_DIR := $(PORTER_DIR)/claims

# Chcck installed helm3 mixin
HELM3_INSTALLED_MIXIN_VERSION := $(shell eval echo $$(echo $$(porter mixin list | grep helm3)) | cut -d' ' -f2)

CREDENTIAL_NAME := $(PROJECT_NAME)-credentials
CREDENTIAL_FILENAME := $(CREDENTIAL_NAME).json

IMAGE_TAG := $(DOCKER_REGISTRY_URL)/$(ORGANIZATION_NAME)/$(PROJECT_NAME):$(BUNDLE_VERSION)$(CI_COMMIT_REF_NAME)
INVOCATION_IMAGE :=$(DOCKER_REGISTRY_URL)/$(ORGANIZATION_NAME)/$(PROJECT_NAME)-installer:$(BUNDLE_VERSION)$(CI_COMMIT_REF_NAME)

export

help:
	@echo "====================================================="
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)
	@echo "====================================================="

all: generate-bundle-file build

## - generate-bundle-file: Command line to generate porter.yaml file from template.
generate-bundle-file: docker-purge
	@echo "====================================================="
	@echo " Bundle version is: $(BUNDLE_VERSION)"
	@echo " Registry is: $(DOCKER_REGISTRY_URL)"
	@echo " Project is: $(PROJECT_NAME)"
	@echo " Branch is: $(CI_COMMIT_REF_NAME)"
	@echo "====================================================="
	@rm -f "porter.yaml" ;
	@envsubst < "./porter.yaml.tmpl" > "porter.yaml"

## - build: Build the bundle using Porter.
build: generate-bundle-file
	@echo "====================================================="
	@echo " Porter version is $(PORTER_LOCAL_VERSION)"
	@echo " helm3 mixin version is $(HELM3_INSTALLED_MIXIN_VERSION)"
	@echo "====================================================="
	@make docker-login
	@porter build --debug
	@make docker-logout

## - publish: Publish a bundle image to an OCI docker registry.
publish: build
	@make docker-login
	@echo Bundle is published with tag: $(IMAGE_TAG)
	@porter publish --debug
	@make docker-logout

## - generate-credentials: Call Porter credential helper tool.
generate-credentials:
	porter credentials generate $(CREDENTIAL_NAME)

## - show-credentials: Display credentials store in Porter
show-credentials:
	porter credentials show $(CREDENTIAL_NAME)

## - install: Install a bundle from a published bundle image.
install: generate-porter-parameters-file
	@make docker-login
	@echo Bundle image is: $(IMAGE_TAG)
	@porter install --tag $(IMAGE_TAG) $(DOCKER_FLAG) --cred $(CREDENTIAL_NAME) $(PROJECT_NAME) --parameter-set ./bundle.parameters.json --debug  --allow-docker-host-access
	@porter installation list
	@make docker-logout

## - upgrade: Upgrade a bundle from a pulished bundle image.
upgrade: generate-porter-parameters-file
	@make docker-login
	@echo Bundle image is: $(IMAGE_TAG)
	@porter upgrade --tag $(IMAGE_TAG) $(DOCKER_FLAG) --cred $(CREDENTIAL_NAME) $(PROJECT_NAME) --parameter-set ./bundle.parameters.json --debug  --allow-docker-host-access
	@porter installation list
	@make docker-logout

## - uninstall: Uninstall a bundle from a published bundle image.
uninstall: generate-porter-parameters-file
	@make docker-login
	@echo Bundle image is: $(IMAGE_TAG)
	@porter uninstall --tag $(IMAGE_TAG) $(DOCKER_FLAG) --cred $(CREDENTIAL_NAME) $(PROJECT_NAME) --parameter-set ./bundle.parameters.json --debug  --allow-docker-host-access --delete
	@porter installation list
	@make docker-logout

## - install-local-bundle: Install a bundle from a local bundle image.
install-local-bundle: generate-porter-parameters-file
	@make docker-login
	@porter install --cred $(CREDENTIAL_NAME) $(PROJECT_NAME) --parameter-set ./bundle.parameters.json --debug  --allow-docker-host-access
	@porter installation list
	@make docker-logout

## - upgrade-local-bundle: Upgrade a bundle from a local bundle image.
upgrade-local-bundle: generate-porter-parameters-file
	@make docker-login
	@porter upgrade --cred $(CREDENTIAL_NAME) $(PROJECT_NAME) --parameter-set ./bundle.parameters.json --debug  --allow-docker-host-access
	@porter installation list
	@make docker-logout

## - uninstall-local-bundle: Upgrade a bundle from a local bundle image.
uninstall-local-bundle: generate-porter-parameters-file
	@make docker-login
	@porter uninstall --cred $(CREDENTIAL_NAME) $(PROJECT_NAME) --parameter-set ./bundle.parameters.json --debug  --allow-docker-host-access --delete
	@porter installation list
	@make docker-logout

## - docker-login: Login to docker registry.
docker-login:
	@echo user is $(DOCKER_REGISTRY_USERNAME)
	@echo $(DOCKER_REGISTRY_TOKEN) | docker login $(DOCKER_REGISTRY_URL) --username $(DOCKER_REGISTRY_USERNAME) --password-stdin

## - docker-logout: Logout from docker registry.
docker-logout:
	@docker logout $(DOCKER_REGISTRY_URL)

## - docker-prune: Clean all cached and dangling layers
docker-purge:
	@docker system prune

## - generate-porter-parameters-file: Generate parameters set from template
generate-porter-parameters-file:
	@rm -f porter.*.parameters.json ;
	@envsubst < "./bundle.parameters.json.tmpl" > "bundle.parameters.json"

inspect-invocation-image:
	@make docker-login
	DOCKER_CLI_EXPERIMENTAL=enabled \
	docker manifest inspect $(INVOCATION_IMAGE)
	@make docker-logout