#! /bin/bash

export LOTUS_VM_ENABLE_TRACING=1

lotus daemon --config /etc/lotus_config/config.toml &
sleep 5

echo -e "${GREEN}### Launching filecoin-indexing-rosetta-proxy${NC}"
filecoin-indexing-rosetta-proxy 2>&1