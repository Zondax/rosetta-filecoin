# Create builder container
FROM golang:1.14 as builder

# set BRANCH_FIL or COMMIT_HASH_FIL
ARG BRANCH_FIL=master
ARG COMMIT_HASH_FIL=""
ARG REPO_FIL=https://github.com/filecoin-project/lotus
ARG NODEPATH=/lotus


ENV DEBIAN_FRONTEND=noninteractive

# Clone Lotus
RUN if [ -z "${BRANCH_FIL}" ] && [ -z "${COMMIT_HASH_FIL}" ]; then \
  		echo 'Error: Both BRANCH_FIL and COMMIT_HASH_FIL are empty'; \
  		exit 1; \
    fi

RUN if [ ! -z "${BRANCH_FIL}" ] && [ ! -z "${COMMIT_HASH_FIL}" ]; then \
		echo 'Error: Both BRANCH_FIL and COMMIT_HASH_FIL are set'; \
		exit 1; \
	fi


WORKDIR ${NODEPATH}
RUN git clone ${REPO_FIL} ${NODEPATH}

RUN if [ ! -z "${BRANCH_FIL}" ]; then \
        echo "Checking out to Lotus branch: ${BRANCH_FIL}"; \
  		git checkout ${BRANCH_FIL}; \
    fi

RUN if [ ! -z "${COMMIT_HASH_FIL}" ]; then \
		echo "Checking out to Lotus commit: ${COMMIT_HASH_FIL}"; \
		git checkout ${COMMIT_HASH_FIL}; \
	fi

# Install Lotus deps
RUN apt-get update && \
    apt-get install -yy apt-utils && \
    apt-get install -yy gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev

RUN make 2k && make install

# Create final container
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ARG LOTUS_API_PORT=1234

# Install Lotus deps
RUN apt-get update && \
    apt-get install -yy apt-utils  && \
    apt-get install -yy bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev

# Install Lotus
COPY --from=builder /usr/local/bin/lotus* /usr/local/bin/
COPY --from=builder ${NODEPATH}/lotus/lotus-seed /usr/local/bin/

EXPOSE $LOTUS_API_PORT
RUN export LOTUS_SKIP_GENESIS_CHECK=_yes_

RUN lotus fetch-params 2048 && lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

RUN lotus-seed genesis new localnet.json && \
   lotus-seed genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json

# Copy config files
COPY ./tools/devnet_config.toml /devnet_config.toml

# Copy test actors keys
COPY ./tools/test_actor_1.key /test_actor_1.key
COPY ./tools/test_actor_2.key /test_actor_2.key
COPY ./tools/test_actor_3.key /test_actor_3.key

# Copy startup script
COPY ./tools/start_devnet.sh /start_devnet.sh

ENTRYPOINT ["/start_devnet.sh"]
CMD ["",""]

