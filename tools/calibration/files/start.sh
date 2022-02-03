#! /bin/bash

GREEN='\e[42m'
NC='\033[0m'

lotus daemon --config /etc/lotus_config/config.toml &
sleep 5

lotus sync wait

# Import test actors
lotus wallet import /test_actor_1.key # t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba
lotus wallet import /test_actor_2.key # t1x5x7ekq5f2cjkk57ee3lismwmzu5rbhkhnsrooa
lotus wallet import /test_actor_3.key # f1itpqzzcx6yf52oc35dgsoxfqkoxpy6kdmygbaja

lotus wallet set-default t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba

sleep 20

# Create test msig actor and send some tokens to it
echo -e "${GREEN}Creating multisig actor...${NC}"
lotus msig create --required 1 t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba t1x5x7ekq5f2cjkk57ee3lismwmzu5rbhkhnsrooa # t01005

# Fund accounts
echo -e "${GREEN}To fund accounts use https://faucet.calibration.fildev.network/${NC}"

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
