.PHONY: all clean

BRANCH := $(shell git rev-parse --abbrev-ref HEAD | sed 's/[^a-zA-Z0-9_.-]/-/g; s/^[.-]/_/')
COMMIT := $(shell git rev-parse --short HEAD)
IMAGE := jforissier/optee_os_ci:$(BRANCH)-$(COMMIT)

all:
	docker build -t $(IMAGE) .

clean:
