#!/bin/bash

# Simple wrapper to run OSB
export PROCEDURE="$1"
export PARAMS="$2"
export MEM=$3
export CPU=$4
export ITERATION=$5

echo $PROCEDURE
echo $PARAMS

docker build -t customosb -f Dockerfile.customosb .
docker run -m ${MEM} --cpus ${CPU} --network cnetwork -v /tmp/results:/results customosb $PROCEDURE $PARAMS $ITERATION
