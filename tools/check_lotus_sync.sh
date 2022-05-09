#!/usr/bin/env sh

set -e

LOTUS_SYNC_ALLOWED_DIFF=${LOTUS_SYNC_ALLOWED_DIFF:-100}

RESPONSE=$(curl --location -s  --header 'Content-Type: application/json' 127.0.0.1:1234/debug/metrics | grep '^lotus_chain_node_height_expected\|^lotus_chain_node_worker_height')

EXPECTED=$(printf %0.f $(echo "${RESPONSE}" | grep ^lotus_chain_node_height_expected | cut -d' ' -f2))
CURRENT=$(printf %0.f $(echo "${RESPONSE}" | grep ^lotus_chain_node_worker_height | cut -d' ' -f2))
DIFF=$(($EXPECTED-$CURRENT))

if [ ${DIFF} -gt ${LOTUS_SYNC_ALLOWED_DIFF} ]; then
    echo Lotus allowed sync diff rebased: ${DIFF} of ${LOTUS_SYNC_ALLOWED_DIFF}
    exit 1
fi
echo Lotus allowed sync diff ok: ${DIFF} of ${LOTUS_SYNC_ALLOWED_DIFF}
exit 0