#*******************************************************************************
#*   (c) 2020 Zondax GmbH
#*
#*  Licensed under the Apache License, Version 2.0 (the "License");
#*  you may not use this file except in compliance with the License.
#*  You may obtain a copy of the License at
#*
#*      http://www.apache.org/licenses/LICENSE-2.0
#*
#*  Unless required by applicable law or agreed to in writing, software
#*  distributed under the License is distributed on an "AS IS" BASIS,
#*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#*  See the License for the specific language governing permissions and
#*  limitations under the License.
#********************************************************************************

DOCKER_IMAGE=zondax/rosetta-filecoin:latest
DOCKER_DEVNET_IMAGE=zondax/filecoin-devnet:latest
DOCKERFILE_DEVNET=./tools/devnet.dockerfile

CONTAINER_NAME=lotusnode
CONTAINER_DEVNET_NAME=filecoin-devnet

INTERACTIVE:=$(shell [ -t 0 ] && echo 1)
ROSETTA_PORT=8080
LOTUS_API_PORT = 1234

ifdef INTERACTIVE
INTERACTIVE_SETTING:="-i"
TTY_SETTING:="-t"
else
INTERACTIVE_SETTING:=
TTY_SETTING:=
endif

ifeq (run,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif


MAX_RAM:=$(shell grep MemTotal /proc/meminfo | awk '{print $$2 $$3}')

define run_docker
    docker run $(TTY_SETTING) $(INTERACTIVE_SETTING) --rm \
    --dns 8.8.8.8 \
    -m $(MAX_RAM) \
    --oom-kill-disable \
    --ulimit nofile=9000:9000 \
    -v $(shell pwd)/data:/data \
    --name $(CONTAINER_NAME) \
    -p $(ROSETTA_PORT):$(ROSETTA_PORT) \
    -p $(LOTUS_API_PORT):$(LOTUS_API_PORT) \
    $(DOCKER_IMAGE) $(RUN_ARGS)
endef

define run_devnet
    docker run $(TTY_SETTING) $(INTERACTIVE_SETTING) --rm \
    --dns 8.8.8.8 \
    -m $(MAX_RAM) \
    --oom-kill-disable \
    --ulimit nofile=9000:9000 \
    --name $(CONTAINER_DEVNET_NAME) \
    -p $(LOTUS_API_PORT):$(LOTUS_API_PORT) \
    $(DOCKER_DEVNET_IMAGE) $(RUN_ARGS)
endef

define kill_docker
	docker kill $(1)
endef

define login_docker
	docker exec -ti $(1) /bin/bash
endef

all: run
.PHONY: all

build:
	docker build -t $(DOCKER_IMAGE) .
.PHONY: build

build_devnet:
	docker build -t $(DOCKER_DEVNET_IMAGE) -f $(DOCKERFILE_DEVNET) .
.PHONY: build_devnet

rebuild:
	docker build --no-cache -t $(DOCKER_IMAGE) .
.PHONY: rebuild

rebuild_devnet:
	docker build --no-cache -t $(DOCKER_DEVNET_IMAGE) -f $(DOCKERFILE_DEVNET) .
.PHONY: rebuild_devnet

clean:
	docker rmi $(DOCKER_IMAGE) .
.PHONY: clean

run: build
	$(call run_docker)
.PHONY: run

run_devnet: build_devnet
	$(call run_devnet)
.PHONY: run_devnet

login:
	$(call login_docker,${CONTAINER_NAME})
.PHONY: login

login_devnet:
	$(call login_docker,${CONTAINER_DEVNET_NAME})
.PHONY: login_devnet

stop:
	$(call kill_docker,${CONTAINER_NAME})
.PHONY: stop

stop_devnet:
	$(call kill_docker,${CONTAINER_DEVNET_NAME})
.PHONY: stop_devnet