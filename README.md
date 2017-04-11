# YTD

## Building

Update the version in `rel/config.exs`, then run

    ./release.sh release

or

    ./release.sh upgrade

## Upgrading

Make a directory for the new version under `releases` in the deployed
directory, copy the tarball there, then run

    bin/ytd upgrade <version>
