#!/bin/bash

set -xe

# bash run.sh 6g 8 2 "faiss-coh1m-768-l2.json" 64g 4
# bash run.sh 6g 8 2 "lucene-coh1m-768-l2.json" 64g 4
# bash run.sh 6g 8 2 "faiss-data-16-l2.json" 64g 4

OS_MEM=$1
OS_CPU=$2
JVM_SIZE=$3
PARAMS=$4
OSB_MEM=$5
OSB_CPU=$6

REMOTE_REPO=https://github.com/jmazanec15/k-NN-1.git
REMOTE_BRANCH=exact-scoring-exps

# First, setup prereqs
echo "Setup prereqs"
mkdir -m 777 /tmp/profiles /tmp/artifacts /tmp/results
docker network create cnetwork

# Second, build the custom image pointed at git
echo "Building the custom image"
cd ../custom-test-image/plugin-build
docker build -t pluginbuild -f Dockerfile.pluginbuild .
docker run -v /tmp/artifacts:/artifacts pluginbuild $REMOTE_REPO $REMOTE_BRANCH
cd ../
bash run-custom-image-build.sh

# Third, start metric server
echo "Starting the metric server"
cd ../metric-cluster
bash run-metric-server.sh

# Fourth, run prod server
echo "Starting prod server"
cd ../test-cluster
bash run-test-cluster.sh $OS_MEM $OS_CPU $JVM_SIZE

# Fifth, run OSB with indexing
echo "Starting OSB job"
cd ../custom-osb
bash run-osb-container.sh no-train-test $PARAMS $OSB_MEM $OSB_CPU 1

# Sixth, rerun and get a profile
echo "Re-running search workload with async profiling for 300s"
sleep 30
test_pid_pid=$(cat /tmp/test-pid)
test_container_id=$(docker ps -aqf "name=test")
docker exec -d -u 0 $test_container_id bash /profile-helper.sh $test_pid_pid 300
bash run-osb-container.sh search-only $PARAMS $OSB_MEM $OSB_CPU 2

echo "Done!"
