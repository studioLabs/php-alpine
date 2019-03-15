#!/usr/bin/env sh
set -e

echo "Build hook running"

TAG=$1
TAG=${TAG:=latest}

export COMMIT_HASH=`git rev-parse --short HEAD`

export IMAGE=startupstudio/php-alpine

export IMAGE_COMMIT=$IMAGE:$TAG-$COMMIT_HASH

export IMAGE_NAME=$IMAGE:$TAG && \
             docker build --no-cache --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
             --file Dockerfile \
             --build-arg VCS_REF=$COMMIT_HASH \
             --build-arg DOCKER_REPO=$DOCKER_REPO \
             --build-arg IMAGE_NAME=$IMAGE_NAME \
             --build-arg IMAGE_COMMIT=$IMAGE_COMMIT \
             --squash --force-rm --compress --rm \
             -t $IMAGE_NAME .