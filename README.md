# YTDWeb

[Strava year-to-date milage tracker](https://ytd.kerryb.org)

Built with [Elixir](https://elixir-lang.org/) and
[Phoenix](http://phoenixframework.org/), and hosted on
[DigitalOcean](https://www.digitalocean.com/).

## Compile, test, etc

```bash
make
```

## Set up server

Add environment variables to `.profile` and source the file (or log out and
back in): 

  * CLIENT_SECRET
  * ACCESS_TOKEN
  * SECRET_KEY_BASE
  * YTD_DATABASE_USER
  * YTD_DATABASE_PASSWORD

Run `install-postgres`

Build a release, and unpack into `/opt/ytd`

## Build and deploy a release

Update the `VERSION` file, then:

```bash
make build-release
make deploy-release version=x.y.z
```
