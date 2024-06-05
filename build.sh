#!/bin/bash

REGISTRY=localhost:5000
TAG=minimal-jupyter-env:0.0.11

set -e

kubectl -n docker-registry port-forward svc/docker-registry 5000:5000 &

cd $(dirname "$0")
docker build --progress=plain . --tag $REGISTRY/$TAG
docker push $REGISTRY/$TAG
