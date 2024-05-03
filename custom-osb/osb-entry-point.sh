#!/bin/bash

set -x

# Get the benchmark args
if [ "$#" -ne 2 ]; then
  export PROCEDURE="no-train-test"
  export PARAMS="faiss-data-16-l2.json"
else
  export PROCEDURE="$1"
  export PARAMS="$2"
fi
echo PROCEDURE
echo PARAMS

# Initialize OSB so benchmark.ini gets created and patch benchmark.ini
echo "Initializing OSB..."
opensearch-benchmark execute-test > /dev/null 2>&1
bash /bench-config-patch-script.sh /benchmark.ini.patch ~/.benchmark/benchmark.ini
cat ~/.benchmark/benchmark.ini

# Confirm access to metrics cluster
echo "Confirming access to metrics cluster..."
curl metrics:9202

# Confirm access to test cluster
echo "Confirming access to test cluster..."
curl test:9200

# Run OSB and write output to a particular file in results
echo "Running OSB..."
cd /custom

# Setup params
export ENDPOINT=test:9200
export PARAMS_FILE=params/${PARAMS}

opensearch-benchmark execute-test \
    --target-hosts $ENDPOINT \
    --workload-path ./workload.json \
    --workload-params ${PARAMS_FILE} \
    --pipeline benchmark-only \
    --test-procedure=${PROCEDURE} \
    --kill-running-processes \
    --results-format=csv \
    --results-file=/results/osb-results.csv | tee /tmp/output.txt

task_id=$(cat /tmp/output.txt | grep "Test Execution ID" | awk -F ': ' '{print $2}')
echo $task_id

# On completion, get recall from metrics cluster and write to recall.txt
echo "Getting recall from metrics cluster..."
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

echo "hits: $hits"
echo "recall: $recall"

echo $recall > /results/recall.txt

# Complete!
echo "Success!"
