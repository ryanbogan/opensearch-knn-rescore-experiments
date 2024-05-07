#!/bin/bash

mkdir -p tmp
cp -r /tmp/artifacts tmp/

docker build -t customimage -f Dockerfile.testimage .
