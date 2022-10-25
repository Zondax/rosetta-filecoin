#! /bin/bash

export LOTUS_VM_ENABLE_TRACING=1

lotus daemon --config /etc/lotus_config/config.toml --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false&
sleep 5

echo -e "${GREEN}### Launching filecoin-indexing-rosetta-proxy${NC}"
filecoin-indexing-rosetta-proxy 2>&1