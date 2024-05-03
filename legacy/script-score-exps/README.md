# Script Score Experiments

## Overview

Set of experiments is for measuring performance of script scoring. For these experiments, we run OpenSearch in a 
container and run different configurations to see impact on latency.

## Docker image

Base image: opensearchstaging/opensearch:2.14.0
sha256:f7487f95be9be24b2fc5632d9297ea6ade06a13fb695c70a2a6de14098faa231
https://hub.docker.com/layers/opensearchstaging/opensearch/2.14.0/images/sha256-295ff2dbf2511d0e003fd080436846333f64c6e0a851ebcf9ed9981dc1db5aad?context=explore

This image includes changes for using script doc values: (Commit info: https://github.com/opensearch-project/k-NN/commit/d4e91e071e9ee71d045635a5fa18b94d7dc8a725) -(Wed Apr 10 01:54:18 2024 +0800)



