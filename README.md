# YTDWeb

[Strava year-to-date milage tracker](https://ytd.keryb.org)

Built with [Elixir](https://elixir-lang.org/) and
[Phoenix](http://phoenixframework.org/). Hosted on
[DigitalOcean](https://www.digitalocean.com/).

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
