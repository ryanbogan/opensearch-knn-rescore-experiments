

## Conda create env
```commandline
conda create -n knndisk python=3.9  
conda activate knndisk
```

## Compile requirements
```bash
# 1. Add dependencies in requirements.in

# 2. Install requirements for the environment with specific version


# 3. Install pip-tools
pip install pip-tools

# 4. Compile dependencies
pip-compile requirements.in 
```


## Running benchmark
```bash

# OpenSearch Cluster End point url with hostname and port
export ENDPOINT=localhost:9200
# Absolute file path of Workload param file
export PARAMS_FILE=params/faiss-data-16-l2.json

export PROCEDURE="search-only"

opensearch-benchmark execute-test \
    --target-hosts $ENDPOINT \
    --workload-path ./workload.json \
    --workload-params ${PARAMS_FILE} \
    --pipeline benchmark-only \
    --test-procedure=${PROCEDURE} \
    --kill-running-processes
```

## Getting recall
Add following configuration in `~/.benchmark/benchmark.ini`
```bash
[results_publishing]
datastore.type = opensearch
datastore.host = localhost
datastore.port = 9200
datastore.secure = False
datastore.user = 
datastore.password = 
```

Run the test. Get the test execution id. Then run:
```bash
curl -XPOST "localhost:9200/benchmark-metrics-*/_search?pretty" -H 'Content-Type: application/json' -d'
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
      "stored_fields": [
        "*"
      ],
      "script_fields": {},
      "docvalue_fields": [
        {
          "field": "@timestamp",
          "format": "date_time"
        },
        {
          "field": "test-execution-timestamp",
          "format": "date_time"
        }
      ],
      "_source": {
        "excludes": []
      },
      "query": {
        "bool": {
          "must": [],
          "filter": [
            {
              "match_phrase": {
                "test-execution-id": "TEST_ID"
              }
            },
            {
              "exists": {
                "field": "meta.recall@k"
              }
            }
          ],
          "should": [],
          "must_not": []
        }
      }
    }
'
```