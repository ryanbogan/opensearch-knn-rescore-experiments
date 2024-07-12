#!/bin/bash

# Run the metric opensearch cluster locally on port 9202. This cluster allows us to pull recall from
# osb results

OS_MEM=1G
OS_CPU=2
JVM_SIZE=512
IMAGE=opensearchproject/opensearch:2.15.0

container_id=$(docker run -d \
--name metrics \
-m ${OS_MEM} \
--cpus ${OS_CPU} \
-e "DISABLE_SECURITY_PLUGIN=true" \
--network cnetwork \
-p 9202:9202 \
-p 9602:9602 \
-e "discovery.type=single-node" \
-e "http.port=9202" \
-e "transport.port=9602" \
-e "OPENSEARCH_JAVA_OPTS=-Xms${JVM_SIZE}m -Xmx${JVM_SIZE}m" \
${IMAGE})

echo "${container_id}"
sleep 20
