#! /bin/bash

mkdir -p /root/.lotus && cp -fr /configFiles/* /root/.lotus
chmod 0600 -R /root/.lotus

lotus daemon --config /etc/lotus_config/config.toml --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false&
sleep 20

echo -e "${GREEN}### Launching filecoin-indexing-rosetta-proxy${NC}"
filecoin-indexing-rosetta-proxy 2>&1

lotus-miner  wait-api