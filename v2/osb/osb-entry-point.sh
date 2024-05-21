#!/bin/bash

set -x

# Parse some arguments
export PROCEDURE="$OSB_PROCEDURE"
export PARAMS="$OSB_PARAMS"
export SHOULD_PROFILE="$OSB_SHOULD_PROFILE"

get_recall() {
    local task_id="$1"
    output=$(curl -XPOST "metrics:9202/benchmark-metrics-*/_search?pretty" -H 'Content-Type: application/json' -d'
      {
        "aggs": {
          "2": {
            "date_histogram": {
              "field": "test-execution-timestamp",
              "calendar_interval": "1m",
              "time_zone": "America/Los_Angeles",
              "min_doc_count": 1
            },
            "aggs": {
              "1": {
                "avg": {
                  "field": "meta.recall@k"
                }
              }
            }
          }
        },
        "size": 0,
        "_source": {
          "includes": ["meta.recall@k"]
        },
        "query": {
          "bool": {
            "filter": [
              {
                "match": {
                  "test-execution-id": {
                     "query": "'$task_id'"
                  }
                }
              },
              {
                "match": {
                  "name" : {
                    "query": "service_time"
                   }
                 }
              },
              {
                "match": {
                  "operation" : {
                    "query": "exact-knn-query"
                   }
                 }
              }
            ]
          }
        }
      }
    ')

    hits=$(echo "$output" | jq -r '.aggregations["2"]["buckets"][0]["doc_count"]')
    recall=$(echo "$output" | jq -r '.aggregations["2"]["buckets"][0]["1"]["value"]')
    echo "$recall"
}

# Just sleep for a minute initially in order to let other containers come up healthily
sleep 60

# Confirm access to metrics cluster
echo "Confirming access to metrics cluster..."
curl metrics:9202

# Confirm access to test cluster
echo "Confirming access to test cluster..."
curl test:9200

SHARED_PATH=/share-data
RESULTS_PATH=${SHARED_PATH}/results
SET_PROFILER_PATH=${SHARED_PATH}/profile.txt
PROFILES_PATH=${SHARED_PATH}/profiles

mkdir -p -m 777 ${RESULTS_PATH} ${PROFILES_PATH}

# Initialize OSB so benchmark.ini gets created and patch benchmark.ini
if [ ! -f "~/.benchmark/benchmark.ini" ]; then
  echo "Initializing OSB..."
  opensearch-benchmark execute-test > /dev/null 2>&1
  bash /bench-config-patch-script.sh /benchmark.ini.patch ~/.benchmark/benchmark.ini
fi

# Run OSB and write output to a particular file in results
echo "Running OSB..."
cd /custom
export ENDPOINT=test:9200
export PARAMS_FILE=params/${PARAMS}

if [ "$SHOULD_PROFILE" = "true" ]; then
  PROFILE_DURATION=60
  PROFILE_OUTPUT=${PROFILES_PATH}/flamegraph
  PROFILE_DELAY=120 # Time to delay before starting profiler
  echo "${PROFILE_DURATION} ${PROFILE_OUTPUT}-${PROCEDURE}.html ${PROFILE_DELAY}" > ${SET_PROFILER_PATH}
fi
opensearch-benchmark execute-test \
    --target-hosts $ENDPOINT \
    --workload-path ./workload.json \
    --workload-params ${PARAMS_FILE} \
    --pipeline benchmark-only \
    --test-procedure=${PROCEDURE} \
    --kill-running-processes \
    --results-format=csv \
    --results-file=${RESULTS_PATH}/osb-results-${PROCEDURE}.csv | tee /tmp/output.txt
task_id=$(cat /tmp/output.txt | grep "Test Execution ID" | awk -F ': ' '{print $2}')

# If its search procedure, get the recall value
if [ "$PROCEDURE" = "search-only" ]; then
  recall_value=$(get_recall $task_id)
  echo $recall_value > ${RESULTS_PATH}/recall-${PROCEDURE}.txt
fi
