#!/bin/bash

# Simple wrapper to run OSB
export PROCEDURE="$1"
export PARAMS="$2"
export MEM=$3
export CPU=$4
export ITERATION=$5

echo $PROCEDURE
echo $PARAMS

# Extra steps for iteration 1
if [[ $ITERATION == 1 ]]; then
  # We build the image and then start the initial container. After which,
  # we need to attach to the container
  docker build -t customosb -f Dockerfile.customosb .
  docker run -m ${MEM} --cpus ${CPU} --network cnetwork --name osb -v /tmp/results:/results -td --entrypoint /bin/bash customosb
fi

docker exec osb /bin/bash /osb-entry-point.sh $PROCEDURE $PARAMS $ITERATION
