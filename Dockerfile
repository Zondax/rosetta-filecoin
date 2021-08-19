# Create builder container
FROM golang:1.16 as builder

# set BRANCH_FIL or COMMIT_HASH_FIL
ARG BRANCH_FIL=v1.11.1
ARG COMMIT_HASH_FIL=""
ARG REPO_FIL=https://github.com/filecoin-project/lotus
ARG NODEPATH=/lotus

# set BRANCH_PROXY or COMMIT_HASH_PROXY
ARG BRANCH_PROXY=main
ARG COMMIT_HASH_PROXY=""
ARG REPO_PROXY=https://github.com/Zondax/filecoin-indexing-rosetta-proxy.git
ARG PROXYPATH=/rosetta-proxy

ENV DEBIAN_FRONTEND=noninteractive

# Install Lotus deps
RUN apt-get update && \
    apt-get install -yy apt-utils && \
    apt-get install -yy gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev hwloc libhwloc-dev

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

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

ENV RUSTFLAGS="-C target-cpu=native -g"
ENV FFI_BUILD_FROM_SOURCE=1
ARG DISABLE_SYNC

# This will disable sync by setting the number of sync workers to 0
RUN if [ ! -z $DISABLE_SYNC ]; then \
		echo "\n\n\nWARNING : Patching + disabling synchronization\n\n\n"; \
		sed -i -E 's/^[ \t]*MaxSyncWorkers[ \t]*=[ \t]*[0-9]*$/MaxSyncWorkers=0/g' chain/sync_manager.go; \
		head -n 25 chain/sync_manager.go; \
	fi

RUN make build && make install


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




###################################################




# Create final container
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ARG ROSETTA_PORT=8080
ARG LOTUS_API_PORT=1234
ARG PROXYPATH=/rosetta-proxy

# Install Lotus deps
RUN apt-get update && \
    apt-get install -yy apt-utils  && \
    apt-get install -yy curl && \
    apt-get install -yy bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev wget libltdl7 libnuma1 hwloc libhwloc-dev

# Install Lotus
COPY --from=builder /usr/local/bin/lotus* /usr/local/bin/
#Check Lotus installation
RUN lotus --version

# Copy config files
COPY ./tools/mainnet_config.toml /etc/lotus_config/mainnet.toml

RUN mkdir -p /data/{node,storage}
ENV LOTUS_PATH=/data/node/
ENV LOTUS_STORAGE_PATH=/data/storage/

#Install rosetta proxy
COPY --from=builder ${PROXYPATH}/filecoin-indexing-rosetta-proxy /usr/local/bin

# Copy config files
COPY --from=builder ${PROXYPATH}/config.yaml /

ENV LOTUS_RPC_URL=ws://127.0.0.1:1234/rpc/v0
ENV LOTUS_RPC_TOKEN=""

EXPOSE $ROSETTA_PORT
EXPOSE $LOTUS_API_PORT

#Copy entrypoint script
COPY --from=builder ${PROXYPATH}/start.sh /

ENTRYPOINT ["/start.sh", "--config", "/etc/lotus_config/mainnet.toml"]
CMD ["",""]

