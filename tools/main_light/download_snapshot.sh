#!/bin/bash
set -e

GRN='\e[32;1m'
RED='\033[0;31m'
BOLDW='\e[1m'
OFF='\e[0m'

SNAPSHOT_DIR=/snapshot
SNAPSHOT_FILE=${SNAPSHOT_DIR}/snapshot.car
SNAPSHOT_CHECKSUM=snapshot.sha256sum
SNAPSHOT_CHECK_FILE=${SNAPSHOT_DIR}/${SNAPSHOT_CHECKSUM}

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

download_checksum() {
  echo -e "${GRN} Checking sha256sum${code} ${OFF}"
  curl -sI https://fil-chain-snapshots-fallback.s3.amazonaws.com/mainnet/minimal_finality_stateroots_latest.car | \
  perl -ne '/x-amz-website-redirect-location:\s(.+)\.car/ && print "$1.sha256sum"' | xargs wget -O $SNAPSHOT_CHECK_FILE
}

download_snapshot() {
  echo -e "${GRN} Downloading latest network snapshot ${code} ${OFF}"
  curl -sI https://fil-chain-snapshots-fallback.s3.amazonaws.com/mainnet/minimal_finality_stateroots_latest.car | \
  perl -ne '/x-amz-website-redirect-location:\s(.+)\.car/ && print "$1.car"' | xargs wget -O $SNAPSHOT_FILE
}

checksum() {
  echo "$(cut -c 1-64 $SNAPSHOT_CHECK_FILE) $SNAPSHOT_FILE" | sha256sum --check
}

full_download() {
  echo -e "${GRN}### Downloading latest snapshot ...${OFF}"
  download_checksum
  download_snapshot
  checksum
  echo -e "${GRN}### Finished downloading latest snapshot${OFF}"
}

mkdir -p $SNAPSHOT_DIR

if [ -f "$SNAPSHOT_FILE" ] && [ -f "$SNAPSHOT_CHECK_FILE" ]; then
    echo -e "${GRN} Checking if the existing snapshot is the latest one ... ${code} ${OFF}"
    mkdir ./test && cd ./test
    download_checksum

    if cmp --silent -- "$SNAPSHOT_CHECKSUM" "../$SNAPSHOT_CHECKSUM"; then
      echo -e "${BOLDW} The existing snapshot is the latest one ${code} ${OFF}"
      cd ../ && rm -rf ./test
      checksum
      exit_func
    else
      echo -e "${BOLDW} The existing snapshot is not the latest one ${code} ${OFF}"
      cd ../ && rm -rf ./test
      full_download
    fi

else
    full_download
fi

trap 'error ${LINENO}' ERR
trap 'exit_func 0' INT SIGINT

