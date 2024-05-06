#!/bin/bash

# Start the test container
IMAGE=customimage
OS_MEM=$1
OS_CPU=$2
JVM_SIZE=$3

container_id=$(docker run -d \
--name test \
-v /tmp/profiles:/profiles \
-m ${OS_MEM} \
--cpus ${OS_CPU} \
-e "DISABLE_SECURITY_PLUGIN=true" \
--network cnetwork \
-p 9200:9200 \
-p 9600:9600 \
-e "discovery.type=single-node" \
-e "OPENSEARCH_JAVA_OPTS=-Xms${JVM_SIZE}g -Xmx${JVM_SIZE}g" \
${IMAGE})
sleep 15


#TODO: We'll need this later when we want to profile. This will need to be done via main runner.
echo "CONTAINER_ID="$container_id

PID=$(docker logs $container_id | grep -oE 'pid\[([0-9]+)\]' | sed 's/pid\[\([0-9]*\)\]/\1/')

echo $PID
docker exec -d $container_id bash /process-stats-collector.sh $PID

bash utils/docker-stats-collector.sh $container_id &
