#!/bin/bash

set -xe

export JAVA_HOME=/opt/java/openjdk-21
echo ${JAVA_HOME}

REPO_ENDPOINT=$1
REPO_BRANCH=$2

git clone -b $REPO_BRANCH $REPO_ENDPOINT
# TODO make sure this aligns with repo name
cd k-NN

# Build the plugin (assume that it is snapshot 2.15 build)
bash scripts/build.sh -v 2.15.0 -s true
cp /home/ci-runner/k-NN/build/distributions/opensearch-knn-2.15.0.0-SNAPSHOT.zip /artifacts

echo Success
