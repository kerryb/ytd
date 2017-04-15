# YTD

Strave year-to-date running mileage.

http://ytd.kerryb.org

## Building

Compile, test etc:

    make

Build an upgrade tarball:

_Notes:

  * ensure umbrella app version is updated in `rel/config.exs`, and also
		individual app versions (assuming they've changed) in their `mix.exs` files.
  * The release build uses Docker: if you get certificate errors, restart Docker to
		get the VM clock back in sync.
	* Make sure the YTD_ERLANG_COOKIE environment variable is set to a suitable
	  secret value._

		make build-upgrade

Deploy upgrade:

		make deploy-upgrade

See `Makefile` for other targets.
