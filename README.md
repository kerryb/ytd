# YTD

Strave year-to-date running mileage.

http://ytd.kerryb.org

## Building

Compile, test etc:

    make

Build an upgrade tarball:

**Notes:**

  * Set the release version in `VERSION`
  * The release build uses Docker: if you get certificate errors, restart Docker to
		get the VM clock back in sync
	* Make sure the YTD_ERLANG_COOKIE environment variable is set to a suitable
	  secret value

		make build-upgrade

Deploy upgrade:

		make deploy-upgrade

See `Makefile` for other targets.

## Server setup

Run `install-letsencrypt` to set up SSH certs.

Run `<install-dir>/bin/ytd rpc YTDCore.Database.setup` after the initial
installation of the application to create the mnesia database.
