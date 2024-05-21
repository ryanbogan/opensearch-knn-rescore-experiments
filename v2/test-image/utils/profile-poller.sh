#!/bin/bash

# Check if profile needs to be taken. Expectation is that /share-data/profile.txt
# will contain args to execute
SET_PROFILER_PATH=/share-data/profile.txt

OS_PID=$1

while true; do
  if [ -f ${SET_PROFILER_PATH} ]; then
    args=$(cat ${SET_PROFILER_PATH})
    rm ${SET_PROFILER_PATH}
    echo "Executing profile command"
    bash /profile-helper.sh ${OS_PID} ${args}
  fi
  sleep 1
done
