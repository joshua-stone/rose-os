CACHE_CONTAINERFILE ?= build.Containerfile
OS_CONTAINERFILE ?= Containerfile
DEBUG_CONTAINERFILE ?= debug.Containerfile

FEDORA_MAJOR_VERSION ?= 41
REGISTRY ?= ghcr.io/joshua-stone
ORG ?= rose-os
FLAVOR ?= silverblue
TAG ?= latest
ARCH ?= $(shell uname -m)

PULL ?= --pull=newer
SQUASH ?= --squash
RM_ARG ?= --rm

CACHE_IMAGE_NAME ?= fedora-minimal
CACHE_SOURCE_IMAGE ?= fedora-minimal
CACHE_SOURCE_ORG ?= fedora
CACHE_BASE_IMAGE ?= quay.io/$(CACHE_SOURCE_ORG)/$(CACHE_SOURCE_IMAGE)

OS_IMAGE_NAME ?= $(FLAVOR)
OS_SOURCE_IMAGE ?= $(FLAVOR)
OS_SOURCE_ORG ?= fedora-ostree-desktops
OS_BASE_IMAGE ?= quay.io/$(OS_SOURCE_ORG)/$(OS_SOURCE_IMAGE)

DEBUG_IMAGE_NAME ?= $(ORG)-$(FLAVOR)
DEBUG_SOURCE_IMAGE ?= $(ORG)-$(FLAVOR)
DEBUG_SOURCE_ORG ?= joshua-stone
DEBUG_BASE_IMAGE=$(REGISTRY)/$(DEBUG_SOURCE_IMAGE)

all: build-rpm-cache build-os-image build-debug-image build-iso

build-iso :
	[[ -n "$(PULL)" ]] && podman pull --arch="$(ARCH)" "$(REGISTRY)/$(ORG)-$(FLAVOR):$(TAG)" ||:
	./build-iso.sh $(REGISTRY) $(ORG) $(FLAVOR) $(TAG) $(ARCH) $(FEDORA_MAJOR_VERSION)

build-rpm-cache :
	podman build $(RM_ARG) $(PULL) $(SQUASH) \
		--file $(CACHE_CONTAINERFILE) \
		--build-arg IMAGE_NAME=$(CACHE_IMAGE_NAME) \
		--build-arg SOURCE_IMAGE=$(CACHE_SOURCE_IMAGE) \
		--build-arg SOURCE_ORG=$(CACHE_SOURCE_ORG) \
		--build-arg BASE_IMAGE=$(CACHE_BASE_IMAGE) \
		--build-arg FEDORA_MAJOR_VERSION=$(FEDORA_MAJOR_VERSION) \
		--tag $(REGISTRY)/$(ORG)-rpms:$(FEDORA_MAJOR_VERSION)

build-os-image :
	podman build $(RM_ARG) $(PULL) $(SQUASH) \
		--file $(OS_CONTAINERFILE) \
		--build-arg IMAGE_NAME=$(OS_IMAGE_NAME) \
		--build-arg SOURCE_IMAGE=$(OS_SOURCE_IMAGE) \
		--build-arg SOURCE_ORG=$(OS_SOURCE_ORG) \
		--build-arg BASE_IMAGE=$(OS_BASE_IMAGE) \
		--build-arg FEDORA_MAJOR_VERSION=$(FEDORA_MAJOR_VERSION) \
		--tag $(REGISTRY)/$(ORG)-$(OS_IMAGE_NAME):$(FEDORA_MAJOR_VERSION)

build-debug-image :
	podman build $(RM_ARG) $(PULL) $(SQUASH) \
		--file $(DEBUG_CONTAINERFILE) \
		--build-arg IMAGE_NAME=$(DEBUG_IMAGE_NAME) \
		--build-arg SOURCE_IMAGE=$(DEBUG_SOURCE_IMAGE) \
		--build-arg SOURCE_ORG=$(DEBUG_SOURCE_ORG) \
		--build-arg BASE_IMAGE=$(DEBUG_BASE_IMAGE) \
		--build-arg FEDORA_MAJOR_VERSION=$(FEDORA_MAJOR_VERSION) \
		--tag $(REGISTRY)/$(ORG)-$(OS_IMAGE_NAME)-debug:$(FEDORA_MAJOR_VERSION)
