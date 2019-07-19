#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly version=$(cat VERSION)
readonly git_branch=${TRAVIS_BRANCH}
readonly git_sha=$(git rev-parse HEAD)
readonly git_timestamp=$(TZ=UTC git show --quiet --date='format-local:%Y%m%d%H%M%S' --format="%cd")
readonly slug=${version}-${git_timestamp}-${git_sha:0:16}

gcloud auth activate-service-account --key-file <(echo $GCLOUD_CLIENT_SECRET | base64 --decode)

# function build template
echo "Publish function builder"

sed "s|projectriff/builder:latest|projectriff/builder:${slug}|" riff-function-clusterbuildtemplate.yaml > riff-function-clusterbuildtemplate-${slug}.yaml
sed "s|projectriff/builder:latest|projectriff/builder:${version}|" riff-function-clusterbuildtemplate.yaml > riff-function-clusterbuildtemplate-${version}.yaml

gsutil cp -a public-read riff-function-clusterbuildtemplate-${slug}.yaml gs://projectriff/riff-buildtemplate/
gsutil cp -a public-read riff-function-clusterbuildtemplate-${version}.yaml gs://projectriff/riff-buildtemplate/
gsutil cp -a public-read riff-function-clusterbuildtemplate-${slug}.yaml gs://projectriff/riff-buildtemplate/riff-function-clusterbuildtemplate.yaml

# application build template
echo "Publish application builder"

gsutil cp -a public-read riff-application-clusterbuildtemplate.yaml gs://projectriff/riff-buildtemplate/riff-application-clusterbuildtemplate-${slug}.yaml
gsutil cp -a public-read riff-application-clusterbuildtemplate.yaml gs://projectriff/riff-buildtemplate/riff-application-clusterbuildtemplate-${version}.yaml
gsutil cp -a public-read riff-application-clusterbuildtemplate.yaml gs://projectriff/riff-buildtemplate/riff-application-clusterbuildtemplate.yaml

# update version references
echo "Publish builder references"

gsutil -h 'Content-Type: text/plain' -h 'Cache-Control: private' cp -a public-read <(echo "${slug}") gs://projectriff/riff-buildtemplate/versions/builds/${git_branch}
gsutil -h 'Content-Type: text/plain' -h 'Cache-Control: private' cp -a public-read <(echo "${slug}") gs://projectriff/riff-buildtemplate/versions/builds/${version}
if [[ ${version} != *"-snapshot" ]] ; then
  gsutil -h 'Content-Type: text/plain' -h 'Cache-Control: private' cp -a public-read <(echo "${slug}") gs://projectriff/riff-buildtemplate/versions/releases/${git_branch}
  # avoids overwriting existing values
  gsutil -n -h 'Content-Type: text/plain' -h 'Cache-Control: private' cp -a public-read <(echo "${slug}") gs://projectriff/riff-buildtemplate/versions/releases/${version}
fi
