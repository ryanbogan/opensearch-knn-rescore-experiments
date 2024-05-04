#!/bin/bash

# Simple wrapper to run OSB

if [ "$#" -ne 2 ]; then
  export PROCEDURE="no-train-test"
  export PARAMS="faiss-data-16-l2.json"
else
  export PROCEDURE="$1"
  export PARAMS="$2"
fi
echo $PROCEDURE
echo $PARAMS

docker build -t customosb -f Dockerfile.customosb .
docker run --name osb --network cnetwork -v /tmp/results:/results customosb search-only $PROCEDURE $PARAMS
