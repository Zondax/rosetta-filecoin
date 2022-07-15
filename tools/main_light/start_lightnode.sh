#!/bin/bash
set -e

GRN='\e[32;1m'
RED='\033[0;31m'
BOLDW='\e[1m'
OFF='\e[0m'

error() {
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo -e "${RED} Error: ${message}; exiting with status ${code} ${OFF}"
  else
    echo -e "${RED} Error; exiting with status ${code} ${OFF}"
  fi
  exit_func "${code}"
}

exit_func() {
  echo -e "${GRN}Exiting...${OFF}"
  trap - SIGINT SIGTERM
  kill -- -$$
  exit "$1"
}

# From lotus v1.16 and on we need to enable this flag to have a full trace output
export LOTUS_VM_ENABLE_TRACING=1
export LOTUS_USE_FVM_TO_SYNC_MAINNET_V15=1

echo -e "${GRN}Running command: ${OFF}${BOLDW}lotus daemon $1 $2${OFF}"

[ -z "$GOLOG_LOG_LEVEL" ] && export GOLOG_LOG_LEVEL=INFO
echo -e "${GRN}Using Lotus logger level:${OFF}${BOLDW} ${GOLOG_LOG_LEVEL} ${OFF}"

echo -e "${GRN} Downloading latest network snapshot ${code} ${OFF}"
curl -sI https://fil-chain-snapshots-fallback.s3.amazonaws.com/mainnet/minimal_finality_stateroots_latest.car | \
perl -ne '/x-amz-website-redirect-location:\s(.+)\.car/ && print "n$1.car"' | xargs wget -O snapshot.car

echo -e "${GRN} Checking sha256sum${code} ${OFF}"
curl -sI https://fil-chain-snapshots-fallback.s3.amazonaws.com/mainnet/minimal_finality_stateroots_latest.car | \
perl -ne '/x-amz-website-redirect-location:\s(.+)\.car/ && print "$1.sha256sum"' | xargs wget -O snapshot.sha256sum

# Replace the filenames for both `.sha256sum` and `.car` files based on the snapshot you downloaded.
echo "$(cut -c 1-64 snapshot.sha256sum) snapshot.car" | sha256sum --check

# Replace the filename for the `.car` file based on the snapshot you downloaded.
lotus daemon --import-snapshot snapshot.car

trap 'error ${LINENO}' ERR
trap 'exit_func 0' INT SIGINT

LOTUS_CHAIN_INDEX_CACHE=32768
LOTUS_CHAIN_TIPSET_CACHE=8192

until [ -f /data/node/token ]
do
     echo -e "${GRN}Waiting for token file to be created by lotus... ${OFF}$"
     sleep 5
done

LOTUS_RPC_TOKEN=$( cat /data/node/token )

echo -e "${GRN}### Launching filecoin-indexing-rosetta-proxy${OFF}"
filecoin-indexing-rosetta-proxy 2>&1
