#!/bin/bash

set -xe


bash run.sh https://github.com/jmazanec15/k-NN-1.git 2.x 4g 4 2 "no-train-test" "faiss-data-16-l2.json"

REMOTE_REPO=$1
REMOTE_BRANCH=$2
OS_MEM=$3
OS_CPU=$4
JVM_SIZE=$5
PROCEDURE=$6
PARAMS=$7

# First, setup tmp dirs
echo "Making dirs"
mkdir /tmp/profiles /tmp/artifacts /tmp/artifacts /tmp/results /tmp/datasets




# Second, build the custom image pointed at git
echo "Building the custom image"
cd ../custom-test-image
docker build -t pluginbuild -f Dockerfile.pluginbuild .
docker run -v /tmp/artifacts:/artifacts pluginbuild $REMOTE_REPO $REMOTE_BRANCH
bash run-custom-image-build.sh


# Third, create the network
echo "Creating the network"
docker network create cnetwork

# Forth, start metric server
echo "Starting the metric server"
cd ../metric-cluster
bash run-metric-server.sh

# Fifth, run prod server
echo "Starting prod server"
cd ../test-cluster
bash run-test-cluster.sh $OS_MEM $OS_CPU $JVM_SIZE


# Sixth, start the OSB
#TODO: Add command to pull proper dataset
echo "Starting OSB job"
cd ../custom-osb
cp /tmp/datasets/* custom/data/
bash run-osb-container.sh $PROCEDURE $PARAMS


echo "Done!"
