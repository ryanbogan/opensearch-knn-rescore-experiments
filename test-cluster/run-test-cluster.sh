#!/bin/bash

# Start the test container
IMAGE=customimage
OS_MEM=$1
OS_CPU=$2
JVM_SIZE=$3

container_id=$(docker run -d \
--name test \
-m ${OS_MEM} \
--cpus ${OS_CPU} \
-e "DISABLE_SECURITY_PLUGIN=true" \
--network cnetwork \
-p 9200:9200 \
-p 9600:9600 \
-e "discovery.type=single-node" \
-e "OPENSEARCH_JAVA_OPTS=-Xms${JVM_SIZE}g -Xmx${JVM_SIZE}g" \
${IMAGE})

#TODO: We'll need this later when we want to profile. This will need to be done via main runner.
echo "CONTAINER_ID="$container_id
