import random
import sys
from opensearchpy import OpenSearch, RequestsHttpConnection
import time

def _get_test_body(field_name: str, engine: str, dimension: int):
    return {
        'mappings': {
            'properties': {
                field_name: {
                    'type': 'knn_vector',
                    'dimension': dimension,
                    'method': {
                        "name": "hnsw",
                        "engine": engine,
                        "space_type": "l2",
                        "parameters": {
                            "m": 4,
                            "ef_construction": 16
                        }
                    }
                }
            }
        },
        'settings': {
            'index': {
                'knn': True,
            },
            'number_of_shards': 1,
            'number_of_replicas': 0,
        }
    }


def create_index(os_client: OpenSearch, index_name: str, field_name: str, engine: str, dimension: int):
    os_client.indices.delete(index=index_name, ignore=[400, 404])
    os_client.indices.create(index=index_name, body=_get_test_body(field_name, engine, dimension))


def ingest_docs(os_client: OpenSearch, index_name: str, field_name: str, dimension: int, doc_count: int):
    bulk_size = 100

    def create_header(doc_id):
        return {'index': {'_index': index_name, '_id': doc_id}}

    def _bulk_transform(partition, offset: int):
        actions = []
        _ = [
            actions.extend([create_header(_id + offset), None]) for _id in range(len(partition))
        ]
        actions[1::2] = [_build_index_doc(vec) for vec in partition]
        return actions

    def _salt_vector(vec):
        return [v + random.random() for v in vec]

    def _build_index_doc(vec):
        return {field_name: _salt_vector(vec)}

    for i in range(0, doc_count, bulk_size):
        vectors = [[random.random() for _ in range(dimension)] for _ in range(bulk_size)]
        body = _bulk_transform(vectors, i)
        os_client.bulk(index=index_name, body=body)


def _get_opensearch_client(endpoint: str, port: int):
    return OpenSearch(
        hosts=[{
            'host': endpoint,
            'port': port
        }],
        use_ssl=False,
        verify_certs=False,
        connection_class=RequestsHttpConnection,
        timeout=400,
    )


def query(os_client: OpenSearch, index_name: str, field_name: str, queries):
    for vec in queries:
        query_body = {
            'size': 100,
            'query': {
                'script_score': {
                    'query': {"match_all": {}},
                    'script': {
                        'source': 'knn_score',
                        'lang': 'knn',
                        'params': {
                            'field': field_name,
                            'query_value': vec,
                            'space_type': "l2"
                        }
                    }
                }
            },
            "docvalue_fields": ["_id"],
            "stored_fields": "_none_"
        }
        query_response = os_client.search(index=index_name, body=query_body)

def main(args):
    TEST_INDEX_NAME = "test_index"
    TEST_FIELD_NAME = "test_field"
    STEP = args[1]
    ENGINE = args[2]
    DIMENSION = int(args[3])
    TEST_COUNT = int(args[4])

    print("step: {}".format(STEP))
    print("ENGINE: {}".format(ENGINE))
    print("DIMENSION: {}".format(DIMENSION))
    print("TEST_COUNT: {}".format(TEST_COUNT))
    os_client = _get_opensearch_client("localhost", 9200)

    if STEP == "ingest":
        create_index(os_client, TEST_INDEX_NAME, TEST_FIELD_NAME, ENGINE, DIMENSION)
        ingest_docs(os_client, TEST_INDEX_NAME, TEST_FIELD_NAME, DIMENSION, TEST_COUNT)
        os_client.indices.refresh(index=TEST_INDEX_NAME)
        os_client.indices.forcemerge(index=TEST_INDEX_NAME, max_num_segments=1)
        return
    if STEP == "query":
        # Do a quick warmup
        print("warmup queries")
        queries = [[random.random() for _ in range(DIMENSION)] for _ in range(10)]
        query(os_client, TEST_INDEX_NAME, TEST_FIELD_NAME, queries)

        print("prod queries")
        queries = [[random.random() for _ in range(DIMENSION)] for _ in range(TEST_COUNT)]
        t0 = time.time()
        query(os_client, TEST_INDEX_NAME, TEST_FIELD_NAME, queries)
        t1 = time.time()

        total = t1 - t0
        print ("{} seconds to run queries".format(total))

        return


if __name__ == "__main__":
    main(sys.argv)

