# Create builder container
FROM golang:1.14 as builder

ARG BRANCH=rosetta_integration
ARG NODEPATH=/lotus

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -yy apt-utils && \
    apt-get install -yy gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev

RUN git clone --single-branch --branch $BRANCH https://github.com/Zondax/lotus.git ${NODEPATH}
RUN cd ${NODEPATH} && make rosetta-api && make install


# Create final container
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ARG ROSETTA_PORT=8080

RUN apt-get update && \
    apt-get install -yy apt-utils  && \
    apt-get install -yy bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev

COPY --from=builder /usr/local/bin/lotus* /usr/local/bin/

RUN mkdir -p /data/{node,storage}

ENV LOTUS_PATH=/data/node/
ENV LOTUS_STORAGE_PATH=/data/storage/

EXPOSE $ROSETTA_PORT

RUN printf "#!/bin/bash \
\n# Run lotus daemon \
\n lotus daemon & \
\n sleep 30 \
\n peers='lotus net peers | wc -l' \
\n while [[ eval $peers -eq 0 ]] \
\n do \
\n sleep 5 \
\n done \
\n lotus sync wait\n" > /start.sh

RUN chmod +x /start.sh

CMD /start.sh && bash
