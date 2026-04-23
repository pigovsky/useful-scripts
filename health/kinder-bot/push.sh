#!/bin/bash

# Get the version from the VERSION file
VERSION=$(cat .kinder-bot.pigovsky.com/VERSION | tr -d '[:space:]')
IMAGE_NAME="pigovsky/kinder-bot.pigovsky.com"

# Build the docker image
docker build -t "$IMAGE_NAME:$VERSION" .

# Tag the image as latest as well (optional but good practice)
docker tag "$IMAGE_NAME:$VERSION" "$IMAGE_NAME:latest"

# Push the images
docker push "$IMAGE_NAME:$VERSION"
docker push "$IMAGE_NAME:latest"

echo "Successfully built and pushed $IMAGE_NAME:$VERSION"
