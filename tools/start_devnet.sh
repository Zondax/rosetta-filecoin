#! /bin/bash

GREEN='\e[42m'
NC='\033[0m'

mkdir -p /root/.lotus && cp -fr /configFiles/* /root/.lotus
chmod 0600 /root/.lotus/*

lotus daemon --config /devnet_config.toml --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false&
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
lotus msig create --required 1 t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba t1x5x7ekq5f2cjkk57ee3lismwmzu5rbhkhnsrooa # t01004
lotus send t01004 5000

# Run forever until exit
while :
do
	sleep 1
done
