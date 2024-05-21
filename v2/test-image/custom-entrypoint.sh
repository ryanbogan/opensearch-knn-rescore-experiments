#!/bin/bash

set -mxe

echo "Starting Opensearch"

./opensearch-docker-entrypoint.sh opensearch &
ENTRY_PID=$!
echo "Entry: ${ENTRY_PID}"
sleep 5
OS_PID=`ps aux | grep "[o]rg.opensearch.bootstrap.OpenSearch" | tr -s ' ' | cut -d ' ' -f2`
echo "OS: ${OS_PID}"
bash /profile-poller.sh ${OS_PID} &
bash /process-stats-collector.sh ${OS_PID} ${OSB_PROCEDURE} &

# Foreground original process
fg %1
