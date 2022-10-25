#! /bin/bash

# Import test actors
lotus wallet import /test_actor_1.key # t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba
lotus wallet import /test_actor_2.key # t1x5x7ekq5f2cjkk57ee3lismwmzu5rbhkhnsrooa
lotus wallet import /test_actor_3.key # f1itpqzzcx6yf52oc35dgsoxfqkoxpy6kdmygbaja

lotus wallet set-default t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba

sleep 20

# Create test msig actor and send some tokens to it
echo -e "${GREEN}Creating multisig actor...${NC}"
lotus msig create --required 1 t1d2xrzcslx7xlbbylc5c3d5lvandqw4iwl6epxba t1x5x7ekq5f2cjkk57ee3lismwmzu5rbhkhnsrooa # t01005