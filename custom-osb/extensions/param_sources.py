from osbenchmark.utils.parse import parse_string_parameter
from osbenchmark.workload.params import VectorSearchPartitionParamSource, SearchParamSource
import logging
from osbenchmark import exceptions

"""
Custom parameter sources so that we can use exact k-NN functionality in order to 
get the top k nearest neighbors. 
"""


def register(registry):
    registry.register_param_source(
        "exact-knn-query", ExactKNNQueryParamSource
    )


class ExactKNNQueryParamSource(SearchParamSource):
    def __init__(self, workload, params, **kwargs):
        super().__init__(workload, params, **kwargs)
        self.delegate_param_source = ExactKNNQueryParamSourceVectors(workload, params, self.query_params, **kwargs)
        self.corpora = self.delegate_param_source.corpora

    def partition(self, partition_index, total_partitions):
        return self.delegate_param_source.partition(partition_index, total_partitions)

    def params(self):
        raise exceptions.WorkloadConfigError("Do not use a VectorSearchParamSource without partitioning")


class ExactKNNQueryParamSourceVectors(VectorSearchPartitionParamSource):

    def __init__(self, workloads, params, query_params, **kwargs):
        super().__init__(workloads, params, query_params, **kwargs)
        self.space_type = parse_string_parameter("space_type", params, "l2")

    def _build_vector_search_query_body(self, vector, efficient_filter=None) -> dict:
        """Builds a k-NN request that can be used to execute an exact nearest
        neighbor search against a k-NN plugin index
        Args:
            vector: vector used for query
        Returns:
            A dictionary containing the body used for search query
        """
        query = {
            "script_score": {
                "query": {
                    "match_all": {}
                },
                "script": {
                    "lang": "knn",
                    "source": "knn_score",
                    "params": {
                        "field": self.field_name,
                        "query_value": vector,
                        "space_type": self.space_type  # TODO: make this configurable
                    }
                }
            }
        }
        logging.warning("Exact KNN query: %s", query)
        return query
