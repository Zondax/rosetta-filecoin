# Create builder container
FROM golang:1.14 as builder

ARG BRANCH=master
ARG REPO=https://github.com/filecoin-project/lotus
ARG NODEPATH=/lotus

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -yy apt-utils && \
    apt-get install -yy gcc git bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev

RUN git clone --single-branch --branch ${BRANCH} ${REPO} ${NODEPATH}
RUN cd ${NODEPATH} && make build && make install

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

EXPOSE 1234
EXPOSE $ROSETTA_PORT

RUN echo ' \n\
'#!/bin/bash' \n\
lotus daemon& \n\
sleep 30 \n\
peers="lotus net peers | wc -l" \n\
while [ $(eval $peers) -eq 0 ] \n\
do \n\
echo "Waiting for peers..." \n\
sleep 5 \n\
done \n\
lotus sync wait ' >> /start.sh

RUN chmod +x /start.sh

CMD /start.sh && bash
