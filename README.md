# YTDWeb

[Strava year-to-date milage tracker](https://ytd.kerryb.org)

Built with [Elixir](https://elixir-lang.org/) and
[Phoenix](http://phoenixframework.org/), and hosted on
[DigitalOcean](https://www.digitalocean.com/).

## Compile, test, etc

```bash
make
```

## Build a release

Update the `VERSION` file, then:

```bash
make release
```

## Deploy

```bash
make deploy
```

## Set up server

Run `setup/setup-server.sh` on the server, update Strava tokens in
`/opt/ytd/ytd.env`, then install a release as above.
