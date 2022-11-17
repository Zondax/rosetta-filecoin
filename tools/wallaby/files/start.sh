#! /bin/bash

GREEN='\e[42m'
NC='\033[0m'

export LOTUS_VM_ENABLE_TRACING=1

lotus daemon --config /etc/lotus_config/config.toml &

LOTUS_CHAIN_INDEX_CACHE=32768
LOTUS_CHAIN_TIPSET_CACHE=8192

until [ -f /data/node/token ]
do
     echo -e "${GREEN}Waiting for token file to be created by lotus... ${NC}$"
     sleep 5
done

LOTUS_RPC_TOKEN=$( cat /data/node/token )

echo -e "${GREEN}### Launching filecoin-indexing-rosetta-proxy${NC}"
filecoin-indexing-rosetta-proxy 2>&1