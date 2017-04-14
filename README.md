# YTD

Strave year-to-date running mileage.

http://ytd.kerryb.org

## Building

Compile, test etc:

    make

Build an upgrade tarball, using version in `rel/config.exs` (uses Docker: if
you get certificate errors, restart Docker to get the VM clock back in sync):

		make build-upgrade

Deploy upgrade:

		make deploy-upgrade

See `Makefile` for other targets.
