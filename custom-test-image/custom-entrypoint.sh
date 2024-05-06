#!/bin/bash

set -xe

# First, run opensearch
./opensearch-docker-entrypoint.sh &
OS_PID=$!
echo $OS_PID
bash /process-stats-collector.sh ${OS_PID}
