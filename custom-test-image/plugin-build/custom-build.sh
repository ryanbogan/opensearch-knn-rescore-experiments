#!/bin/bash

set -xe

export JAVA_HOME=/opt/java/openjdk-21
echo ${JAVA_HOME}

REPO_ENDPOINT=$1
REPO_BRANCH=$2

git clone -b $REPO_BRANCH $REPO_ENDPOINT
# TODO make sure this aligns with repo name
cd k-NN

# Build the plugin (assume that it is snapshot 2.17 build)
bash scripts/build.sh -v 2.17.1 -s true -a x64
cp /home/ci-runner/k-NN/build/distributions/opensearch-knn-2.17.1.0-SNAPSHOT.zip /artifacts

echo Success
