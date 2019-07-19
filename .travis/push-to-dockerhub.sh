#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly version=$(cat VERSION)
readonly git_branch=${TRAVIS_BRANCH}
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

docker tag projectriff/builder:latest projectriff/builder:${version}
docker tag projectriff/builder:latest projectriff/builder:${slug}

docker login -u "${DOCKER_USERNAME}" -p "${DOCKER_PASSWORD}"
docker push projectriff/builder:${version}
docker push projectriff/builder:${slug}
