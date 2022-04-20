# Create builder container
FROM golang:1.17 as builder

# Configure token for reading private repos
ARG TOKEN
ENV GOPRIVATE=github.com/Zondax/*
RUN echo "machine github.com login $TOKEN password x-oauth-basic" > ~/.netrc

# set BRANCH_FIL or COMMIT_HASH_FIL
ARG BRANCH_FIL="experimental/fvm-m2"
ARG COMMIT_HASH_FIL=""
ARG REPO_FIL=https://github.com/filecoin-project/lotus
ARG NODEPATH=/lotus

# set BRANCH_PROXY or COMMIT_HASH_PROXY
ARG BRANCH_PROXY="v1.1600.5"
ARG COMMIT_HASH_PROXY=""
ARG REPO_PROXY=https://github.com/Zondax/filecoin-indexing-rosetta-proxy.git
ARG PROXYPATH=/rosetta-proxy

ENV DEBIAN_FRONTEND=noninteractive

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

ENV RUSTFLAGS="-C target-cpu=native -g"
ENV FFI_BUILD_FROM_SOURCE=0

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
    apt-get install -yy gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev hwloc libhwloc-dev

RUN make 2k && make install


# Clone filecoin-indexing-rosetta-proxy
RUN if [ -z "${BRANCH_PROXY}" ] && [ -z "${COMMIT_HASH_PROXY}" ]; then \
  		echo 'Error: Both BRANCH_PROXY and COMMIT_HASH_PROXY are empty'; \
  		exit 1; \
    fi

RUN if [ ! -z "${BRANCH_PROXY}" ] && [ ! -z "${COMMIT_HASH_PROXY}" ]; then \
		echo 'Error: Both BRANCH_PROXY and COMMIT_HASH_PROXY are set'; \
		exit 1; \
	fi

WORKDIR ${PROXYPATH}
RUN git clone --recurse-submodules ${REPO_PROXY} ${PROXYPATH}

RUN if [ ! -z "${BRANCH_PROXY}" ]; then \
        echo "Checking out to proxy branch: ${BRANCH_PROXY}"; \
  		git checkout ${BRANCH_PROXY}; \
    fi

RUN if [ ! -z "${COMMIT_HASH_PROXY}" ]; then \
		echo "Checking out to proxy commit: ${COMMIT_HASH_PROXY}"; \
		git checkout ${COMMIT_HASH_PROXY}; \
	fi

RUN make build

# Create final container
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ARG ROSETTA_PORT=8080
ARG LOTUS_API_PORT=1234
ARG PROXYPATH=/rosetta-proxy

# Install Lotus deps
RUN apt-get update && \
    apt-get install -yy apt-utils  && \
    apt-get install -yy curl  && \
    apt-get install -yy bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev wget libltdl7 libnuma1 hwloc libhwloc-dev

# Install Lotus
COPY --from=builder /usr/local/bin/lotus* /usr/local/bin/
COPY --from=builder ${NODEPATH}/lotus/lotus-seed /usr/local/bin/

#Install rosetta proxy
COPY --from=builder ${PROXYPATH}/filecoin-indexing-rosetta-proxy /usr/local/bin

ENV LOTUS_RPC_URL=ws://127.0.0.1:1234/rpc/v0
ENV LOTUS_RPC_TOKEN=""

EXPOSE $ROSETTA_PORT
EXPOSE $LOTUS_API_PORT

RUN export LOTUS_SKIP_GENESIS_CHECK=_yes_

RUN lotus fetch-params 2048 && lotus-seed pre-seal --sector-size 2KiB --num-sectors 2

RUN lotus-seed genesis new localnet.json && \
   lotus-seed genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json

# Copy config files
COPY ./tools/dev/files/config.toml /etc/lotus_config/config.toml
COPY ./tools/dev/files/rosetta_config.yaml /config.yaml
COPY ./tools/dev/node/api /configFiles/api

# Copy keys files
COPY ./tools/dev/node/token /configFiles/token
COPY ./tools/dev/node/keystore /configFiles/keystore

# Copy test actors keys
COPY ./tools/dev/files/test_actor_1.key /test_actor_1.key
COPY ./tools/dev/files/test_actor_2.key /test_actor_2.key
COPY ./tools/dev/files/test_actor_3.key /test_actor_3.key

# Copy startup script
COPY ./tools/dev/files/start.sh /start.sh

# Copy check lotus sync script
COPY ./tools/check_lotus_sync.sh /usr/local/bin/

ENTRYPOINT ["/start.sh"]
CMD ["",""]

