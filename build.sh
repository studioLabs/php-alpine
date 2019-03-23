#!/usr/bin/env sh
set -e

echo "Build hook running"

TAG=$1
TAG=${TAG:=latest}

export COMMIT_HASH=`git rev-parse --short HEAD`

export IMAGE=startupstudio/php-alpine

export IMAGE_COMMIT=$IMAGE:$TAG-$COMMIT_HASH

export IMAGE_NAME=$IMAGE:$TAG && \
             docker build --file Dockerfile \
             -t $IMAGE_NAME .