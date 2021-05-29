#!/bin/bash
#
# Release deployment script (must be run as the premonition user)

set -x
set -e
tarball="$1"
set -u
set -o pipefail
umask 022

deploy() {
  version=$(find_version)
  extract_script
  run_script
  delete_script
}

find_version() {
  tar tzf "$tarball" | awk '/^releases\/[0-9.]+\// { FS="/" ; print $2 }' | tail -1
}

extract_script() {
  tar xzOf "$tarball" lib/ytd-${version}/priv/bin/deploy.sh > deploy.sh
  chmod u+x deploy.sh
}

run_script() {
  ./deploy.sh "$tarball" "$version"
}

delete_script() {
  rm deploy.sh
}

deploy
