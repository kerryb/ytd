# YTDWeb

[Strava year-to-date milage tracker](https://ytd.kerryb.org)

Built with [Elixir](https://elixir-lang.org/) and
[Phoenix](http://phoenixframework.org/), and hosted on
[DigitalOcean](https://www.digitalocean.com/). The run/ride/swim icons are
in the public domain, and made by [Edward
Boatman](https://thenounproject.com/edward/collection/national-park-service/).

## Compile, test, etc

```bash
make
```

## Initialise the database

From `iex` or a remote console:

```elixir
Amnesia.Schema.destroy # only if overwriting an existing db
YTD.Database.setup
```

Data can be exported and imported using `Amnesia.dump "some-file"` and
`Amnesia.load "some-file"`.

## Build and deploy a release or upgrade

NB. if performing database migrations, it has to be a release.

Update the `VERSION` file, then:

```bash
make build-release
make deploy-release version=x.y.z
```

or

```bash
make build-upgrade
make deploy-upgrade version=x.y.z
```
