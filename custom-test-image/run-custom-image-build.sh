#!/bin/bash

mkdir tmp
cp -r /tmp/artifacts tmp/

docker build -t customimage -f Dockerfile.testimage .
