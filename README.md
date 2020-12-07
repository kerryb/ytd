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

## Set up server

Add environment variables to `.profile` and source the file (or log out and
back in): 

  * CLIENT_SECRET
  * ACCESS_TOKEN
  * SECRET_KEY_BASE
  * YTD_DATABASE_USER
  * YTD_DATABASE_PASSWORD

Run `install-letsencrypt` and `install-postgres`

Build a release, and unpack into `/opt/ytd`

**Note:** Currently running in `/opt/ytd4`. I should really clean that up.

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

## Renew SSL cert

There must be better ways, but this works for now:

```bash
/opt/ytd4/bin/ytd stop
certbot certonly --config /etc/letsencrypt/letsencrypt.conf
/opt/ytd4/bin/ytd start
```

That's with the config file changed to the following (not sure how it worked
before, but now it can't find the secret file with the initial config):

```
rsa-key-size = 4096
email = kerryjbuckley@gmail.com
domains = ytd.kerryb.org
text = True
authenticator = standalone
```
