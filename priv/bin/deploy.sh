#!/bin/bash
#
# Release deployment script
#
# The wrapper in /setup/deploy-release.sh copies and runs this one, so changes
# are picked up without having to copy the script onto the server manually.

set -x
set -e
tarball="$1"
version="$2"
set -u
set -o pipefail
umask 022

deploy() {
  release_dir="/opt/ytd/releases/$version"
  shared_var_dir="/opt/ytd/shared/var"
  unpack_release
  link_release
  migrate_database
  stop_server
  start_server
  remove_old_releases
}

unpack_release() {
  mkdir -p "$release_dir"
  tar -xzf "$tarball" -C "$release_dir"
}

link_release() {
  mkdir -p "$shared_var_dir"
  rm -rf "$release_dir/var"
  ln -s "$shared_var_dir" "$release_dir/var"

  rm -f "$HOME/current"
  ln -s "$release_dir" "$HOME/current"
}

migrate_database() {
  ./current/bin/ytd eval "YTD.Release.Tasks.migrate()"
}

stop_server() {
  systemctl stop $USER
}

start_server() {
  systemctl start $USER
}

remove_old_releases() {
  # Keep latest five
  cd $HOME/releases
  ls -1rt | head -n -5 | xargs rm -rf
  cd -
}

deploy
