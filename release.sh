#!/bin/bash
set -e
set -u
set -o pipefail

usage() {
  echo "Usage: $0 <release|upgrade>" >&2
  exit 1
}

if [ $# -ne 1 ] ; then
  usage
fi

if [ "$1" ==  "release" ] ; then
  extra_flag=""
elif [ "$1" ==  "upgrade" ] ; then
  extra_flag="--upgrade"
else
  usage
fi

pushd apps/ytd_web
./node_modules/brunch/bin/brunch b -p
mix phoenix.digest
popd
docker build --tag=build-elixir -f docker/builder/Dockerfile .
docker run -v $PWD/releases:/app/releases build-elixir mix release --env=prod ${extra_flag}
