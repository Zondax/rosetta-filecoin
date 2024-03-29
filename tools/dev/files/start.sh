#! /bin/bash

GREEN='\e[42m'
NC='\033[0m'

export LOTUS_VM_ENABLE_TRACING=1

mkdir -p /root/.lotus && cp -fr /configFiles/* /root/.lotus
chmod 0600 -R /root/.lotus

lotus daemon --config /etc/lotus_config/config.toml --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false&
sleep 5

# Import test actors
lotus wallet import /test_actor_1.key # t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba
lotus wallet import /test_actor_2.key # t1x5x7ekq5f2cjkk57ee3lismwmzu5rbhkhnsrooa
lotus wallet import /test_actor_3.key # f1itpqzzcx6yf52oc35dgsoxfqkoxpy6kdmygbaja

# Create and init miner
echo -e "${GREEN}Creating miner...${NC}"
lotus wallet import --as-default ~/.genesis-sectors/pre-seal-t01000.key
lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=~/.genesis-sectors --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync && \
lotus-miner run --nosync&

sleep 20

# Fund accounts
echo -e "${GREEN}Funding accounts...${NC}"
lotus send t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba 1000
lotus send t1x5x7ekq5f2cjkk57ee3lismwmzu5rbhkhnsrooa 1000
lotus send f1itpqzzcx6yf52oc35dgsoxfqkoxpy6kdmygbaja 1000
lotus send t137sjdbgunloi7couiy4l5nc7pd6k2jmq32vizpy 1000

# Create test msig actor and send some tokens to it
echo -e "${GREEN}Creating multisig actor...${NC}"
lotus msig create --required 1 t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba t1x5x7ekq5f2cjkk57ee3lismwmzu5rbhkhnsrooa # t01005
lotus send t01005 5000


LOTUS_CHAIN_INDEX_CACHE=32768
LOTUS_CHAIN_TIPSET_CACHE=8192

until [ -f /root/.lotus/token ]
do
     echo -e "${GREEN}Waiting for token file to be created by lotus... ${NC}$"
     sleep 5
done

LOTUS_RPC_TOKEN=$( cat /root/.lotus/token )

echo -e "${GREEN}### Launching filecoin-indexing-rosetta-proxy${NC}"
filecoin-indexing-rosetta-proxy 2>&1