#!/bin/bash

set -xe

# Simple wrapper script that will give opportunity to run tests with
# different memory limits for one run versus another

mkdir -m 777 /tmp/share-data

docker compose --env-file env/index.env up -d

# Wait for the osb to exit
for (( ; ; ))
do
    CONTAINER_STATUS=$(docker inspect --format='{{.State.Running}}' "osb" 2>/dev/null)
    if [ "$CONTAINER_STATUS" != "true" ]; then
        break
    fi
    sleep 5
done

# Once done, we need to restart the OSB and Test clusters while
# keeping the shared data. Also, we need to drop the caches
docker compose --env-file env/search.env up -d
sudo free
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
sudo free
