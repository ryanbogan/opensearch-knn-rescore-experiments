#!/bin/bash -xe

source activate py38


ENGINE=$1
DIM=$2
TEST_COUNT=$3
QUERY_COUNT=$4

CUSTOM_IMAGE_NAME="custom-script-score"
CUSTOM_IMAGE_TAG="latest"

# Start it
OS_CPU=8
OS_MEM=16g
JVM_SIZE=8
docker run -d \
-m ${OS_MEM} \
--cpus ${OS_CPU} \
-e "DISABLE_SECURITY_PLUGIN=true" \
-p 9200:9200 \
-p 9600:9600 \
-e "discovery.type=single-node" \
-e "OPENSEARCH_JAVA_OPTS=-Xms${JVM_SIZE}g -Xmx${JVM_SIZE}g" \
${CUSTOM_IMAGE_NAME}:${CUSTOM_IMAGE_TAG}
sleep 20
curl localhost:9200

DOCKER_ID=`docker ps | grep ${CUSTOM_IMAGE_NAME}:${CUSTOM_IMAGE_TAG} | cut -d " " -f1`
echo ${DOCKER_ID}

echo "Ingest"
python experiment.py ingest ${ENGINE} ${DIM} ${TEST_COUNT}
echo "sleeping in hopes forcemerge finishes"
sleep 80

python experiment.py query ${ENGINE} ${DIM} ${QUERY_COUNT}

# clean up
docker kill ${DOCKER_ID} | docker container prune && echo "y" | docker volume prune && echo "y" | docker image prune && docker ps --all
