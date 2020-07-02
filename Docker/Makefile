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

.PHONY: all build_docker login_docker run stop 

DOCKER_IMAGE=lotus:latest
CONTAINER_NAME=lotusnode

INTERACTIVE:=$(shell [ -t 0 ] && echo 1)

ifdef INTERACTIVE
INTERACTIVE_SETTING:="-i"
TTY_SETTING:="-t"
else
INTERACTIVE_SETTING:=
TTY_SETTING:=
endif

define run_docker
	docker run $(TTY_SETTING) $(INTERACTIVE_SETTING) --rm \
	-v $(shell pwd)/data:/data \
	-d \
	--name $(CONTAINER_NAME) \
	$(DOCKER_IMAGE) \
	"$(2)"
endef

define kill_docker
	docker kill $(CONTAINER_NAME)
endef

define login_docker
	docker exec -ti $(CONTAINER_NAME) /bin/bash
endef

all: build

build_docker:
	docker build --rm  -f dockerfile -t $(DOCKER_IMAGE) .

run:
	$(call run_docker) 

login_docker:
	$(call login_docker) 

stop:
	$(call kill_docker)
