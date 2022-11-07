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
DOCKER_IMAGE_LIGHT=zondax/rosetta-filecoin-light:latest
DOCKER_DEVNET_IMAGE=zondax/filecoin-devnet:latest
DOCKER_BUTTERFLY_IMAGE=zondax/filecoin-butterfly:latest
DOCKER_CALIBRATION_IMAGE=zondax/filecoin-calibration:latest
DOCKER_WALLABY_IMAGE=zondax/filecoin-wallaby:latest

DOCKERFILE_MAIN=./tools/main/Dockerfile
DOCKERFILE_LIGHT_MAIN=./tools/main_light/Dockerfile
DOCKERFILE_DEVNET=./tools/dev/Dockerfile
DOCKERFILE_BUTTERFLY=./tools/butterfly/Dockerfile
DOCKERFILE_CALIBRATION=./tools/calibration/Dockerfile
DOCKERFILE_WALLABY=./tools/wallaby/Dockerfile

CONTAINER_NAME=lotusnode
CONTAINER_DEVNET_NAME=filecoin-devnet
CONTAINER_BUTTERFLY_NAME=filecoin-butterfly
CONTAINER_CALIBRATION_NAME=filecoin-calibration
CONTAINER_WALLABY_NAME=filecoin-wallaby

INTERACTIVE:=$(shell [ -t 0 ] && echo 1)
ROSETTA_PORT=8080
LOTUS_API_PORT = 1234
NPROC=16

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	NPROC=$(shell nproc)
endif
ifeq ($(UNAME_S),Darwin)
	NPROC=$(shell sysctl -n hw.physicalcpu)
endif

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
ifneq ($(MAX_RAM),)
	RAM_OPT="-m $(MAX_RAM) --oom-kill-disable"
endif

define run_docker
    docker run $(TTY_SETTING) $(INTERACTIVE_SETTING) --rm \
    --dns 8.8.8.8 \
    -m $(MAX_RAM) \
    --oom-kill-disable \
    --ulimit nofile=900000 \
    -v $(shell pwd)/data:/data \
    --name $(CONTAINER_NAME) \
    -p $(ROSETTA_PORT):$(ROSETTA_PORT) \
    -p $(LOTUS_API_PORT):$(LOTUS_API_PORT) \
    $(DOCKER_IMAGE) $(RUN_ARGS)
endef

define run_docker_light
    docker run $(TTY_SETTING) $(INTERACTIVE_SETTING) --rm \
    --dns 8.8.8.8 \
    -m $(MAX_RAM) \
    --oom-kill-disable \
    --ulimit nofile=900000 \
    --name $(CONTAINER_NAME) \
    -p $(ROSETTA_PORT):$(ROSETTA_PORT) \
    -p $(LOTUS_API_PORT):$(LOTUS_API_PORT) \
    $(DOCKER_IMAGE_LIGHT) $(RUN_ARGS)
endef

define run_devnet
    docker run $(TTY_SETTING) $(INTERACTIVE_SETTING) --rm \
    --dns 8.8.8.8 \
    $(RAM_OPT) \
    --cpus="$(NPROC)" \
    --ulimit nofile=90000:90000 \
    --name $(CONTAINER_DEVNET_NAME) \
    -p 1235:$(LOTUS_API_PORT) \
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

########################## BUILD ###################################
build:
	docker build -t $(DOCKER_IMAGE) -f $(DOCKERFILE_MAIN) --build-arg TOKEN=${READ_TOKEN} .
.PHONY: build

build_nosync:
	docker build -t $(DOCKER_IMAGE) -f $(DOCKERFILE_MAIN) --build-arg DISABLE_SYNC=1 .
.PHONY: build

build_light:
	docker build -t $(DOCKER_IMAGE_LIGHT) -f $(DOCKERFILE_LIGHT_MAIN) --build-arg TOKEN=${READ_TOKEN} .
.PHONY: build_light

build_devnet:
	docker build -t $(DOCKER_DEVNET_IMAGE) -f $(DOCKERFILE_DEVNET) --build-arg TOKEN=${READ_TOKEN} .
.PHONY: build_devnet

build_butterfly:
	docker build -t $(DOCKER_BUTTERFLY_IMAGE) -f $(DOCKERFILE_BUTTERFLY) --build-arg TOKEN=${READ_TOKEN} .
.PHONY: build_butterfly

build_calibration:
	docker build -t $(DOCKER_CALIBRATION_IMAGE) -f $(DOCKERFILE_CALIBRATION) --build-arg TOKEN=${READ_TOKEN} .
.PHONY: build_calibration

build_wallaby:
	docker build -t $(DOCKER_WALLABY_IMAGE) -f $(DOCKERFILE_WALLABY) --build-arg TOKEN=${READ_TOKEN} .
.PHONY: build_wallaby

rebuild:
	docker build --no-cache -t $(DOCKER_IMAGE) -f $(DOCKERFILE_MAIN) .
.PHONY: rebuild

rebuild_devnet:
	docker build --no-cache -t $(DOCKER_DEVNET_IMAGE) -f $(DOCKERFILE_DEVNET) .
.PHONY: rebuild_devnet

########################## RUN ###################################
clean:
	docker rmi $(DOCKER_IMAGE)
.PHONY: clean

run: build
	$(call run_docker)
.PHONY: run

run_light: build_light
	$(call run_docker_light)
.PHONY: run_light

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
